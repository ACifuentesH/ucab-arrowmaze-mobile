# Modo Hexagonal — Auditoría, Diseño y Plan de Orquestación

> Documento de diseño previo al desarrollo. Nada de lo aquí descrito está
> implementado todavía. Fecha: 2026-07-17. Base auditada: `origin/develop`
> (commit `5714350`) del cliente y `main` (commit `d6dab52`) del backend
> `ucab-arrowmaze-api`.

---

## 1. Objetivo

Nueva modalidad de juego **"Modo Hexagonal"**: el tablero se compone de
celdas hexagonales en vez de cuadradas, por lo que cada flecha puede salir
por **6 direcciones** en vez de 4. Entrada en la pantalla de selección de
niveles (campaña), con un botón **debajo del botón "Modo Creativo"**, que
abre una ventana propia con una mini-campaña de **2 niveles**: uno de
dificultad baja y uno bastante complejo.

Fuera de alcance en v1 (documentado en §8): generación IA de niveles hex,
modo survival hex, seed de niveles hex en el backend.

---

## 2. Auditoría del estado actual (cómo se crea el grafo hoy)

### 2.1 Pipeline de carga de un nivel (cliente)

```
JSON (assets/levels/<id>.json  o  GET /levels/:id del backend)
  → LevelDefinition.fromJson / .fromBackendJson      [application/builders/level_definition.dart]
  → LevelBuilder.build(def)                          [application/builders/level_builder.dart]
      1. crea un Node por cada celda [r,c]  →  CellId('r{r}c{c}')
      2. ITopologyStrategy.buildConnections(nodes)   ← AQUÍ se decide la forma
      3. IArrowFactory.create(ArrowSpec)             ← deriva headDirection del último segmento
      4. valida paths (pertenencia + no colisión + adyacencia)
  → Board (aggregate root)                           [domain/aggregates/board.dart]
```

### 2.2 Piezas del dominio y su grado de acoplamiento a "cuadrado"

| Clase / interfaz | Archivo | ¿Agnóstica a la forma? |
|---|---|---|
| `Direction` (VO) | `domain/value_objects/direction.dart` | ✅ Sí — es `index` dentro de `total` puertos; diseñada explícitamente para hex (`total = 6`). `next()` rota en sentido horario para cualquier `total`. |
| `Node` | `domain/entities/node.dart` | ✅ Sí — sin coordenadas; mapa `Direction → CellId`. |
| `IBoardGraph` / `AdjacencyBoardGraph` | `domain/ports/i_board_graph.dart`, `domain/services/adjacency_board_graph.dart` | ✅ Sí — grafo por listas de adyacencia. |
| `Board` (aggregate) | `domain/aggregates/board.dart` | ✅ Sí — `_isPathClear` camina el grafo con `connectedNode(id, dir)`; nunca hace matemática de coordenadas. Vidas, tiempo, eventos: agnósticos. |
| `ITopologyStrategy` | `domain/ports/i_topology_strategy.dart` | ✅ Es la costura prevista: `allowedDirections()` + `buildConnections(nodes)`. |
| `SquareGridTopology` | `domain/services/square_grid_topology.dart` | Implementación 4-dir (N=0,E=1,S=2,O=3). Se mantiene intacta. |
| `Arrow` | `domain/entities/arrow.dart` | ✅ Sí — path de CellIds + `headDirection`. |
| `ArrowFactory` | `domain/factories/arrow_factory.dart` | ❌ **Acoplada**: hardcodea `total = 4` y deltas ortogonales `(±1,0)/(0,±1)` en `_computeDirection`. |
| `ProceduralArrowPlacer` | `domain/services/procedural_arrow_placer.dart` | ❌ **Acoplada**: `_dirs` cartesianas 4-dir en todo el algoritmo de pelado. Solo lo usa el modo creativo (IA) → fuera de alcance v1. |
| `LevelBuilder` | `application/builders/level_builder.dart` | ⚠️ **Parcial**: topología y fábrica ya son inyectables por constructor, pero (a) el default es `SquareGridTopology`, y (b) `_validate` re-implementa adyacencia manhattan (`dr+dc == 1`) parseando los ids — rompe con hex. |
| `LevelDefinition` | `application/builders/level_definition.dart` | ⚠️ No tiene campo de topología; el esquema `{cells, arrows, lives}` en sí es reutilizable. |

### 2.3 Capa de presentación

| Pieza | Archivo | Acoplamiento |
|---|---|---|
| `BoardPainter` | `presentation/views/widgets/board_painter.dart` | ❌ Todo cuadrado: `_dir` con 4 offsets, `cellSize = width/cols`, fondo con `addRect`, centros `(c+0.5, r+0.5)·cs`. |
| `BoardView` | `presentation/views/widgets/board_view.dart` | ❌ Hit-test por división entera `(dx/cellSize).floor()` — inválido para hex. Tamaño del canvas asume grilla rectangular. |
| `GameScreen`, `GameViewModel`, HUD, victoria, undo, vidas, timer | varios | ✅ Agnósticos — operan sobre `Board`/`arrowId`, nunca sobre coordenadas. |
| `LevelSelectScreen` | `presentation/views/screens/level_select_screen.dart` | Punto de entrada: hoy renderiza `_CreativeButton` (línea ~121) y luego la sección campaña. El botón hex va justo debajo del creativo. |

### 2.4 Catálogo, repositorios y progreso

- Catálogo: `CompositeLevelCatalogService` = `RemoteFirst(Backend → Asset)` + `Generated` (`config/providers.dart:145`). El manifest de assets (`assets/levels/manifest.json`) define **qué niveles forman la campaña cuadrada** — un nivel presente en `assets/levels/` pero fuera del manifest no aparece en la campaña.
- Carga por id: `ChainedLevelRepository` = `Remote → Generated → Asset`; el eslabón de assets carga `assets/levels/<id>.json` para **cualquier id** (`asset_json_level_repository.dart`). Un 404 remoto cae al siguiente eslabón → los niveles hex locales se cargan sin tocar la cadena.
- Progreso: `SharedPrefsPlayerProgressRepository` guarda por `levelId` arbitrario; el desbloqueo secuencial de campaña vive en `GetLevelSelectionUseCase` (application).
- `GetLevelSelectionUseCase` mezcla catálogo+progreso y aplica la regla de desbloqueo solo a `LevelSource.asset`.

### 2.5 Backend (`ucab-arrowmaze-api`, auditado en `main` local)

- `LevelData` (VO, `src/domain/value-objects/LevelData.ts`) trata el nivel como **blob opaco** `{cells:[[r,c]], arrows:[{id,path,color}], lives?, timeLimitSeconds?}` — sin semántica de direcciones ni de forma. La topología hex **cabe en el contrato actual sin cambios**, con una salvedad: `LevelData.create/toPrimitives` **descarta claves desconocidas**, así que un campo `topology` dentro de `data` NO sobreviviría un round-trip por el backend.
- `SyncProgressUseCase` construye `LevelScore(LevelId, Score)` **sin validar que el levelId exista** en la tabla de niveles → sincronizar progreso de `hex_1`/`hex_2` funciona hoy tal cual.
- Generación IA (`GenerateLevelUseCase` + `LlmLevelGenerator`): prompt y validación orientados a cuadrícula cuadrada → fuera de alcance v1.

**Conclusión backend: cero cambios necesarios para v1** (niveles hex bundleados como assets; progreso sincroniza). Extensión opcional futura en §8.

---

## 3. Decisiones de diseño

### 3.1 Sistema de coordenadas: offset "odd-r", hexágonos pointy-top

Se mantiene `cells: [[r,c]]` y `CellId('r{r}c{c}')` **sin cambios de esquema**:
filas con índice impar se dibujan desplazadas media celda a la derecha
(convención *odd-r offset* de Red Blob Games). Ventajas: contrato JSON y
backend intactos, ids estables, `LevelDefinition` casi intacta.

Costo asumido: la matemática de vecinos depende de la paridad de la fila.
Queda encapsulada en exactamente 3 sitios: `HexGridTopology`,
`HexArrowFactory` y `HexBoardGeometry`.

### 3.2 Codificación de las 6 direcciones

Índices horarios (compatible con `Direction.next()`):

| index | nombre | delta fila PAR | delta fila IMPAR | vector px (unitario) |
|---|---|---|---|---|
| 0 | NE | `(r-1, c)`   | `(r-1, c+1)` | `( 0.5, -√3/2)` |
| 1 | E  | `(r, c+1)`   | `(r, c+1)`   | `( 1.0,  0.0)`  |
| 2 | SE | `(r+1, c)`   | `(r+1, c+1)` | `( 0.5,  √3/2)` |
| 3 | SW | `(r+1, c-1)` | `(r+1, c)`   | `(-0.5,  √3/2)` |
| 4 | W  | `(r, c-1)`   | `(r, c-1)`   | `(-1.0,  0.0)`  |
| 5 | NW | `(r-1, c-1)` | `(r-1, c)`   | `(-0.5, -√3/2)` |

Geometría pointy-top con circumradio `s`: ancho de celda `√3·s`, alto `2·s`,
espaciado vertical `1.5·s`, centro `(√3·s·(c + 0.5·(r%2)) + √3/2·s, 1.5·s·r + s)`.

### 3.3 Cómo se marca que un nivel es hexagonal

Nuevo enum de dominio y campo opcional en el JSON:

```jsonc
// assets/levels/hex_1.json
{ "id": "hex_1", "topology": "hex", "cells": [...], "arrows": [...] }
```

- `TopologyKind { square, hex }` — `lib/domain/value_objects/topology_kind.dart`
  (vive en dominio para que `Board` pueda exponerlo sin dependencias invertidas).
- Ausencia del campo ⇒ `square` (retro-compatible con los 15 niveles actuales
  y con los niveles del backend/generados).

---

## 4. Diseño detallado — clases e interfaces

### 4.1 Dominio (nuevo)

| Clase | Archivo (nuevo) | Contrato |
|---|---|---|
| `HexGridTopology implements ITopologyStrategy` | `lib/domain/services/hex_grid_topology.dart` | `allowedDirections()` → 6 `Direction(index: i, total: 6)`. `buildConnections(nodes)` → conecta vecinos odd-r existentes (tabla §3.2) y devuelve `AdjacencyBoardGraph(nodes)`. Espeja la estructura de `SquareGridTopology` (parse de `r{d}c{d}`, `_tryConnect`). |
| `HexArrowFactory implements IArrowFactory` | `lib/domain/factories/hex_arrow_factory.dart` | Igual que `ArrowFactory` pero `_computeDirection(from, to)` resuelve contra la tabla odd-r según paridad de `from[0]`; `total = 6`. Lanza `ArgumentError` si el segmento no es hex-adyacente. |
| `TopologyKind` (enum) | `lib/domain/value_objects/topology_kind.dart` | `square`, `hex`; `TopologyKind.parse(String?)` con default `square`. |

### 4.2 Dominio / aplicación (modificado)

| Clase | Cambio |
|---|---|
| `Board` | + campo final `TopologyKind topologyKind` (default `square` en constructor para no romper llamadas existentes). La UI lo lee para elegir geometría. Ninguna regla de juego cambia. |
| `LevelDefinition` | + `TopologyKind topology` (parse en `fromJson`/`fromBackendJson`, emit en `toJson` solo si ≠ square). |
| `LevelBuilder` | (a) Selección interna de estrategia+fábrica por `def.topology` (mapa `TopologyKind → (ITopologyStrategy, IArrowFactory)`); los parámetros de constructor actuales quedan como overrides para tests. (b) **`_validate` deja de parsear ids**: la adyacencia de cada par consecutivo del path se verifica contra el grafo ya construido (`∃ dir ∈ topology.allowedDirections() : node.neighborTowards(dir) == siguiente`) — agnóstico a la forma, elimina la duplicación manhattan actual. (c) Propaga `topologyKind` al `Board`. |
| `LevelPreview` | + `TopologyKind topology` (para filtrar/badgear en selección). |

**No se toca:** `Direction`, `Node`, `IBoardGraph`, `AdjacencyBoardGraph`,
`SquareGridTopology`, `ArrowFactory` (cuadrada), `Board.tryRemoveArrow`,
comandos/undo, `GameViewModel`, score, vidas, timer.

### 4.3 Presentación

| Clase | Archivo | Contrato |
|---|---|---|
| `IBoardGeometry` (nueva) | `lib/presentation/views/widgets/board_geometry.dart` | Abstrae TODA la matemática de píxeles: `Size boardSize(int rows, int cols, double cell)` · `Offset cellCenter(int r, int c, double cell)` · `Path cellOutline(int r, int c, double cell)` (cuadrado o hexágono) · `Offset directionVector(int dirIndex)` (unitario, tabla §3.2) · `(int r, int c)? hitTest(Offset local, double cell, int rows, int cols)`. |
| `SquareBoardGeometry` (nueva) | mismo archivo o `square_board_geometry.dart` | Reproduce el comportamiento actual 1:1 (centros `(c+0.5, r+0.5)·cs`, outline rect, hit-test por floor). |
| `HexBoardGeometry` (nueva) | `hex_board_geometry.dart` | Pointy-top odd-r (§3.2). Hit-test: candidato por inversión aproximada fila→columna y desempate por distancia mínima al centro entre el candidato y sus 6 vecinos. |
| `BoardPainter` (mod.) | `board_painter.dart` | Recibe `IBoardGeometry`; sustituye `_dir`, `_center`, `addRect` y `_headPoints` por llamadas a la geometría. La lógica de animación (escape recorre camino extendido, shake, fade) no cambia. |
| `BoardView` (mod.) | `board_view.dart` | Elige geometría según `board.topologyKind`; hit-test y tamaño delegados a la geometría. Animaciones intactas. |
| `HexLevelSelectScreen` (nueva) | `lib/presentation/views/screens/hex_level_select_screen.dart` | Ventana "Modo Hexagonal": lista los 2 niveles hex con estado bloqueado/desbloqueado/completado, estrellas y best score; tap → mismo flujo `GameScreen` de siempre (`startCampaign` con la cola hex). Key de test: `hexTileKey(int)`. |
| `LevelSelectScreen` (mod.) | `level_select_screen.dart` | Nuevo `_HexModeButton` **inmediatamente debajo de `_CreativeButton`** (estilo espejo, icono `Icons.hexagon`), `Key('level_select_hex_button')` → `Navigator.push(HexLevelSelectScreen)`. |

### 4.4 Catálogo / view models

| Pieza | Diseño |
|---|---|
| `assets/levels/hex_manifest.json` (nuevo) | `{"levels": ["hex_1", "hex_2"]}`. Los archivos `hex_1.json`/`hex_2.json` viven en `assets/levels/` (mismo dir) para que `AssetJsonLevelRepository` y `ChainedLevelRepository` los carguen **sin ningún cambio**. NO se agregan a `manifest.json` → la campaña cuadrada no los ve. |
| `HexAssetLevelCatalogService implements ILevelCatalogService` (nueva) | `lib/infrastructure/catalog/hex_asset_level_catalog_service.dart` — clon de `AssetLevelCatalogService` leyendo `hex_manifest.json`. |
| `GetHexLevelSelectionUseCase` (nueva) | `lib/application/use_cases/get_hex_level_selection_use_case.dart` — misma regla de desbloqueo secuencial que `GetLevelSelectionUseCase` (primero libre, siguiente al completar el anterior) sobre el catálogo hex. Reutiliza `IPlayerProgressRepository` → el progreso hex se sincroniza al backend igual que el resto (§2.5, sin cambios de API). |
| `HexLevelSelectViewModel` + `hexLevelSelectProvider` (nuevos) | Espejo de `LevelSelectViewModel`; registrado en `config/providers.dart`. |

### 4.5 Niveles (contenido)

- `hex_1.json` — **"Panal"** (fácil): ~12-15 celdas (hex de radio 2), 4 flechas
  de 2-4 celdas, 5 vidas, sin límite de tiempo, `parMoves = 4`.
- `hex_2.json` — **"Colmena"** (complejo): ~40-48 celdas (hex de radio ≈4 o
  silueta irregular), 10-12 flechas con dobleces y dependencias encadenadas
  (orden de resolución casi único), 3 vidas, `timeLimitSeconds` ~240,
  `parMoves` = nº de flechas.
- **Garantía de resolubilidad por test**, no a ojo: el juego es monótono
  (extraer una flecha solo libera celdas, nunca bloquea), así que un solver
  greedy es completo: *mientras exista una flecha con rayo de escape libre,
  extráela; el nivel es resoluble ⇔ el tablero queda vacío*. Test
  `hex_levels_solvability_test.dart` construye cada nivel con `LevelBuilder`
  real y ejecuta el greedy sobre `Board.tryRemoveArrow`.

### 4.6 i18n

Claves nuevas en `lib/l10n/app_en.arb` + `app_es.arb`:
`hexModeButton` ("Hexagonal Mode" / "Modo Hexagonal"), `hexModeTitle`,
`hexLevelEasyName`, `hexLevelHardName` (o nombres desde el JSON), y las que
pida la pantalla. Regenerar `app_localizations` con `flutter gen-l10n`.

---

## 5. Plan por fases y ramas (formato §C del DEVELOPMENT_PLAN)

Gitflow: cada rama sale de `develop` y su PR apunta a `develop`.
**Orden estricto: la Fase 1 debe estar mergeada en `develop` antes de cortar
las ramas de la Fase 2** (ambas dependen del enum/builder/Board).

### Fase 1 — `feature/hex-core` (secuencial, bloqueante)

- **Alcance:** `TopologyKind` + `HexGridTopology` + `HexArrowFactory`;
  `LevelDefinition.topology`; `LevelBuilder` con selección de estrategia y
  validación de adyacencia vía grafo (§4.2); `Board.topologyKind`;
  `LevelPreview.topology`. Cero cambios de UI.
- **Pruebas exigidas:** `test/domain/services/hex_grid_topology_test.dart`
  (vecinos fila par e impar, bordes, celdas ausentes),
  `test/domain/factories/hex_arrow_factory_test.dart` (6 direcciones × 2
  paridades, segmento ilegal lanza), `test/application/builders/`
  (build hex feliz, path no-adyacente rechazado, default square intacto,
  regresión: los 15 niveles de assets siguen construyendo). Nomenclatura
  `should_..._when_...`.
- **Definición de HECHO:** `flutter analyze` y `flutter test` verdes; ningún
  test existente modificado salvo por API aditiva; `Board` cuadrado se
  comporta idéntico (suite de regresión verde).

### Fase 2A — `feature/hex-board-rendering` (paralelizable con 2B)

- **Alcance:** `IBoardGeometry` + `SquareBoardGeometry` + `HexBoardGeometry`;
  refactor de `BoardPainter`/`BoardView` para delegar geometría según
  `board.topologyKind` (§4.3). Sin pantallas nuevas.
- **Pruebas exigidas:** `test/presentation/widgets/hex_board_geometry_test.dart`
  (centros par/impar, `directionVector` de los 6 índices, hit-test dentro/
  fuera/frontera entre celdas), regresión de `SquareBoardGeometry` contra los
  valores actuales del painter, y widget test de `BoardView` hex (tap sobre
  flecha dispara `onTapArrow`).
- **Definición de HECHO:** tablero cuadrado renderiza pixel-idéntico (mismos
  centros/tamaños); un `Board` hex de prueba renderiza panal correcto con
  flechas y animación de escape en las 6 direcciones.

### Fase 2B — `feature/hex-levels-catalog` (paralelizable con 2A)

- **Alcance:** `hex_1.json`, `hex_2.json`, `hex_manifest.json`;
  `HexAssetLevelCatalogService`; `GetHexLevelSelectionUseCase`;
  `HexLevelSelectViewModel` + provider (§4.4, §4.5). Sin UI de pantalla
  (solo view model), para no chocar con 2A.
- **Pruebas exigidas:** `hex_levels_solvability_test.dart` (solver greedy,
  §4.5), test del use case (desbloqueo secuencial: hex_2 bloqueado hasta
  completar hex_1), test del catálogo hex (no contamina el catálogo normal y
  viceversa — la campaña cuadrada sigue mostrando exactamente 15 niveles).
- **Definición de HECHO:** ambos niveles construyen con `LevelBuilder` real y
  el solver los resuelve; suite completa verde.

### Fase 3 — `feature/hex-mode-ui` (secuencial, tras merge de 2A y 2B)

- **Alcance:** `_HexModeButton` en `LevelSelectScreen` debajo del botón
  creativo; `HexLevelSelectScreen`; navegación → `GameScreen` con cola hex;
  claves i18n en/es; ajuste visual (badge hex, colores); entrada(s) en
  `AI_USAGE.md` + cierre de `AI_USAGE_HEX.md`.
- **Pruebas exigidas:**
  `test/presentation/screens/hex_level_select_screen_test.dart` (render de 2
  niveles, tile bloqueado no navega, tile desbloqueado navega a juego) y
  ampliación de `level_select_screen_test` (botón hex visible y navega),
  siguiendo la arquitectura de 3 niveles (Testing API + `ProviderScope`
  overrides con fakes de `test/_support/`).
- **Definición de HECHO:** flujo completo jugable en emulador: Home → JUGAR →
  botón "Modo Hexagonal" → ventana hex → jugar hex_1 → victoria desbloquea
  hex_2 → hex_2 jugable; progreso persiste y sincroniza; ambos idiomas;
  `flutter analyze`/`flutter test` verdes.

### Dependencias

```
Fase 1 (hex-core) ──► merge a develop
        ├─────────► Fase 2A (rendering)  ─┐
        └─────────► Fase 2B (niveles)    ─┴─► merge a develop ─► Fase 3 (UI) ─► develop
```

---

## 6. Orquestación con subagentes (evaluación y protocolo)

**¿Tiene sentido la metodología de subagentes aquí? Sí, con matices:**

- **Fase 1 NO se paraleliza** — todo depende de ella; la hace un solo agente
  (o el orquestador directamente). Lanzar varios agentes antes de que el core
  exista solo produce conflictos.
- **Fase 2 es el caso ideal**: 2A (píxeles/geometría) y 2B (contenido/
  catálogo/use case) no comparten archivos → 2 subagentes Opus en worktrees
  aislados, en paralelo.
- **Fase 3 vuelve a ser secuencial**: integra ambas y toca `LevelSelectScreen`
  (archivo caliente que otras ramas del backlog también tocan — verificar
  estado de `develop` antes de cortar).

**Protocolo (según acuerdo de orquestación del 2026-07-13):**

1. Implementación: `Agent(model: "opus", isolation: "worktree")`, un agente
   por rama, prompteado con el bloque Alcance/Pruebas/HECHO literal de §5.
2. Auditorías y revisión de ramas ajenas: subagentes de solo lectura
   (Explore/general-purpose), nunca escritores.
3. **Confirmación humana antes de CADA push y CADA PR** — sin excepciones ni
   aprobaciones en lote.
4. Cada rama, antes del push: rebase/merge de `develop` y revisión de
   colisiones de numeración en `AI_USAGE.md` (fricción recurrente conocida).
5. Registro de IA: cada rama añade su entrada numerada a `AI_USAGE.md`
   (formato Task / Prompt / Result / Modifications / Lessons) y actualiza la
   bitácora específica `AI_USAGE_HEX.md` (raíz del repo).

---

## 7. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Matemática odd-r con paridad invertida (bug clásico) | Tabla §3.2 como única fuente de verdad; tests de vecinos por paridad en topología, fábrica y geometría (3 suites redundantes a propósito). |
| Hit-test hex impreciso en bordes | Estrategia candidato+vecinos por distancia mínima (§4.3) + test de fronteras. |
| Refactor de `BoardPainter` rompe el modo cuadrado | `SquareBoardGeometry` con test de regresión de valores exactos + suite widget existente. |
| Nivel "complejo" irresoluble o trivial | Solver greedy en CI (§4.5) + revisión manual de la cadena de dependencias entre flechas. |
| `LevelSelectScreen` en conflicto con otras ramas del backlog | Fase 3 se corta al final, con `develop` fresco. |
| Backend descarta `topology` si algún día viaja por `data` | v1 no lo envía (assets locales). Documentado en §8 para la extensión. |

## 8. Extensiones futuras (explícitamente fuera de v1)

1. **Backend**: preservar `topology` en `LevelData` (`LevelDataProps`,
   `create`, `toPrimitives`) + seed de niveles hex vía script de campaña →
   serviría los niveles hex remotos con `LevelDefinition.fromBackendJson` ya
   preparado.
2. **Creativo hex**: `HexArrowPlacer implements IArrowPlacer` (generalizar el
   pelado en orden de resolución a 6 direcciones con rayos por paridad) +
   prompt del generador LLM con siluetas hex.
3. **Survival hex**, rotación de flechas con `Direction.next()` (ya
   soportado por el VO), topologías 3D (el dominio ya lo permite).
