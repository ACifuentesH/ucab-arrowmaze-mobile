import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:arrow_maze/domain/aggregates/board.dart';
import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/value_objects/cell_id.dart';
import 'package:arrow_maze/presentation/views/widgets/board_painter.dart';

/// Renderiza el tablero completo con CustomPainter.
/// Gestiona animaciones de escape y shake internamente via didUpdateWidget.
class BoardView extends StatefulWidget {
  final Board board;
  final Arrow? escapingArrow;
  final String? lastBlockedArrowId;
  final void Function(String arrowId) onTapArrow;

  const BoardView({
    super.key,
    required this.board,
    required this.onTapArrow,
    this.escapingArrow,
    this.lastBlockedArrowId,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with TickerProviderStateMixin {
  late final AnimationController _escapeCtrl;
  late final Animation<double> _escapeAnim;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  Arrow? _escapingArrowCache;
  String? _blockedArrowCache;

  @override
  void initState() {
    super.initState();

    _escapeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _escapingArrowCache = null);
          _escapeCtrl.reset();
        }
      });
    _escapeAnim = CurvedAnimation(parent: _escapeCtrl, curve: Curves.easeIn);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _blockedArrowCache = null);
          _shakeCtrl.reset();
        }
      });

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -9, end: 9), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 9, end: -7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);

    if (widget.escapingArrow != null && old.escapingArrow == null) {
      setState(() => _escapingArrowCache = widget.escapingArrow);
      _escapeCtrl.forward(from: 0);
    }

    if (widget.lastBlockedArrowId != null && old.lastBlockedArrowId == null) {
      setState(() => _blockedArrowCache = widget.lastBlockedArrowId);
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _escapeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final rows = board.boundingRows;
    final cols = board.boundingCols;

    final existingCells = board.graph.allNodes.map((n) => n.id).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Celda cuadrada: usa el menor de los dos ejes para no deformar la forma.
        final cellSize = min(
          constraints.maxWidth / cols,
          constraints.maxHeight / rows,
        );
        final boardW = cellSize * cols;
        final boardH = cellSize * rows;

        return Center(
          child: GestureDetector(
            onTapDown: (d) {
              // localPosition es relativo al SizedBox del tablero (no al canvas completo).
              final c = (d.localPosition.dx / cellSize).floor();
              final r = (d.localPosition.dy / cellSize).floor();
              if (r < 0 || r >= rows || c < 0 || c >= cols) return;
              final arrowId = board.arrowAt(CellId('r${r}c$c'))?.id;
              if (arrowId != null) widget.onTapArrow(arrowId);
            },
            child: SizedBox(
              width: boardW,
              height: boardH,
              child: AnimatedBuilder(
                animation: Listenable.merge([_escapeCtrl, _shakeCtrl]),
                builder: (_, __) => CustomPaint(
                  painter: BoardPainter(
                    boundingRows: rows,
                    boundingCols: cols,
                    existingCells: existingCells,
                    arrows: board.arrows,
                    escapingArrow: _escapingArrowCache,
                    escapeProgress: _escapeAnim.value,
                    blockedArrowId: _blockedArrowCache,
                    shakeOffsetX: _shakeAnim.value,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
