# Arquitectura de Arrow Maze — Frontend (Flutter)

> Explica **cómo interactúa el cliente con el backend**, **qué clase vive en qué capa**, y **cómo colaboran** para cada flujo real del juego (login, jugar, sincronizar progreso, generar un nivel con IA, survival, leaderboard). Escrito auditando el código actual en `lib/` — cada clase mencionada existe hoy en el repo, con su ruta.

---

## 1. Panorama general

Dos repos independientes, un solo contrato entre ellos:

```
ucab-arrowmaze-mobile (este repo, Flutter/Dart)  <──HTTP/JSON──>  ucab-arrowmaze-api (Node/Express/Prisma)
```

- **El backend es dueño de**: usuarios, JWT, progreso persistente, leaderboard (niveles + survival), el catálogo remoto de niveles, y el LLM que genera siluetas de niveles con IA.
- **El frontend es dueño de**: la mecánica de juego completa (tablero, flechas, reglas de escape/bloqueo — el backend jamás simula esto), 15 niveles empaquetados como assets, progreso *local* (para poder jugar sin cuenta), y la decisión de qué mostrar/cuándo sincronizar.
- **El contrato de niveles** es el mismo objeto en ambos lados, definido una sola vez:
  ```ts
  { cells: [[row, col], ...], arrows: [{ id, path: [[row,col],...], color }], lives? }
  ```
  El backend lo trata como JSON opaco (no lo valida más que su forma mínima); el frontend es el único que sabe qué significa (`LevelBuilder` lo interpreta para construir un `Board` jugable).

El frontend sigue **Clean Architecture** (4 capas concéntricas) + **MVVM** dentro de la capa de presentación, con **Riverpod** como contenedor de inyección de dependencias (la "capa de configuración").

---

## 2. Las 4 capas — inventario real de clases

```
presentation  →  application  →  domain
     ↑                                ↑
     └──────── infrastructure ────────┘
config (composition root): conecta infra + application + presentation, nunca al revés
```

La regla de dependencia se cumple así: `domain` no importa nada de las otras 3 capas (es Dart puro, cero Flutter, cero red). `application` solo importa `domain` + sus propias interfaces (puertos). `infrastructure` implementa esos puertos. `presentation` solo habla con `application` (casos de uso) vía Riverpod. `config` es el único lugar que conoce las 4 capas a la vez.

### 2.1 Domain (`lib/domain/`) — el juego, sin Flutter ni red

| Tipo | Clases | Rol |
|---|---|---|
| Agregado raíz | `Board` (`aggregates/board.dart`) | Único punto de mutación del juego: `tryRemoveArrow`, `restoreArrow`, `applyTimeTick`. Emite `DomainEvent`s. |
| Entidades | `Arrow` (`entities/arrow.dart`), `Node` (`entities/node.dart`), `ICell`/`EmptyCell`/`WallCell` (`entities/cell/`) | Piezas del tablero. |
| Value Objects | `CellId`, `Direction`, `LevelId`, `Lives`, `MoveCount` (`value_objects/`) | Inmutables, con igualdad por valor. |
| Enums | `GameStatus` (`playing/levelCleared/gameOver/paused`) | Estado del juego. |
| Eventos de dominio | `ArrowEscaped`, `MoveBlocked`, `LevelCleared`, `GameOver` (`events/domain_events.dart`) | El `Board` los acumula; `GameViewModel` los consume vía `pullEvents()`. |
| Puertos (interfaces) | `IBoardGraph`, `ITopologyStrategy`, `ILevelRepository`, `IArrowPlacer`, `ITimeService` | Todo lo que el dominio necesita de afuera, sin saber quién lo implementa. |
| Servicios de dominio | `SquareGridTopology` (Strategy — geometría de la cuadrícula), `AdjacencyBoardGraph`, `ArrowFactory` (Factory Method), `ProceduralArrowPlacer` (Strategy — coloca flechas válidas/resolubles sobre cualquier silueta) | Lógica de negocio pura. |

### 2.2 Application (`lib/application/`) — casos de uso, orquesta el flujo

| Subcarpeta | Contenido |
|---|---|
| `use_cases/` | `RemoveArrowUseCase`, `LoadLevelUseCase`, `RestartLevelUseCase`, `UndoMoveUseCase`, `SaveProgressUseCase`, `CompleteLevelUseCase`, `GetLevelSelectionUseCase`, `GenerateLevelUseCase`, `GetLevelCatalogUseCase`, `auth/{Login,Register,Logout,RestoreSession}UseCase`, `leaderboard/GetLeaderboardUseCase`, `progress/{Sync,Hydrate,Push}ProgressUseCase`, `survival/{SubmitSurvivalRun,GetSurvivalLeaderboard}UseCase` |
| `ports/` | Interfaces que la aplicación necesita de infraestructura: `IApiClient`, `IAudioService`, `ILevelCatalogService`, `ILevelGeneratorService`, `IPlayerProgressRepository`, `IGeneratedLevelRepository`, `ITokenStorage`, `IUserStorage`, `ISurvivalRepository`, `IProgressSyncCoordinator` |
| `dtos/` | Objetos que cruzan la frontera con el backend o entre capas: `AuthSession`, `AuthUser`, `PlayerProgressDto`, `ProgressUpdate`, `LeaderboardEntryDto`, `SurvivalEntryDto`/`SubmitSurvivalInput` (estos dos con `freezed`), `LevelPreview`, `LevelSpec`, `LevelResult`, `LevelSelectEntry`, `PlayableLevel` |
| `builders/` | `LevelBuilder` (Builder — arma un `Board` desde `LevelDefinition`), `LevelDefinition` (el contrato `{cells, arrows, lives}` parseado, con `fromJson`/`fromBackendJson`/`toJson`) |
| `commands/` | `IArrowCommand`, `RemoveArrowCommand`, `CommandInvoker` (Command — permite undo real) |
| `proxies/` (AOP) | `UseCaseLoggerProxy`, `ExceptionHandlingApiClientProxy`, `CachingUseCaseProxy` — ver §5 |
| `services/` | `ScoreCalculator` (fórmula de puntaje), `SessionCleanup` (interfaz `ISessionCleanup`) |
| `errors/` | `ApiError` y sus 6 subtipos sellados: `UnauthorizedError`, `NotFoundError`, `ConflictError`, `ValidationError`, `ServerError`, `NetworkError` |
| `mappers/` | `ProgressMapper` (DTO remoto → entradas de progreso local) |

### 2.3 Infrastructure (`lib/infrastructure/`) — adapters concretos

| Puerto (application/domain) | Implementación concreta |
|---|---|
| `IApiClient` | `HttpApiClient` (`infrastructure/api/http_api_client.dart`) — el único que sabe hablar HTTP con el backend real |
| `ILevelRepository` | `AssetJsonLevelRepository`, `GeneratedJsonLevelRepository`, compuestos en `ChainedLevelRepository` |
| `ILevelCatalogService` | `AssetLevelCatalogService`, `GeneratedLevelCatalogService`, compuestos en `CompositeLevelCatalogService` |
| `ILevelGeneratorService` | `ApiLevelGeneratorService` — pide la silueta al backend (`POST /levels/generate`) |
| `IAudioService` | `AudioService` (Singleton + Facade + Adapter sobre `audioplayers`) |
| `ITimeService` | `StopwatchTimeService` |
| `IPlayerProgressRepository`, `ITokenStorage`, `IUserStorage`, `IGeneratedLevelRepository` | Implementaciones sobre `SharedPreferences` (`Shared­Prefs*Repository`) |
| `ISurvivalRepository` | `SurvivalRepositoryImpl` — delega en `IApiClient` |

### 2.4 Presentation (`lib/presentation/`) — MVVM

| ViewModel (`StateNotifier`) | Pantallas que lo consumen |
|---|---|
| `AuthViewModel` / `AuthState` | `LoginScreen`, `RegisterScreen`, menú de cuenta en `HomeScreen` |
| `GameViewModel` / `GameState` | `GameScreen` (campaña, nivel único y también el motor detrás de survival) |
| `LevelSelectViewModel` / `LevelSelectState` | `LevelSelectScreen` |
| `LeaderboardViewModel` / `LeaderboardState` | `LeaderboardScreen` |
| `SurvivalViewModel` / `SurvivalState` | `SurvivalGameScreen`, y alimenta `survival_leaderboard_provider.dart` |
| `SettingsViewModel` / `SettingsState` | `SettingsScreen` (mute + idioma) y `ArrowMazeApp` (relocaliza toda la app) |
| `GenerateLevelViewModel` / `GenerateLevelState` | `GenerateLevelScreen` (AI Level Builder) |

Pantallas (`views/screens/`): `HomeScreen`, `LoginScreen`, `RegisterScreen`, `SettingsScreen`, `LevelSelectScreen`, `GameScreen`, `LeaderboardScreen`, `SurvivalGameScreen`, `SurvivalLeaderboardScreen`, `GenerateLevelScreen`. Widgets compartidos (`views/widgets/`): `BoardView`/`BoardPainter` (canvas del tablero), `HudView`, `AnimatedLogo`, `LoginPromptDialog`.

### 2.5 Config (`lib/config/`) — composition root

- `providers.dart`: **todo** el grafo de dependencias vive aquí (un único archivo, ~420 líneas) — cada `Provider`/`StateNotifierProvider` de Riverpod conecta un puerto con su implementación concreta. Es el único archivo del repo que puede importar las 4 capas a la vez.
- `progress_sync_coordinator.dart`: adapter que implementa `IProgressSyncCoordinator` orquestando pull/push + invalida providers de Riverpod tras hidratar (para no acoplar `AuthViewModel` a Riverpod directamente).
- `theme_config.dart`, `api_config.dart`.

---

## 3. Cómo interactúa el frontend con el backend

### 3.1 El puerto único: `IApiClient`

Todo lo que el frontend necesita del backend pasa por **una sola interfaz** (`lib/application/ports/i_api_client.dart`):

| Método | HTTP | Auth | Nota |
|---|---|---|---|
| `register(username,email,password)` | `POST /auth/register` | No | Guarda el token al éxito |
| `login(email,password)` | `POST /auth/login` | No | Guarda el token al éxito |
| `logout()` | (local) | — | Solo borra el token guardado |
| `getProgress()` | `GET /progress` | JWT | 404 = usuario nuevo sin progreso |
| `putProgress(update)` | `PUT /progress` | JWT | Si trae `last*`, el backend también crea entrada de leaderboard |
| `getLeaderboard(levelId, limit)` | `GET /leaderboard/:levelId` | No | |
| `getLevels()` / `getLevelById(id)` | `GET /levels` / `GET /levels/:id` | No | Catálogo remoto (además del local en assets) |
| `submitSurvival(body)` | `POST /survival` | JWT | |
| `getSurvivalLeaderboard(durationSeconds, limit)` | `GET /survival/leaderboard` | No | |
| `generateLevel(spec)` | `POST /levels/generate` | JWT | El backend llama al LLM; ver §4.4 |

### 3.2 El adapter real: `HttpApiClient`

`infrastructure/api/http_api_client.dart` es la única clase que sabe que existe HTTP:

1. Arma la URL (`ApiConfig.baseUrl` + path + query).
2. Agrega `Authorization: Bearer <token>` solo si el método lo pide (`authenticated: true`), leyendo el token de `ITokenStorage`.
3. Envía con `package:http`.
4. Desempaqueta el envelope `{ success, data, message }` — si `success` es `true` y el status es 2xx, devuelve `data`; si no, lanza el `ApiError` correspondiente al código HTTP.
5. Normaliza `user.id` (register) vs `user.userId` (login) al construir `AuthUser`.
6. Traduce errores de validación del backend (que pueden venir como JSON de Zod, con `path`/`regex`/etc.) a **códigos cortos de aplicación** (ej. `invalid_email`) — la UI nunca ve el JSON crudo del validador.

### 3.3 Los dos aspectos AOP que envuelven la comunicación

Ninguno de los dos vive en `HttpApiClient` — se **componen alrededor** de él en `providers.dart`, sin que el adapter ni los casos de uso sepan que existen (Proxy transparente):

```dart
// providers.dart
final apiClientProvider = Provider<IApiClient>(
  (ref) => ExceptionHandlingApiClientProxy(
    delegate: HttpApiClient(...),
  ),
);

final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>(
  (ref) => CachingUseCaseProxy(
    delegate: GetLeaderboardUseCase(api: ref.read(apiClientProvider)),
    ttl: const Duration(seconds: 30),
  ),
);
```

- **`ExceptionHandlingApiClientProxy`** (`application/proxies/exception_handling_proxy.dart`): implementa `IApiClient` completo, delega cada método envolviéndolo en `_guard`. Normaliza cualquier excepción no tipada a `NetworkError`, y **reintenta solo** los fallos transitorios de transporte (hasta 2 intentos, 300ms de por medio) — nunca reintenta un 404/422 porque volvería a fallar igual.
- **`CachingUseCaseProxy`** (`application/proxies/caching_use_case_proxy.dart`): memoiza `GetLeaderboardUseCase.execute(levelId, limit)` por 30s, para que refrescar la pantalla de leaderboard varias veces seguidas no golpee la red cada vez.
- El aspecto de **logging** (`UseCaseLoggerProxy`) envuelve `RemoveArrowUseCase` — no toca red, pero es el mismo patrón (Proxy) aplicado a un caso de uso de dominio en vez de a `IApiClient`.

Los tres siguen la misma receta: **implementan la misma interfaz que envuelven**, así que Riverpod los inyecta sin que nadie más en el árbol de dependencias note el cambio.

### 3.4 Errores: `ApiError`

`application/errors/api_error.dart` — jerarquía sellada (`sealed class`), así el compilador obliga a manejar todos los casos en un `switch`:

```
ApiError (sealed)
├── UnauthorizedError   (401 → la UI debe forzar logout)
├── NotFoundError       (404 → ej. progreso inexistente de usuario nuevo)
├── ConflictError       (409 → email/username ya registrado)
├── ValidationError     (400/422 → código corto, ej. "invalid_email")
├── ServerError         (500 / respuesta malformada)
└── NetworkError        (sin conexión, timeout, DNS)
```

### 3.5 Autenticación y sesión

- El JWT vive en `ITokenStorage` (impl. `SharedPrefsTokenStorage`); el usuario normalizado vive en `IUserStorage`.
- `RestoreSessionUseCase` se ejecuta al arrancar `AuthViewModel` (ver `main.dart`, `ref.watch(authViewModelProvider)`): si hay token guardado, restaura sesión sin pedir login de nuevo.
- Sin sesión, la app funciona como **invitado**: `HomeScreen` muestra un `LoginPromptDialog` la primera vez que se toca "JUGAR" (login / registro / continuar como invitado), y el progreso vive solo local hasta que haya sesión.

---

## 4. Flujos completos (quién llama a quién)

### 4.1 Login

```
LoginScreen
  → AuthViewModel.login(email, password)
      → LoginUseCase.execute(...)
          → IApiClient.login(...)                 [HttpApiClient → POST /auth/login]
              ⤷ ExceptionHandlingApiClientProxy envuelve la llamada
          → IUserStorage.save(user)
      → AuthViewModel._syncProgressAfterAuth()
          → IProgressSyncCoordinator.pullAndApplyLocal()
              → HydrateProgressUseCase.execute()
                  → SyncProgressUseCase.pull()      [GET /progress]
                  → IPlayerProgressRepository.replaceAll(...)  [local]
      → AuthState.authenticated(user)  →  HomeScreen se re-renderiza (Riverpod watch)
```

Nota de robustez (ver comentario en `auth_view_model.dart`): un fallo en el *pull* de progreso (red, 500, JSON raro) **nunca** tumba un login válido — se absorbe silenciosamente dentro de `pullAndApplyLocal`.

### 4.2 Jugar un nivel de campaña

```
LevelSelectScreen → tap nivel desbloqueado
  → GameViewModel.loadLevel(id, difficulty, mode: campaign)
      → LoadLevelUseCase.execute(id)
          → ILevelRepository (ChainedLevelRepository: assets → generados)
              → LevelBuilder.build(LevelDefinition)   [construye el Board]
  → usuario toca una flecha
      → GameViewModel.tapArrow(arrowId)
          → RemoveArrowUseCase (envuelto en UseCaseLoggerProxy)
              → CommandInvoker.execute(RemoveArrowCommand)
                  → Board.tryRemoveArrow(arrowId)
                      → emite ArrowEscaped | MoveBlocked | LevelCleared | GameOver
          → GameViewModel consume los eventos (pullEvents) → dispara audio, anima
  → al vaciar el tablero (LevelCleared)
      → CompleteLevelUseCase (ScoreCalculator, guarda mejor puntaje LOCAL)
      → IProgressSyncCoordinator.pushCompletedLevel(...)
          → PushProgressUseCase.execute(...)  → PUT /progress (con last*)
              ⤷ si no hay token: no-op (invitado); si falla red/5xx: se absorbe
```

### 4.3 Generación de nivel con IA (`feature/ai-generation-backend-integration`)

Aquí es donde más cambió la arquitectura desde la versión anterior: **la API key del LLM ya no vive en el frontend**.

```
GenerateLevelScreen
  → GenerateLevelViewModel → GenerateLevelUseCase.execute(spec)
      → ILevelGeneratorService.generate(spec)
          [ApiLevelGeneratorService → IApiClient.generateLevel(spec)]
          [HttpApiClient → POST /levels/generate  (JWT)]
          ⤷ el BACKEND llama al LLM y devuelve SOLO la silueta: { cells }
      → IArrowPlacer.place(cells)          [ProceduralArrowPlacer, dominio, determinista]
          ⤷ coloca flechas que cubren toda la forma, siempre resolubles, sin IA
      → LevelBuilder.build(...)             [valida el resultado]
      → IGeneratedLevelRepository.save(...) [persiste local]
```

Antes (`GroqLevelGeneratorService`, ya eliminado del repo) el frontend llamaba directo a Groq con una API key embebida y generaba las flechas con un algoritmo similar pero acoplado a ese servicio. Ahora: (a) ninguna credencial de IA vive en el cliente, (b) la colocación de flechas es un `Strategy` de dominio reutilizable (`ProceduralArrowPlacer`) que no sabe nada de IA ni de HTTP.

### 4.4 Survival

```
HomeScreen → "MODO SUPERVIVENCIA" → SurvivalGameScreen
  → SurvivalViewModel.start(durationSeconds: 120)
      → ILevelCatalogService.getLevels()   [pool: assets + generados]
      → carga un nivel al azar vía GameViewModel.loadLevel(..., mode: survival)
      → Timer.periodic 1s → cuenta regresiva
  → GameViewModel notifica victoria/derrota (ref.listen en providers.dart)
      → SurvivalViewModel.onGameStateChanged(...)
          → victoria: boardsCleared++, carga otro nivel al azar tras un delay
          → derrota: carga otro nivel al azar (no resetea el contador)
  → al llegar a 0s
      → SubmitSurvivalRunUseCase.execute(SubmitSurvivalInput)
          → ISurvivalRepository.submitRun(...)  → POST /survival (JWT)
  → SurvivalGameScreen navega a SurvivalLeaderboardScreen
      → GetSurvivalLeaderboardUseCase → GET /survival/leaderboard
```

### 4.5 Leaderboard por nivel

```
LevelSelectScreen → ícono de leaderboard de un nivel → LeaderboardScreen(levelId)
  → LeaderboardViewModel → GetLeaderboardUseCase (envuelto en CachingUseCaseProxy, TTL 30s)
      → IApiClient.getLeaderboard(levelId, limit)  → GET /leaderboard/:levelId
```

---

## 5. Patrones de diseño — tabla actualizada (post backend-integration)

| Patrón | Categoría | Clase(s) | Nota |
|---|---|---|---|
| Factory Method | Creacional | `ArrowFactory` | Crea `Arrow` desde `ArrowSpec` |
| Builder | Creacional | `LevelBuilder` | Ensambla `Board` desde `LevelDefinition` |
| Singleton | Creacional | `AudioService` | `factory AudioService() => _instance` |
| Strategy | Comportamiento | `ITopologyStrategy`/`SquareGridTopology`, `IArrowPlacer`/`ProceduralArrowPlacer` | Geometría del tablero y colocación de flechas intercambiables |
| Command | Comportamiento | `IArrowCommand`, `RemoveArrowCommand`, `CommandInvoker` | Soporta undo real |
| Adapter | Estructural | `HttpApiClient`, `AudioService` (audio) | Traducen librerías/servicios externos a puertos internos |
| Facade | Estructural | `AudioService` | Oculta múltiples `AudioPlayer` |
| Proxy (×3, AOP) | Estructural | `UseCaseLoggerProxy`, `ExceptionHandlingApiClientProxy`, `CachingUseCaseProxy` | Ver §3.3 — sustitución transparente de la interfaz que envuelven |
| Chain of Responsibility | Estructural (nombrado "Composite*" en 2 clases, ver nota) | `ChainedLevelRepository`, `CompositeLevelCatalogService` | Prueban assets → generados en orden hasta que uno responde |

**Nota de defensa** (heredada de `DEVELOPMENT_PLAN.md`): `ChainedLevelRepository` ya se renombró desde `CompositeLevelRepository` para reflejar que es Chain of Responsibility, no Composite — `CompositeLevelCatalogService` todavía tiene el nombre antiguo y conviene alinearlo o aclararlo en el README antes de la defensa.

---

## 6. Testing — quién prueba qué

Metodología obligatoria en `docs/testing-architecture.md` (3 niveles: Test / Testing API / Object Mother). Con los flujos nuevos, la cobertura se organiza así:

- **Dominio puro** (`test/domain/`): `Board`, `Arrow`, `Node`, cells, topología, `ArrowFactory` — sin mocks, con `BoardMother`.
- **Casos de uso** (`test/application/use_cases/`): cada uno con su propio `*_test_api.dart` (ej. `AuthTestApi`, `LeaderboardTestApi`, `SyncProgressTestApi`) que esconde fakes in-memory de sus puertos.
- **Proxies AOP** (`test/application/proxies/` si existe, o junto al caso de uso que envuelven): aquí **sí se usan mocks/interacción** (`mocktail`) porque la interacción (¿se reintentó?, ¿se sirvió desde caché?) es el comportamiento observable — coherente con la excepción que documenta `testing-architecture.md §0.5`.
- **Niveles de campaña** (`test/infrastructure/levels/campaign_levels_test.dart`): construye los 15 niveles reales y prueba resolubilidad con `GreedyBoardSolver`.
- **Presentación**: ViewModels con fakes de sus casos de uso; widget tests (`testWidgets`) para navegación entre pantallas (home → settings/login/survival, level select → game/leaderboard).

Correr todo: `flutter test` (95 archivos de test a la fecha de este documento). CI (`.github/workflows/ci.yml`) corre `analyze` → `test` → `build` en cada push/PR a `main`/`develop`/`feature/**`.

---

## 7. Índice rápido — "¿dónde vive X?"

| Pregunta | Archivo |
|---|---|
| ¿Qué le puedo pedir al backend? | `lib/application/ports/i_api_client.dart` |
| ¿Cómo se arma cada request HTTP? | `lib/infrastructure/api/http_api_client.dart` |
| ¿Cómo se reintenta/normaliza un error de red? | `lib/application/proxies/exception_handling_proxy.dart` |
| ¿Cómo se cachea el leaderboard? | `lib/application/proxies/caching_use_case_proxy.dart` |
| ¿Qué tipos de error existen? | `lib/application/errors/api_error.dart` |
| ¿Cómo se sincroniza el progreso (pull/push)? | `lib/application/use_cases/progress/{hydrate,push,sync}_progress_use_case.dart`, `lib/config/progress_sync_coordinator.dart` |
| ¿Cómo se arma un tablero desde JSON? | `lib/application/builders/{level_definition,level_builder}.dart` |
| ¿Cómo se colocan flechas en una silueta generada por IA? | `lib/domain/services/procedural_arrow_placer.dart` |
| ¿Todo el grafo de dependencias (quién implementa qué)? | `lib/config/providers.dart` |
| ¿Qué pantalla navega a cuál? | `lib/presentation/views/screens/home_screen.dart` (punto de entrada), `level_select_screen.dart`, `survival_game_screen.dart` |
| ¿Dónde están los 15 niveles y su prueba de resolubilidad? | `assets/levels/*.json`, `test/infrastructure/levels/campaign_levels_test.dart` |
| ¿Qué le falta a la documentación/entregables del enunciado? | `docs/DEVELOPMENT_PLAN.md` |
