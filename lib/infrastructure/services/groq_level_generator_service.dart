import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:arrow_maze/application/builders/level_definition.dart';
import 'package:arrow_maze/application/dtos/level_spec.dart';
import 'package:arrow_maze/application/ports/i_level_generator_service.dart';

/// Adaptador de infraestructura que genera niveles con la API de Groq.
///
/// Responsabilidades:
///  1. Pedir al modelo SOLO la silueta (grid binario) de la forma. El modelo es
///     bueno dibujando una figura grande y reconocible, pero malo colocando
///     flechas válidas y resolubles.
///  2. Generar las flechas de forma procedural sobre la silueta, garantizando
///     que sean válidas (en celdas existentes, adyacentes, sin solaparse) y que
///     el puzzle siempre tenga solución (ver [_buildArrows]).
class GroqLevelGeneratorService implements ILevelGeneratorService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  /// Paleta de colores para las flechas generadas.
  static const List<String> _palette = [
    '#EF476F',
    '#06D6A0',
    '#118AB2',
    '#FFD166',
    '#8338EC',
    '#FB5607',
    '#3A86FF',
    '#FF006E',
  ];

  final String apiKey;
  final http.Client _client;
  final Random _rng;
  String? _cachedPrompt;

  GroqLevelGeneratorService({
    required this.apiKey,
    http.Client? client,
    Random? random,
  })  : _client = client ?? http.Client(),
        _rng = random ?? Random();

  @override
  Future<LevelDefinition> generate(LevelSpec spec) async {
    if (apiKey.isEmpty) {
      throw const LevelGenerationException(
        'Groq API key not configured. '
        'Run with --dart-define=GROQ_API_KEY=gsk_... '
        'or enter it in Settings.',
      );
    }

    final systemPrompt = await _loadPrompt();
    final userMessage = _buildUserMessage(spec);

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.6,
        'max_tokens': 8192,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final msg = (body['error']?['message'] as String?) ?? response.body;
      throw LevelGenerationException('Groq API ${response.statusCode}: $msg');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;

    try {
      final levelJson = jsonDecode(_extractJson(content)) as Map<String, dynamic>;

      final cells = _extractCells(levelJson);
      if (cells.length < 4) {
        throw const LevelGenerationException(
          'The AI drew a shape that is too small. Please try again.',
        );
      }

      // We own the final document: ignore any arrows/metadata the model emitted
      // and rebuild it deterministically so the level is always valid.
      final finalJson = <String, dynamic>{
        'id': 'generated_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'name': _sanitizeName(levelJson['name'], spec.shapeName),
        'lives': spec.lives,
        'difficulty': spec.difficulty.name,
        if (spec.timeLimitSeconds != null)
          'timeLimitSeconds': spec.timeLimitSeconds,
        'cells': cells,
        'arrows': _buildArrows(cells, _rng),
      };

      return LevelDefinition.fromJson(finalJson);
    } on LevelGenerationException {
      rethrow;
    } catch (e) {
      throw LevelGenerationException(
        'Could not parse AI response as a valid level.\n'
        'Error: $e\n\n'
        'Raw response:\n$content',
      );
    }
  }

  // ── Shape parsing ───────────────────────────────────────────────────────────

  /// Extracts the board cells from the model output. The model is asked for a
  /// binary `grid`; we also tolerate a raw `cells` list as a fallback.
  List<List<int>> _extractCells(Map<String, dynamic> json) {
    if (json['grid'] is List) {
      return _gridToCells((json['grid'] as List).cast<String>());
    }
    if (json['cells'] is List) {
      return (json['cells'] as List)
          .map((e) => [(e as List)[0] as int, e[1] as int])
          .toList();
    }
    throw const LevelGenerationException(
      'The AI response contained no shape (no "grid"). Please try again.',
    );
  }

  /// Converts a list of binary strings (one per row) to [[row,col],…] cells.
  static List<List<int>> _gridToCells(List<String> grid) {
    final cells = <List<int>>[];
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (grid[r][c] == '1') cells.add([r, c]);
      }
    }
    return cells;
  }

  // ── Procedural arrow generation ───────────────────────────────────────────────

  /// Builds a set of valid, complex, *always-solvable* arrows over the shape.
  ///
  /// Strategy — "reverse solve order" construction:
  ///   Arrows are placed one at a time. For each new arrow we choose a head and
  ///   an exit direction whose outward corridor (head → board edge) is clear of
  ///   every cell already occupied. Because each arrow only has to avoid the
  ///   arrows placed *before* it, tapping them in the reverse of their placement
  ///   order always succeeds: the first arrow tapped only needs the others to be
  ///   present (its corridor was checked against all of them), and each later tap
  ///   has even fewer blockers left. The escape rule only depends on the head and
  ///   its exit direction, so tails are free to bend through the interior — that
  ///   is what makes the arrows look complex without breaking solvability.
  ///
  /// Pure & deterministic given [rng]; exposed for tests via [debugBuildArrows].
  static List<Map<String, dynamic>> _buildArrows(
      List<List<int>> cells, Random rng) {
    // Orthogonal directions: N, E, S, W (matches ArrowFactory encoding).
    const dirs = [
      [-1, 0],
      [0, 1],
      [1, 0],
      [0, -1],
    ];

    final shape = <String>{for (final c in cells) '${c[0]},${c[1]}'};
    final occupied = <String>{};
    final arrows = <Map<String, dynamic>>[];

    // Scale the number of arrows with the size of the shape.
    final target = (cells.length / 9).round().clamp(4, 10);
    final maxAttempts = target * 120;

    var attempts = 0;
    while (arrows.length < target && attempts < maxAttempts) {
      attempts++;

      final head = cells[rng.nextInt(cells.length)];
      final hr = head[0];
      final hc = head[1];
      final headKey = '$hr,$hc';
      if (occupied.contains(headKey)) continue;

      final dirOrder = [0, 1, 2, 3]..shuffle(rng);
      for (final di in dirOrder) {
        final d = dirs[di];

        // The cell directly behind the head (path[-2]) must exist and be free,
        // so that the head direction equals the exit direction.
        final br = hr - d[0];
        final bc = hc - d[1];
        final behindKey = '$br,$bc';
        if (!shape.contains(behindKey) || occupied.contains(behindKey)) continue;

        // Outward corridor: consecutive in-shape cells must be unoccupied.
        final corridor = <String>{};
        var corridorClear = true;
        for (var k = 1;; k++) {
          final cr = hr + d[0] * k;
          final cc = hc + d[1] * k;
          final ck = '$cr,$cc';
          if (!shape.contains(ck)) break; // exits the shape → escapable
          if (occupied.contains(ck)) {
            corridorClear = false;
            break;
          }
          corridor.add(ck);
        }
        if (!corridorClear) continue;

        // Build the (possibly bending) tail. headFirst[0] is the head.
        final headFirst = <List<int>>[
          [hr, hc],
          [br, bc],
        ];
        final used = <String>{headKey, behindKey};
        final forbidden = <String>{...occupied, ...corridor};
        final totalLen = 3 + rng.nextInt(3); // 3..5 cells

        var cur = [br, bc];
        while (headFirst.length < totalLen) {
          final neighbours = <List<int>>[];
          for (final dd in dirs) {
            final nr = cur[0] + dd[0];
            final nc = cur[1] + dd[1];
            final nk = '$nr,$nc';
            if (!shape.contains(nk)) continue;
            if (used.contains(nk) || forbidden.contains(nk)) continue;
            neighbours.add([nr, nc]);
          }
          if (neighbours.isEmpty) break;
          final next = neighbours[rng.nextInt(neighbours.length)];
          headFirst.add(next);
          used.add('${next[0]},${next[1]}');
          cur = next;
        }

        // path is ordered tail → head (head last) for ArrowSpec/ArrowFactory.
        final path = headFirst.reversed.map((c) => [c[0], c[1]]).toList();
        occupied.addAll(used);
        arrows.add({
          'id': 'a${arrows.length + 1}',
          'path': path,
          'color': _palette[arrows.length % _palette.length],
        });
        break; // placed this arrow; move on to the next
      }
    }

    if (arrows.length < 2) {
      throw const LevelGenerationException(
        'Could not place arrows on the generated shape. Please try again.',
      );
    }
    return arrows;
  }

  /// Test-only entry point for the procedural arrow generator.
  @visibleForTesting
  static List<Map<String, dynamic>> debugBuildArrows(
          List<List<int>> cells, Random rng) =>
      _buildArrows(cells, rng);

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Strips accidental markdown fences / prose around the JSON object.
  static String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return raw;
    return raw.substring(start, end + 1);
  }

  static String _sanitizeName(dynamic name, String fallback) {
    final n = (name is String) ? name.trim() : '';
    return n.isNotEmpty ? n : fallback;
  }

  Future<String> _loadPrompt() async {
    _cachedPrompt ??=
        await rootBundle.loadString('assets/prompts/level_generator.md');
    return _cachedPrompt!;
  }

  String _buildUserMessage(LevelSpec spec) {
    final n = spec.gridSize;
    return 'Draw the shape: "${spec.shapeName}".\n'
        'Grid size: $n×$n — output EXACTLY $n row strings, each EXACTLY $n '
        'characters long (row 0 = top, column 0 = left).\n'
        'Make the silhouette large, bold, centered and instantly recognizable '
        'as "${spec.shapeName}". Fill roughly 40–60% of the grid.\n'
        'Output ONLY the JSON object (id, name, reasoning, grid). Do not include arrows.';
  }
}
