# Plan de Desarrollo — Arrow Maze (Frontend Flutter)

> Auditoría realizada sobre `ucab-arrowmaze-mobile` en la rama `feature/ui-polish` (base `develop`), cruzando el código real del repo contra `Enunciado_ProyectoSemestral_ArrowMaze_MAYO2026 (1).md`, `docs/backend-context.md`, `docs/testing-architecture.md` y `AI_USAGE.md`. Cada afirmación cita un archivo real; donde no pude verificar algo (típicamente el repo del backend, que no vive en este working directory) lo marco explícitamente como **por verificar**.

---

## A. Resumen ejecutivo

**Cumplimiento estimado hoy: ~50-55% de los 20 pts** (excluyendo el criterio 10 "Defensa individual", que no es auditable por código). El hallazgo central: **el código funcional y arquitectónico está mucho más avanzado que su documentación**. La mayoría de los puntos en riesgo no se pierden por falta de trabajo técnico, sino porque ese trabajo no está *evidenciado* donde la rúbrica lo exige (README, `/docs`).

### Los 3 mayores riesgos de perder puntos

1. **Cero diagramas y README sin terminar (hasta ~6.5 pts en juego: criterios 3, 4, 8).** No existe ni un solo `.puml`/`.drawio` en todo el repo (`find . -iname "*.puml" -o -iname "*.drawio"` → sin resultados), y `README.md:9` dice literalmente *"Full README (badges, screenshots, SOLID/patterns/AOP sections) is completed at the docs phase"*. El código ya tiene 8 patrones GoF y las 4 capas Clean correctamente separadas — pero sin diagrama ni README, la rúbrica los califica como si no existieran.
2. **Fecha de entrega ya vencida según el enunciado.** El documento fuente dice *"Fecha de entrega: Viernes 03 de julio de 2026"* (`Enunciado...md:19`) y la fecha actual del sistema es **2026-07-09** — 6 días después. Esto es una **discrepancia crítica que hay que confirmar con el profesor hoy**, no asumir. Ver Sección H.
3. **AOP incompleto y "Pruebas de Widget/UI" en cero.** Solo existe 1 aspecto AOP (`UseCaseLoggerProxy`), y la rúbrica da el máximo (2 pts) a partir de 3+. Y pese a que el enunciado exige explícitamente "Pruebas de Widget / UI" (§3.5) — render + navegación entre pantallas —, no hay ni un solo `testWidgets(` en todo `test/` (169 tests existentes son 100% unitarios/dominio/aplicación, cero widget tests).

### Lo que ya está fuerte (no hay que rehacerlo)

- Arquitectura Clean real (domain/application/infrastructure/presentation/config), no solo de nombre.
- 15 niveles jugables con formas variadas y dificultad progresiva, **todos con prueba de resolubilidad real** (`test/infrastructure/levels/campaign_levels_test.dart`, 169/169 tests pasan).
- Suite de tests siguiendo la metodología de 3 niveles exigida (`test/_support/{mothers,apis,fakes,solvers}`), con nomenclatura `should_..._when_...` consistente.
- CI ya espeja al backend (`.github/workflows/ci.yml`: analyze → test → build en cada push/PR a `main`/`develop`/`feature/**`).
- `AI_USAGE.md` ya cumple el formato exigido por la Sección 7 del enunciado (aunque necesita una entrada más, ver Sección G).

---

## B. Tabla de cumplimiento vs. rúbrica (ordenada por puntos)

| # | Criterio | Pts | Estado | Evidencia | Qué falta exactamente |
|---|---|---|---|---|---|
| 1 | Funcionalidad del Juego | 4 | **Parcial** | `lib/presentation/views/screens/{home,level_select,game}_screen.dart`; `assets/levels/*.json` (15 niveles); `lib/application/services/score_calculator.dart` | `home_screen.dart` no tiene botón/pantalla de **ajustes** (requisito 5.1.1). No hay `l10n`/ARB en el repo (`grep -r "Localizations\|intl" lib/` → 0 resultados) → falta soporte de 2 idiomas (5.1.10). `assets/audio/` y `assets/audio/sfx/` solo tienen `.gitkeep`: el mute funciona pero no suena nada real (5.1.9). Mecánica de flechas: el enunciado dice "rotar o activar"; el juego implementado solo "activa" (desliza si el camino está libre), nunca rota — ver RIESGO en Sección H. |
| 6 | Pruebas | 2 | **Parcial-fuerte** | 169 tests pasan (`flutter test`); `test/_support/{mothers,apis,fakes,solvers}` siguiendo `docs/testing-architecture.md`; `.github/workflows/ci.yml` corre tests en cada push/PR | **Cero** `testWidgets(` en todo el repo (`grep -r "testWidgets(" test/` → sin resultados). El enunciado (§3.5) exige explícitamente "Pruebas de Widget/UI": render de componentes + navegación entre pantallas. No hay tests de `AuthViewModel` ni `LeaderboardViewModel` (existen `lib/presentation/view_models/auth/auth_view_model.dart` y `.../leaderboard/leaderboard_view_model.dart` sin test en `test/presentation/view_models/`). Pruebas de contrato (Pact) no existen — son "recomendadas", no obligatorias. |
| 3 | Patrones de Diseño | 3 | **Código fuerte, doc en cero** | Ver tabla detallada abajo | Nada documentado en README. Dos patrones declarados por comentario son cuestionables bajo escrutinio de defensa (ver detalle). |
| 4 | Arquitectura CLEAN | 3 | **Arquitectura correcta, diagrama en cero** | Capas reales en `lib/{domain,application,infrastructure,presentation,config}`; regla de dependencia respetada (domain no importa nada de capas externas) | Ningún diagrama de capas existe en `/docs` ni en el README. La rúbrica liga explícitamente el puntaje al diagrama ("diagrama completo, regla de dependencia respetada" = 3pts; "diagrama incompleto" = 2pts). |
| 2 | Principios SOLID | 2 | **Código OK, doc en cero** | Ver tabla detallada abajo | Ningún ejemplo documentado en README. Escala de la rúbrica: "0.5 pt: aplicación superficial o sin documentación" — hoy estamos ahí pese a que el código sí lo cumple. |
| 5 | AOP | 2 | **Parcial** | `lib/application/proxies/use_case_logger_proxy.dart`, envuelto en `removeArrowUseCaseProvider` (`lib/config/providers.dart:125-129`) | Solo 1 aspecto implementado; la rúbrica da el máximo a partir de 3+. Faltan 2 aspectos más (candidatos concretos abajo) + documentación en README. |
| 10 | Defensa individual | 2 | No auditable por código | — | Depende de que cada quien entienda su parte; este plan asigna trabajo por persona precisamente para que cada quien pueda defender lo suyo. |
| 7 | Backend y API REST | 1 | **Por verificar** | `docs/backend-context.md` describe un backend terminado (auth JWT, progress, leaderboard, levels, Swagger en `/api-docs`) | No pude auditar el código del backend: no vive en este working directory (solo un resumen en `docs/backend-context.md` y un `client OLD/backend.zip` obsoleto). Falta que el compañero confirme que el repo remoto `ucab-arrowmaze-api` sigue en ese estado, tiene CI verde y está desplegado/accesible. |
| 8 | Documentación (README + Diagramas) | 0.5 | **Falta casi todo** | — | `README.md` (9 líneas) dice explícitamente que está pendiente. Sin diagramas. Sin `LICENSE` (`ls LICENSE*` → no existe). |
| 9 | Documentación del Uso de IA | 0.5 | **Hecho** | `AI_USAGE.md` — 6 entradas con prompt/resultado/modificaciones/lecciones + evaluación crítica | Desactualizado: dice "135+ tests" y hoy son 169; no incluye aún el trabajo de esta sesión (paleta/tipografía/niveles regenerados en `feature/ui-polish`). Añadir Entry 007 antes de cerrar esa rama. |

### Detalle — Patrones de Diseño ya presentes en el código

| Patrón | Categoría GoF | Evidencia | Nota |
|---|---|---|---|
| Factory Method | Creacional | `lib/domain/factories/arrow_factory.dart` (`ArrowFactory implements IArrowFactory`) | Sólido. |
| Builder | Creacional | `lib/application/builders/level_builder.dart` | Sólido — construye `Board` paso a paso desde `LevelDefinition`. |
| Singleton | Creacional | `lib/infrastructure/services/audio_service.dart:12-15` (`factory AudioService() => _instance`) | Sólido, y ya documentado como tal en el comentario de la clase. |
| Adapter | Estructural | `lib/infrastructure/api/http_api_client.dart` (`HttpApiClient implements IApiClient`); `AudioService` (traduce `SoundEffect` → asset path) | Sólido. |
| Facade | Estructural | `AudioService` (oculta múltiples `AudioPlayer` tras una API simple) | Sólido, documentado en el comentario de clase. |
| Proxy (= el aspecto AOP) | Estructural | `lib/application/proxies/use_case_logger_proxy.dart` | Sólido. |
| Strategy | Comportamiento | `lib/domain/ports/i_topology_strategy.dart` + `lib/domain/services/square_grid_topology.dart` | Sólido — preparado para tableros hexagonales sin tocar el resto del dominio. |
| Command | Comportamiento | `lib/application/commands/{i_arrow_command,remove_arrow_command,command_invoker}.dart` | Sólido — soporta undo real (`undo_move_use_case.dart`). |
| "Composite" (mal nombrado) | — | `CompositeLevelRepository`/`CompositeLevelCatalogService` (`lib/config/providers.dart:81-90, 112-117`) | El propio comentario en `providers.dart:81` dice *"Chain of Responsibility — assets → generated"*. Es Chain of Responsibility, no Composite. **Riesgo en defensa**: si se presenta como Composite, un evaluador que lea el código lo detecta. Recomendación: renombrar la clase/comentario a `ChainOfResponsibility` o mantener el nombre pero documentarlo correctamente como CoR en el README (no reclamar Composite). |
| "Observer" (débil) | — | `lib/domain/events/domain_events.dart` + `Board.pullEvents()` + `GameViewModel._consumeEvents` (`lib/presentation/view_models/game_view_model.dart:206-209`) | Es un modelo **pull** (el ViewModel llama `pullEvents()` después de actuar), no el Observer clásico de GoF (`subject.attach(observer)` + `notify()` empujando eventos). Es válido como patrón *Domain Events*, pero llamarlo "Observer" puede no resistir la defensa. **Alternativa más defendible ya presente en el código**: los `StateNotifier` de Riverpod (`GameViewModel`, `LevelSelectViewModel`) + `ref.watch(...)` en cada pantalla **sí son Observer real** (los widgets se suscriben y son notificados en cada cambio de estado). Recomendación: documentar el Observer sobre Riverpod, y renombrar "Observer" en los comentarios de `domain_events.dart` a "Domain Events" (patrón DDD, no GoF). |
| "State" (no implementado) | — | `lib/domain/game_status.dart` — solo un `enum GameStatus { playing, levelCleared, gameOver, paused }` con un comentario que dice *"Sirve de base al patrón State"* | **No es State de GoF**: falta la jerarquía polimórfica (`MenuState`, `PlayingState`, etc. con comportamiento propio) que el enunciado pide literalmente (§3.2). Hoy es solo un enum con un `switch` en quien lo consuma. Contar esto como "State" en la defensa es el escenario de "aplicación incorrecta" (0 pts en esa fila de la escala). |

Con lo anterior, el proyecto ya tiene **8 patrones reales y defendibles** (Factory Method, Builder, Singleton, Adapter, Facade, Proxy, Strategy, Command) repartidos en las 3 categorías — sobra para el tope de 3 pts (4+) **sin necesitar** reclamar Composite/Observer/State tal como están hoy. Recomendación de bajo riesgo: documentar solo los 8 sólidos, y opcionalmente arreglar Composite/Observer/State como trabajo de pulido (ver backlog `feature/pattern-hardening`).

### Detalle — Principios SOLID ya presentes en el código

| Principio | Evidencia |
|---|---|
| SRP | `LevelBuilder` solo construye tableros; `ScoreCalculator` solo calcula puntaje (`lib/application/services/score_calculator.dart`, clase `abstract final class` sin estado); `AudioService` solo audio. |
| OCP | `lib/domain/entities/cell/i_cell.dart` + `empty_cell.dart` + `wall_cell.dart`: nuevos tipos de celda se agregan implementando `ICell`, sin tocar código existente. `ITopologyStrategy` permite nuevas geometrías (hex) sin modificar `Board`. |
| LSP | `EmptyCell` y `WallCell` implementan `ICell` y son intercambiables donde `Node.content` espera un `ICell` (`lib/domain/entities/node.dart`). |
| ISP | Puertos pequeños y específicos: `IApiClient`, `ILevelRepository`, `IAudioService`, `ITimeService`, `ITopologyStrategy` — ninguno obliga a implementar métodos que no se usan. |
| DIP | Todos los casos de uso dependen de interfaces (`ILevelRepository`, `IApiClient`, `IAudioService`), inyectadas vía Riverpod en `lib/config/providers.dart`, nunca de implementaciones concretas. |

---

## C. Backlog de features faltantes

### `feature/settings-i18n`
- **Objetivo / criterio:** cumple 5.1.1 ("acceso a ajustes") y 5.1.10 ("soporte para al menos dos idiomas") del enunciado.
- **Alcance:**
  - `presentation/views/screens/settings_screen.dart` (nueva) — toggle de mute (reutilizar `IAudioService`), selector de idioma.
  - `presentation/views/screens/home_screen.dart` — agregar botón/icono de ajustes que navegue a `SettingsScreen`.
  - Infraestructura de `l10n`: `flutter gen-l10n`, `lib/l10n/app_es.arb` + `lib/l10n/app_en.arb`, `MaterialApp(localizationsDelegates:, supportedLocales:)` en `main.dart`.
  - Reemplazar strings hardcodeados en `home_screen.dart`, `hud_view.dart`, `game_screen.dart`, `level_select_screen.dart` por `AppLocalizations.of(context)!.xxx`.
- **Pruebas exigidas:** `test/presentation/screens/settings_screen_test.dart` (Testing API tipo `SettingsScreenTestApi` + Mother de `IAudioService` fake) con casos `should_toggle_mute_when_switch_is_tapped_when_...`, `should_change_locale_when_language_is_selected_when_...`. Widget test de `home_screen_test.dart` cubriendo navegación a Settings.
- **Definición de HECHO:** ajustes accesible desde Home; app arranca y se puede jugar completamente en inglés y español; `flutter analyze` y `flutter test` verdes.
- **Dependencias:** ninguna — puede arrancar de inmediato.
- **Estimación:** M.

### `feature/audio-assets`
- **Objetivo / criterio:** cumple 5.1.9 (efectos de sonido y música con opción de silenciar) de forma real, no solo el toggle.
- **Alcance:** conseguir/generar (con licencia libre, documentar fuente en `AI_USAGE.md` o `README` si se generan con IA) `assets/audio/background.mp3` y `assets/audio/sfx/{arrow_escaped,move_blocked,level_cleared,game_over,button_tap}.wav` — las rutas exactas que ya espera `lib/infrastructure/services/audio_service.dart:20-28`. Solo copiar archivos + registrar en `pubspec.yaml` (ya declarado: `assets/audio/`).
- **Pruebas exigidas:** ninguna nueva (el `AudioService` ya tiene manejo de error silencioso); verificar manualmente en dispositivo/emulador que suena.
- **Definición de HECHO:** música de fondo y los 5 SFX suenan en build real; mute los detiene.
- **Dependencias:** ninguna.
- **Estimación:** S.

### `feature/pattern-hardening`
- **Objetivo / criterio:** blindar el criterio 3 (Patrones) para la defensa — evitar que Composite/Observer/State mal aplicados bajen la nota.
- **Alcance:**
  - Renombrar/documentar `CompositeLevelRepository` y `CompositeLevelCatalogService` como Chain of Responsibility (ya lo dice el comentario existente; ajustar nombre de clase o dejar constancia clara en README de que el nombre es histórico).
  - En `domain_events.dart`, cambiar el comentario "Observer pattern" por "Domain Events pattern (DDD)"; documentar el Observer real (Riverpod `StateNotifier` + `ref.watch`) en el README con snippet de `game_view_model.dart` + `level_select_screen.dart`.
  - Opcional (si sobra tiempo): implementar State real con una jerarquía mínima (`abstract class GameStateBehavior`, subclases `PlayingBehavior`/`ClearedBehavior`/`GameOverBehavior`) para reclamar el patrón con seguridad. Si no hay tiempo, simplemente **no reclamar State** en el README — con 8 patrones sólidos ya se cubre el tope de 3 pts.
- **Pruebas exigidas:** si se implementa State real, `test/domain/game_status_behavior_test.dart` con casos `should_...`. Si no, ninguna prueba nueva.
- **Definición de HECHO:** README lista solo patrones defendibles con evidencia 1:1 en código.
- **Dependencias:** ninguna, pero debe cerrarse antes de `feature/readme-docs`.
- **Estimación:** S.

### `feature/game-widget-tests`
- **Objetivo / criterio:** cumple la categoría "Pruebas de Widget / UI" del enunciado (§3.5) y sube la solidez del criterio 6.
- **Alcance:** `test/presentation/screens/` (nueva carpeta) con `flutter_test`/`testWidgets`:
  - `home_screen_test.dart`: renderiza título y botones; tap en "JUGAR" navega a `LevelSelectScreen`.
  - `level_select_screen_test.dart`: niveles bloqueados no son tappeable; nivel desbloqueado navega a `GameScreen`.
  - `game_screen_test.dart`: tap en una flecha removible dispara `onTapArrow`; overlay de victoria/derrota se muestra según `GameStatus`.
- **Pruebas exigidas:** seguir igualmente la arquitectura de 3 niveles — Testing API tipo `GameScreenTestApi` envolviendo `ProviderScope(overrides:)` con fakes ya existentes en `test/_support/fakes/`. Nomenclatura `should_navigate_to_game_screen_when_unlocked_level_is_tapped`, etc.
- **Definición de HECHO:** al menos 1 test de render + 1 de interacción + 1 de navegación por pantalla mínima (home, level_select, game).
- **Dependencias:** idealmente después de `feature/settings-i18n` (para cubrir también la navegación a Settings), pero no bloqueante — puede empezar antes y ampliarse después.
- **Estimación:** M.

### `feature/auth-ui` (asignado a compañera)
- **Objetivo / criterio:** hoy `lib/presentation/view_models/auth/auth_view_model.dart` existe pero **no hay ninguna pantalla** que lo use (`find lib/presentation/views/screens` solo devuelve `game`, `generate_level`, `home`, `level_select`). Sin esto, el login del backend (criterio 7, comunicación cliente-servidor) no es demostrable.
- **Alcance:**
  - `presentation/views/screens/login_screen.dart`, `register_screen.dart` (nuevas).
  - Entry point desde `home_screen.dart` (o desde `settings_screen.dart` si `feature/settings-i18n` ya aterrizó).
  - Wiring a `authViewModelProvider` (agregar el provider en `lib/config/providers.dart`, no existe todavía).
- **Pruebas exigidas:** `test/presentation/view_models/auth_view_model_test.dart` (no existe hoy — los casos de uso `login_use_case_test.dart`/`register_use_case_test.dart` sí están cubiertos, falta el ViewModel) + widget tests de las 2 pantallas nuevas siguiendo la misma arquitectura de 3 niveles que `test/_support/apis/auth_test_api.dart` (ya existe, reutilizar).
- **Definición de HECHO:** usuario puede registrarse/iniciar sesión desde la UI real contra el backend; token persiste (`ITokenStorage` ya implementado); 401 fuerza logout.
- **Dependencias:** ninguna del lado frontend. Requiere backend accesible para probar contra la API real (o mock en dev).
- **Estimación:** M.

### `feature/leaderboard-ui` (asignado a compañera)
- **Objetivo / criterio:** `lib/presentation/view_models/leaderboard/leaderboard_view_model.dart` existe sin pantalla. Enunciado 5.2.3 exige leaderboard, y sin UI no es demostrable en la defensa.
- **Alcance:**
  - `presentation/views/screens/leaderboard_screen.dart` (nueva), consumiendo `getLeaderboardUseCaseProvider` (ya existe en `providers.dart:218-220`).
  - Entry point desde `level_select_screen.dart` (p. ej. icono junto a cada nivel) o desde Home.
- **Pruebas exigidas:** `test/presentation/view_models/leaderboard_view_model_test.dart` (no existe hoy) + widget test de estado vacío/con datos (reusar `test/_support/mothers/leaderboard_entry_mother.dart`, ya existe).
- **Definición de HECHO:** tabla de posiciones se ve por nivel, con estado vacío manejado sin crash.
- **Dependencias:** ninguna técnica; puede ir en paralelo a `feature/auth-ui`.
- **Estimación:** M.

### `feature/aop-extra-aspects` (asignado a compañero)
- **Objetivo / criterio:** subir AOP de 1 a 3+ aspectos para el tope de 2 pts (criterio 5).
- **Alcance — 2 aspectos candidatos concretos:**
  1. **Manejo centralizado de excepciones**: decorator/proxy sobre `HttpApiClient` (o sobre cada `*UseCase` que lo llama) que capture errores de red y los mapee a `ApiError` de forma uniforme, con reintentos simples — hoy el mapeo de errores vive disperso en `http_api_client.dart`. Extraerlo a `lib/application/proxies/exception_handling_proxy.dart` siguiendo el mismo molde que `use_case_logger_proxy.dart`.
  2. **Caché de resultados**: el propio enunciado lo sugiere para `GetLeaderboardUseCase` (§3.4) — `lib/application/proxies/caching_use_case_proxy.dart` con invalidación simple por tiempo (TTL), envolviendo `getLeaderboardUseCaseProvider` en `providers.dart`.
- **Pruebas exigidas:** siguiendo el mismo patrón que ya usa el backend para sus decorators (`docs/backend-context.md §5`, `LoggingUseCaseDecorator`/`CachingUseCaseDecorator`) — tests de **interacción** (mocktail) porque aquí la interacción SÍ es el comportamiento observable, como ya indica `docs/testing-architecture.md §5` ("Interacción (cuando SÍ va un mock)"). P. ej. `should_return_cached_result_when_called_twice_within_ttl`.
- **Definición de HECHO:** 3 aspectos en total (logging + excepciones + caché), todos documentados en README con snippet.
- **Dependencias:** ninguna, pero conviene coordinarlo con `feature/auth-ui`/`feature/leaderboard-ui` si tocan los mismos providers.
- **Estimación:** M.

### `feature/architecture-diagrams` (asignado a compañero)
- **Objetivo / criterio:** cumple 4.1 y 4.2 del enunciado y desbloquea buena parte de los criterios 3, 4 y 8.
- **Alcance:**
  - Diagrama de capas Clean Architecture (PlantUML o Mermaid, exportado a imagen) — mostrar las 4 capas reales del repo (`domain`, `application`, `infrastructure`, `presentation`+`config`), flechas de dependencia hacia adentro, y los puertos (`ILevelRepository`, `IApiClient`, `IAudioService`, `ITimeService`, `ITopologyStrategy`) como frontera entre capas.
  - Diagrama de clases — entidades (`Board`, `Arrow`, `Node`, `ICell`/`EmptyCell`/`WallCell`), casos de uso, repositorios, servicios, ViewModels (sin widgets individuales, tal como pide el enunciado). Marcar con color/estereotipo la capa de cada clase y anotar los patrones (Factory Method, Builder, Command, Strategy, etc.).
  - Guardar fuente editable en `docs/diagrams/*.puml` (o `.drawio`) + export `.png` embebido en README.
- **Pruebas exigidas:** N/A (documentación).
- **Definición de HECHO:** ambos diagramas en `/docs`, imagen embebida en README, leyenda de capas/colores.
- **Dependencias:** ninguna técnica — puede arrancar ya mismo con el código actual. Bloquea a `feature/readme-docs`.
- **Estimación:** M.

### `feature/readme-docs` (asignado a compañero, última tarea)
- **Objetivo / criterio:** cierra los criterios 2 (SOLID), 3 (Patrones), 4 (embeber diagrama), 5 (AOP), 8 (estructura README completa) y `LICENSE`.
- **Alcance:** completar `README.md` con las secciones exigidas por §6.1 del enunciado: badges (CI status), descripción, screenshots/GIF (usar capturas del board ya rediseñado en `feature/ui-polish`), arquitectura (embebe diagrama de `feature/architecture-diagrams`), Design Patterns (tabla de la Sección B de este documento), SOLID (tabla de la Sección B), AOP (los 3 aspectos de `feature/aop-extra-aspects`), Getting Started, Running Tests, AI Usage (enlazar `AI_USAGE.md`), Contributing (Conventional Commits + gitflow), License. Agregar `LICENSE` en la raíz (MIT o la que decida el equipo).
- **Pruebas exigidas:** N/A.
- **Definición de HECHO:** README pasa un repaso 1:1 contra la lista de §6.1 del enunciado.
- **Dependencias:** depende de que **todas** las demás ramas de este backlog ya estén mergeadas a `develop` (necesita el conteo final de patrones/aspectos/pantallas/screenshots reales). Es la última rama antes de la entrega.
- **Estimación:** M.

---

## D. Orden de ejecución y dependencias

```
Fase 0 (arrancan ya, en paralelo — sin dependencias entre sí)
├── feature/settings-i18n        (YO)
├── feature/audio-assets         (YO)
├── feature/pattern-hardening    (YO)
├── feature/architecture-diagrams (COMPAÑERO)
├── feature/auth-ui              (COMPAÑERA)
└── feature/leaderboard-ui       (COMPAÑERA)

Fase 1 (puede arrancar en paralelo a la Fase 0, pero conviene coordinarse
        si toca los mismos providers que auth/leaderboard)
└── feature/aop-extra-aspects    (COMPAÑERO)

Fase 2 (después de que Fase 0 esté mergeada a develop — necesita las
        pantallas nuevas para cubrir navegación completa)
└── feature/game-widget-tests    (YO)

Fase 3 (última — necesita TODO lo anterior mergeado: conteo final de
        patrones, aspectos, pantallas y capturas de pantalla reales)
└── feature/readme-docs          (COMPAÑERO)
```

Todo PR va contra `develop` (nunca directo a `main`), siguiendo el mismo gitflow que ya usa el backend (`docs/backend-context.md §2`).

---

## E. Asignación por persona

- **YO — niveles, lógica de tablero, gameplay, pulido visual (+ ajustes/idiomas/audio/pattern-hardening/widget tests):**
  Esta área ya está mayormente hecha (`LevelBuilder`, `Board`, `SquareGridTopology`, `RemoveArrowCommand`+undo, 15 niveles con solvability probada, y el rediseño visual en curso en `feature/ui-polish`: paleta "Sunset Cálido" en `theme_config.dart`, tipografía Outfit, niveles regenerados con tableros grandes y flechas largas/entrelazadas). Añado a mi carga las piezas que faltan y que tocan exactamente las pantallas/mecánica que ya domino: `settings-i18n`, `audio-assets`, `pattern-hardening`, `game-widget-tests`.

- **COMPAÑERA — autenticación/login y ranking/leaderboard:**
  Tal como estaba planteado, pero con el detalle concreto que salió de la auditoría: **el trabajo de aplicación (casos de uso) ya está terminado y probado** (`login_use_case.dart`, `register_use_case.dart`, `logout_use_case.dart`, `get_leaderboard_use_case.dart`, todos con tests). Lo que falta es 100% capa de presentación: las pantallas no existen. Su entregable real es `feature/auth-ui` + `feature/leaderboard-ui`.

- **COMPAÑERO — backend pendiente + integración/CI/docs:**
  Ajustado con lo que la auditoría encontró: además de confirmar el estado del backend (no auditable desde aquí), tiene el bloque de **documentación formal** (diagramas + README, que son los que más puntos tienen en riesgo hoy) y el refuerzo de **AOP** (de 1 a 3 aspectos). Es intencional que su bloque sea el último en cerrar (`feature/readme-docs`), porque necesita ver el resultado final de los otros dos.

**¿Por qué este reparto y no otro?** La auditoría mostró que el trabajo pendiente no está parejo entre "features de negocio" y "documentación": hay ~6.5 pts colgando de documentación pura (diagramas + README) que no requieren tocar lógica de juego ni backend, así que tiene sentido que la persona con menos código pendiente en su área (compañero, una vez el backend esté confirmado) absorba ese bloque, mientras las dos personas con pantallas de UI por construir (yo y compañera) seguimos en nuestros dominios ya conocidos.

---

## F. Gitflow y CI

- **Ramas:** `main` (estable) ← `develop` (integración) ← `feature/<slug>` (una por ítem del backlog de la Sección C, todas desde `develop`).
- **Reglas de PR:** todo PR apunta a `develop`, nunca a `main`. `main` solo recibe merges desde `develop` cerca de la entrega (para cortar el release). Recomendado: proteger ambas ramas en GitHub (`Settings → Branches`) exigiendo que `CI` pase antes de mergear.
- **CI (ya existe, `.github/workflows/ci.yml`):** en cada push a `main`/`develop`/`feature/**` y cada PR hacia `main`/`develop`, corre `flutter pub get --enforce-lockfile` → `flutter analyze --no-pub --no-fatal-infos` → `flutter test --no-pub` → `flutter build web --release --no-pub`. Esto ya espeja el pipeline del backend (`docs/backend-context.md §3`). Para las ramas de este backlog no hace falta tocar el workflow — cualquier test nuevo (`testWidgets`, tests de ViewModel) corre automáticamente con `flutter test`.
- **Conventional Commits:** ya se usa correctamente (`feat(levels): ...`, `ci: ...`, `test: ...` en el historial actual) — mantener el mismo estilo en inglés como exige el enunciado (§6.2).

---

## G. Checklist de entregables del enunciado (§8)

| # | Entregable | Estado |
|---|---|---|
| 1 | URL repo GitHub del juego | ✅ Existe: `https://github.com/ACifuentesH/ucab-arrowmaze-mobile` (`git remote -v`). Confirmar que sea público o que el profesor tenga acceso. |
| 2 | URL repo GitHub del backend | ⚠️ Por verificar (compañero) — no está en este working directory. |
| 3 | Diagrama de clases (imagen + fuente) | ❌ Falta — `feature/architecture-diagrams`. |
| 4 | Diagrama de capas Clean Architecture (imagen + fuente) | ❌ Falta — `feature/architecture-diagrams`. |
| 5 | README completo en ambos repos | ❌ Falta en frontend (`README.md` actual lo admite explícitamente); backend por verificar. |
| 6 | `AI_USAGE.md` en ambos repos | ✅ Frontend completo (falta actualizar con Entry 007 al cerrar `feature/ui-polish`); backend por verificar. |
| 7 | Ejecutable funcional (Android o iOS), Release en GitHub | ⚠️ Falta generar/publicar. `android/` existe (`applicationId = "edu.ucab.arrow_maze"`), no hay carpeta `ios/` — usar Android como plataforma objetivo (el enunciado pide "Android **o** iOS", con Android alcanza). No hay evidencia local de un GitHub Release ya creado. |

Adicional no listado en la tabla del enunciado pero exigido en el texto: **`LICENSE`** en la raíz — no existe (`ls LICENSE*` → nada). Agregar en `feature/readme-docs`.

---

## H. Riesgos y decisiones abiertas para consultar con el profesor

1. **🔴 Fecha de entrega ya vencida en el documento fuente.** El enunciado dice *"Viernes 03 de julio de 2026"* y hoy (fecha del sistema) es 2026-07-09. Puede ser que exista una prórroga comunicada por otro canal que no está en este repo, o que el enunciado archivado esté desactualizado. **Esto se confirma con el profesor antes de priorizar cualquier otra cosa de este plan** — cambia por completo cuánto de este backlog es realista completar.
2. **Mecánica de flechas: "rotar" vs "activar".** El enunciado (§1.1) dice *"El jugador toca una celda para rotar o activar la dirección de su flecha"*. El juego implementado nunca rota una flecha; toca-y-desliza si el camino está libre (que es, de hecho, la mecánica real del juego de referencia de SayGames). Es defendible bajo la lectura de "...o activar", pero como el criterio 1 de la rúbrica repite *"las flechas rotan"* textualmente, conviene que el equipo lo aclare con el profesor para no dar pie a un descuento por una lectura literal.
3. **Backend no auditado en este documento.** Todo lo dicho sobre el backend viene de `docs/backend-context.md`, no de código verificado en este repo. Antes de dar por buena la fila 7 de la Sección B, el compañero debe confirmar contra el repo remoto real: que sigue en ese estado, que el CI está verde, y que está desplegado/alcanzable para la demo.
4. **Alcance de "2 idiomas" (5.1.10).** ¿Aplica a las 7 pantallas mínimas del enunciado únicamente, o también a `GenerateLevelScreen` (el "AI Level Builder", que no es un requisito mínimo)? Este plan asume que basta con cubrir las pantallas obligatorias (inicio, selección, juego, victoria, derrota, y ahora ajustes) y deja `GenerateLevelScreen` fuera del alcance de i18n salvo que sobre tiempo.
5. **Patrón State no implementado de verdad.** Ver Sección B — recomendación es no reclamarlo en el README salvo que `feature/pattern-hardening` decida implementarlo de verdad. Si el profesor pregunta explícitamente por State en la defensa, mejor tener la respuesta lista de antemano ("lo evaluamos, decidimos no forzarlo para no violar SRP/OCP con una jerarquía artificial, y priorizamos los 8 patrones que sí están completos") en vez de que se descubra en vivo.
