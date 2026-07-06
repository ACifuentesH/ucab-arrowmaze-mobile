# Contexto Backend Para Frontend AI - Arrow Maze

Este documento resume como esta construido el backend `ucab-arrowmaze-api`, como se organizaron las ramas/features/tests, y que debe saber un frontend para integrarse correctamente.

## 1. Resumen Ejecutivo

- Proyecto: `Arrow Maze API`
- Proposito: backend REST para el juego `Arrow Maze - Escape Puzzle`.
- Stack: Node 22, TypeScript 6, Express 5, Prisma 6, PostgreSQL, pnpm, Vitest, Supertest, Docker.
- Arquitectura: Clean Architecture con capas `domain`, `application`, `infrastructure`, `config` y composition root en `src/app.ts`.
- API docs interactivas: `GET /api-docs`
- OpenAPI JSON: `GET /api-docs.json`
- Health check: `GET /health`
- Formato general de respuesta: `{ success, data?, message?, meta? }`
- Excepcion: `/health` responde JSON crudo `{ status, timestamp }`.

## 2. Flujo De Ramas Y Features

El backend usa un flujo tipo Gitflow:

- `main`: rama principal estable. En este repo aparece con el commit inicial.
- `develop`: rama de integracion de features. Los PRs se mergean aqui.
- `feature/*`: ramas de trabajo por fase o feature. Se crean desde `develop` y se integran por PR a `develop`.

Ramas remotas observadas:

- `origin/feature/1-scaffolding`: setup inicial TypeScript, Express, Prisma, Vitest, ESLint, GitHub Actions, Husky y commitlint.
- `origin/feature/2-domain`: entidades, errores de dominio, interfaces/puertos, use cases, fakes in-memory, builders y tests unitarios de dominio.
- `origin/feature/3-aop`: decorators AOP de logging, excepciones y cache, mas tests.
- `origin/feature/4-application`: controllers, routes, mappers, middleware auth/error, ResponseFactory y tests de aplicacion.
- `origin/feature/5-infrastructure`: repositorios Postgres/Prisma, servicios bcrypt/JWT/UUID/logger, strategies de leaderboard y tests.
- `origin/feature/6-composition`: `src/app.ts`, wiring de DI, middleware global, rutas, swagger y composition root.
- `origin/feature/7-integration-tests`: tests e2e/integracion con Supertest y Postgres.
- `origin/feature/8-docs`: README, OpenAPI inline, docs de arquitectura, diagramas y licencia.
- `origin/feature/9-docker`: Dockerfile, docker-compose, `.env.docker`, smoke test Docker en CI.

Tambien hubo ramas posteriores de mejora:

- `chore/tooling-hardening`: typecheck de tests, limpieza de aliases.
- `chore/audit-followups`: ajustes de Node types y tests extra.
- `chore/aop-redact-secrets`: redaccion de passwords/tokens en logs.
- `refactor/auth-facade-wiring`: JWT via puerto `ITokenService`.
- `refactor/level-getbyid-usecase`: `GetLevelByIdUseCase` separado.
- `fix/robustness-hardening`: mitigacion de enumeracion de usuarios y mapeo robusto de errores Prisma.
- `refactor/domain-invariants`: invariantes mas fuertes en `PlayerProgress`.
- `test/expand-coverage`: expansion grande de tests unitarios e integracion.

### Recomendacion Para El Frontend

Usar el mismo patron:

1. Crear ramas `feature/<numero-o-nombre>` desde `develop`.
2. Hacer PR hacia `develop`, no directo a `main`.
3. Configurar GitHub Actions para correr en:
   - push a `main`, `develop`, `feature/**`
   - pull_request hacia `main` o `develop`
4. Separar features por fases claras: scaffolding, domain/state, API client, UI, integration/e2e, docs, docker/deploy.
5. Mantener commits con Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`, `ci:`.

## 3. GitHub Actions Del Backend

Archivo: `.github/workflows/ci.yml`

Triggers:

- `push` a `main`, `develop`, `feature/**`
- `pull_request` hacia `main`, `develop`

Tiene concurrency:

- cancela corridas viejas de la misma rama cuando llega un push nuevo.

Jobs:

### `backend-ci`

Corre en Ubuntu y levanta un servicio PostgreSQL para tests:

1. Checkout.
2. Setup pnpm.
3. Setup Node.js 22 con cache pnpm.
4. `pnpm install --frozen-lockfile`
5. `pnpm run lint`
6. `pnpm run typecheck`
7. `pnpm exec prisma generate`
8. `pnpm exec prisma db push` contra DB de test.
9. `pnpm run test:coverage`
10. `pnpm run test:integration`
11. `pnpm run build`

### `docker-smoke`

Valida que la app pueda correr en Docker:

1. `docker compose up --build -d`
2. Espera a `GET http://localhost:3000/health`
3. Hace smoke test:
   - `GET /health`
   - `POST /auth/register`
   - verifica HTTP 201 y que venga `token`
4. Si falla, imprime logs.
5. Hace `docker compose down -v`.

### Recomendacion Para CI Del Frontend

Un frontend deberia tener un workflow equivalente:

1. Install con lockfile estricto.
2. Lint.
3. Typecheck.
4. Unit tests.
5. Component tests si aplica.
6. Build.
7. E2E/smoke tests contra backend mockeado o contra una API de test.
8. Si hay Docker/deploy, smoke test de contenedor.

## 4. Arquitectura Del Backend

El backend sigue Clean Architecture. Las dependencias apuntan hacia adentro:

```text
src/app.ts + config + infra services/decorators/strategies
        -> application/controllers/routes/mappers/middleware/factories
        -> domain/use-cases + domain/interfaces
        -> domain/entities + domain/errors
```

### Carpetas Principales

- `src/domain/entities`: entidades puras de negocio.
- `src/domain/errors`: errores de dominio con `statusCode` HTTP.
- `src/domain/interfaces`: puertos/interfaces, como repositorios, token service, logger, use case, leaderboard strategy.
- `src/domain/use-cases`: operaciones de negocio.
- `src/application/controllers`: HTTP controllers Express.
- `src/application/routes`: routers Express.
- `src/application/mappers`: conversion de dominio a DTO JSON.
- `src/application/middleware`: auth JWT y error handler.
- `src/application/factories`: `ResponseFactory` para respuestas uniformes.
- `src/infrastructure/repositories`: adaptadores Prisma/Postgres.
- `src/infrastructure/services`: bcrypt, JWT facade, UUID, logger.
- `src/infrastructure/strategies`: algoritmos de ranking.
- `src/infrastructure/decorators`: logging, exception handling, cache y redaccion de secretos.
- `src/config`: environment y Swagger/OpenAPI.
- `src/app.ts`: composition root; instancia Prisma, repos, services, use cases, controllers y rutas.
- `tests`: tests unitarios e integracion.
- `docs`: diagramas Mermaid de arquitectura y clases.
- `prisma/schema.prisma`: modelos de base de datos.

## 5. Patrones De Diseno Usados

- Factory Method: `ResponseFactory` crea respuestas HTTP uniformes.
- Adapter: repositorios `Postgres*Repository` implementan puertos del dominio usando Prisma.
- Facade: `AuthFacade` centraliza JWT.
- Decorator: `LoggingUseCaseDecorator`, `ExceptionHandlingUseCaseDecorator`, `CachingUseCaseDecorator`.
- Strategy: `PerLevelLeaderboardStrategy`, `TotalScoreLeaderboardStrategy`, `CombinedLeaderboardStrategy`.
- Dependency Injection manual: `src/app.ts` compone todo sin framework DI.

## 6. Modelo De Datos

Base de datos: PostgreSQL via Prisma.

### `User`

Tabla: `users`

Campos:

- `id`: UUID string.
- `username`: string unico.
- `email`: string unico.
- `passwordHash`: string, mapeado a `password_hash`.
- `createdAt`: DateTime.
- Relacion opcional con `PlayerProgress`.

### `PlayerProgress`

Tabla: `player_progress`

Campos:

- `id`: UUID string.
- `userId`: string unico, FK a `users.id`.
- `completedLevels`: array de strings.
- `bestScores`: JSON. En API se expone como objeto `{ [levelId]: score }`.
- `currentLevelId`: string.
- `updatedAt`: DateTime.

### `LeaderboardEntry`

Tabla: `leaderboard_entries`

Campos:

- `id`: UUID string.
- `userId`: string.
- `username`: string denormalizado.
- `levelId`: string.
- `score`: int.
- `moves`: int.
- `timeSeconds`: int.
- `rankedAt`: DateTime.

Indices:

- `[levelId, score desc]`
- `[userId]`

### `LevelDefinition`

Tabla: `level_definitions`

Campos:

- `id`: string manual, por ejemplo `level_1`.
- `name`: string.
- `difficulty`: `easy | medium | hard`, default `medium`.
- `parMoves`: int opcional.
- `data`: JSON.
- `createdAt`: DateTime.
- `updatedAt`: DateTime.

Importante para frontend: `data` es un JSON opaco para el backend. El backend no simula la mecanica del juego; solo valida forma minima:

```ts
type Cell = [number, number];

type LevelData = {
  cells: Cell[];
  arrows: {
    id: string;
    path: Cell[];
    color: string;
  }[];
  lives?: number;
};
```

## 7. API HTTP Para Frontend

Base local: `http://localhost:3000`

Headers comunes:

```http
Content-Type: application/json
Authorization: Bearer <token>
```

`Authorization` solo se usa en endpoints protegidos.

### Formato De Respuesta

Exito:

```json
{
  "success": true,
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "Error description"
}
```

### Auth

#### `POST /auth/register`

Publico.

Request:

```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "password123"
}
```

Validaciones:

- `username`: string, 3 a 30 chars.
- `email`: email valido.
- `password`: minimo 6 chars.

Response 201:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "alice",
      "email": "alice@example.com"
    },
    "token": "jwt"
  }
}
```

Errores:

- `409`: email o username duplicado.
- `422`: validacion.

#### `POST /auth/login`

Publico.

Request:

```json
{
  "email": "alice@example.com",
  "password": "password123"
}
```

Response 200:

```json
{
  "success": true,
  "data": {
    "user": {
      "userId": "uuid",
      "username": "alice",
      "email": "alice@example.com"
    },
    "token": "jwt"
  }
}
```

Nota: register devuelve `user.id`; login devuelve `user.userId`. El frontend debe normalizar esto internamente.

Errores:

- `401`: credenciales invalidas.
- `422`: validacion.

### Progress

Todos los endpoints de progress requieren JWT.

#### `GET /progress`

Protegido.

Response 200:

```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "completedLevels": ["level_1", "level_2"],
    "bestScores": {
      "level_1": 900,
      "level_2": 800
    },
    "currentLevelId": "level_3"
  }
}
```

Errores:

- `401`: token ausente, invalido o expirado.
- `404`: usuario autenticado pero todavia no tiene progreso guardado.

#### `PUT /progress`

Protegido. Guarda progreso y opcionalmente registra una entrada en leaderboard.

Request minimo:

```json
{
  "completedLevels": ["level_1", "level_2"],
  "bestScores": {
    "level_1": 900,
    "level_2": 800
  },
  "currentLevelId": "level_3"
}
```

Request con leaderboard:

```json
{
  "completedLevels": ["level_1"],
  "bestScores": {
    "level_1": 950
  },
  "currentLevelId": "level_2",
  "lastLevelId": "level_1",
  "lastScore": 950,
  "lastMoves": 8,
  "lastTimeSeconds": 45
}
```

Regla importante:

- Solo se crea entrada de leaderboard si vienen `lastLevelId` y `lastScore`.
- Si faltan `lastMoves` o `lastTimeSeconds`, se guardan como `0`.

Response 200: mismo DTO de `GET /progress`.

Errores:

- `401`: token invalido.
- `422`: body invalido.

### Leaderboard

#### `GET /leaderboard/:levelId?limit=10`

Publico.

Query:

- `limit`: entero 1 a 100, default 10.

Response 200:

```json
{
  "success": true,
  "data": [
    {
      "userId": "uuid",
      "username": "alice",
      "levelId": "level_1",
      "score": 950,
      "moves": 8,
      "timeSeconds": 45,
      "rankedAt": "2026-07-01T00:00:00.000Z"
    }
  ]
}
```

Si no hay entries:

```json
{
  "success": true,
  "data": []
}
```

Errores:

- `400`: `levelId` invalido.

Nota backend:

- El ranking actual usado en `app.ts` es `PerLevelLeaderboardStrategy`.
- La consulta base pide hasta 100 entries y luego aplica `limit`.
- Hay cache in-memory de leaderboard por 30 segundos con key `lb:<levelId>:<limit>`.

### Levels

#### `GET /levels`

Publico.

Response 200:

```json
{
  "success": true,
  "data": [
    {
      "id": "level_1",
      "name": "Tutorial",
      "difficulty": "easy",
      "parMoves": 10,
      "data": {
        "cells": [[0, 0], [1, 0]],
        "arrows": [
          {
            "id": "arrow_1",
            "path": [[0, 0], [1, 0]],
            "color": "red"
          }
        ],
        "lives": 3
      }
    }
  ]
}
```

#### `GET /levels/:id`

Publico.

Response 200: `LevelDto`.

Errores:

- `400`: id invalido.
- `404`: nivel no existe.

#### `PUT /levels/:id`

Protegido por JWT. Crea o actualiza un nivel.

Request:

```json
{
  "name": "Tutorial",
  "difficulty": "easy",
  "parMoves": 10,
  "data": {
    "cells": [[0, 0], [1, 0], [0, 1]],
    "arrows": [
      {
        "id": "arrow_1",
        "path": [[0, 0], [1, 0]],
        "color": "red"
      }
    ],
    "lives": 3
  }
}
```

Validaciones:

- `name`: string no vacio.
- `difficulty`: opcional, `easy | medium | hard`.
- `parMoves`: opcional, entero positivo.
- `data.cells`: array no vacio de coordenadas `[number, number]`.
- `data.arrows`: array no vacio.
- cada arrow: `id`, `path` no vacio, `color`.
- `data.lives`: opcional, entero >= 0.

Errores:

- `400`: id invalido.
- `401`: token ausente/invalido.
- `422`: body invalido.

### System

#### `GET /health`

Publico, sin envelope.

Response 200:

```json
{
  "status": "ok",
  "timestamp": "2026-07-01T00:00:00.000Z"
}
```

## 8. Autenticacion Y Manejo De Token

El backend genera JWT con:

- `userId`
- `username`

El frontend debe:

1. Guardar el token al hacer register/login.
2. Enviar `Authorization: Bearer <token>` en rutas protegidas.
3. Manejar `401` como sesion invalida/expirada.
4. No depender de claims extra no documentados.
5. Normalizar usuario de register/login porque las formas son distintas:
   - register: `{ id, username, email }`
   - login: `{ userId, username, email }`

## 9. Errores Esperados

Errores de dominio:

- `ValidationError`: 422
- `InvalidCredentialsError`: 401
- `EmailAlreadyRegisteredError`: 409
- `UsernameAlreadyTakenError`: 409
- `NotFoundError`: 404

Errores no controlados:

- 500 con `{ success: false, message: "Internal server error" }`

Errores de auth middleware:

- Header ausente o sin `Bearer `: `{ success: false, message: "Missing or invalid authorization header" }`
- Token invalido/expirado: `{ success: false, message: "Invalid or expired token" }`

## 10. Tests Del Backend

Framework: Vitest.

Scripts:

```bash
pnpm test
pnpm test:unit
pnpm test:integration
pnpm test:watch
pnpm test:coverage
pnpm typecheck
pnpm lint
pnpm build
```

### Unit Tests

Comando:

```bash
pnpm test:unit
```

Cubre:

- `tests/domain`: entidades y use cases.
- `tests/application`: mappers, middleware, factories.
- `tests/infrastructure`: services, decorators, strategies, repos con stubs.

Filosofia:

- State over interaction: probar outputs/estado, no llamadas internas.
- Fakes in-memory en lugar de mocks para repositorios.
- Builders/Object Mother para test data.
- Los mocks (`vi.fn`) se usan cuando la interaccion es el comportamiento observable, por ejemplo decorators y logger.

Coverage:

- `src/domain/**`: lineas 90%, funciones 90%, branches 85%, statements 90%.
- Global medido: lineas 85%, funciones 85%, branches 80%, statements 85%.

### Integration Tests

Comando:

```bash
pnpm test:integration
```

Cubre API HTTP real con Supertest contra `app`.

Caracteristicas:

- Requiere PostgreSQL real.
- Usa `DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `NODE_ENV=test`.
- Corre secuencial con `--no-file-parallelism` porque comparte DB.
- Limpia tablas en `beforeEach`.
- Usa timeouts de 30s por latencia de DB.

Archivos clave:

- `tests/integration/api/Auth.int.test.ts`
- `tests/integration/api/Progress.int.test.ts`
- `tests/integration/api/Leaderboard.int.test.ts`
- `tests/integration/api/Level.int.test.ts`
- `tests/integration/api/System.e2e.test.ts`
- `tests/integration/api/docs.e2e.test.ts`

Casos cubiertos:

- Register/login exitoso.
- Duplicados 409.
- Credenciales invalidas 401.
- Bodies invalidos 422.
- Progress protegido por token.
- Sync + retrieve de progreso.
- No progress 404.
- Token alterado 401.
- Leaderboard vacio, con entries y con `limit`.
- Levels list/get/upsert/404/422/401.
- Health DB-free.
- OpenAPI JSON y Swagger UI.

## 11. Tests Que Deberia Hacer El Frontend

El frontend deberia reflejar los contratos del backend, no repetir su logica interna.

### API Client Tests

Probar una capa `apiClient` o similar:

- Construye URLs correctas para `/auth`, `/progress`, `/leaderboard`, `/levels`.
- Adjunta `Authorization: Bearer <token>` solo cuando corresponde.
- Parse de envelope `{ success, data, message }`.
- Manejo centralizado de errores 401, 404, 409, 422 y 500.
- Normaliza usuario de register/login a una sola forma interna:

```ts
type FrontendUser = {
  id: string;
  username: string;
  email: string;
};
```

### Auth Tests

Casos minimos:

- Register exitoso guarda token y usuario.
- Login exitoso guarda token y usuario.
- Login 401 muestra error de credenciales.
- Register 409 muestra email/username ya usado.
- 422 muestra errores de validacion.
- Logout borra token.
- Token invalido en endpoint protegido fuerza logout o estado no autenticado.

### Progress Tests

Casos minimos:

- `GET /progress` con token carga progreso.
- `GET /progress` 404 se interpreta como "usuario nuevo sin progreso", no como crash.
- `PUT /progress` envia:
  - `completedLevels`
  - `bestScores`
  - `currentLevelId`
- Cuando termina un nivel, `PUT /progress` tambien envia:
  - `lastLevelId`
  - `lastScore`
  - `lastMoves`
  - `lastTimeSeconds`
- 422 muestra error de payload invalido.

### Leaderboard Tests

Casos minimos:

- `GET /leaderboard/:levelId` renderiza entries.
- Empty leaderboard renderiza estado vacio.
- `limit` se manda correctamente.
- Orden esperado: mayor score primero para strategy actual.
- `rankedAt` se formatea sin romper si viene ISO string.

### Levels Tests

Casos minimos:

- `GET /levels` lista niveles.
- `GET /levels/:id` carga detalle.
- `GET /levels/:id` 404 muestra "nivel no encontrado".
- El frontend interpreta `data.cells`, `data.arrows`, `data.lives`.
- Si hay editor/admin de niveles:
  - `PUT /levels/:id` requiere token.
  - valida `name`, `difficulty`, `parMoves`, `cells`, `arrows`.

### UI / E2E Tests

Flujos recomendados:

1. Usuario se registra.
2. Recibe token y entra al juego.
3. Carga niveles.
4. Juega/termina un nivel.
5. Sincroniza progreso.
6. Consulta leaderboard.
7. Cierra sesion.
8. Vuelve a loguearse y recupera progreso.

### Contract Tests Opcionales

Si el frontend quiere blindarse contra cambios del backend:

- Descargar `GET /api-docs.json` en CI.
- Generar tipos desde OpenAPI.
- Validar que endpoints esperados existen.
- Usar MSW o mocks generados desde OpenAPI para tests de UI.

## 12. Variables De Entorno Backend

El backend requiere:

```env
DATABASE_URL="postgresql://user:pass@host:5432/db"
DIRECT_URL="postgresql://user:pass@host:5432/db"
JWT_SECRET="secret-at-least-16-chars"
JWT_EXPIRES_IN="30d"
PORT=3000
NODE_ENV="development"
```

Para Docker hay `.env.docker` y `docker-compose.yml` levanta:

- `postgres:16-alpine`
- API en puerto `3000`

Comando:

```bash
docker compose up --build
```

## 13. Reglas Importantes Para Integracion Frontend

- No asumir que `LevelDefinition.data` tiene mas campos que `cells`, `arrows`, `lives`; el backend lo trata como contrato opaco.
- Usar strings como IDs de niveles (`level_1`, etc.).
- `bestScores` es objeto JSON, no array.
- `completedLevels` es array de strings.
- La creacion de leaderboard depende de `PUT /progress`, no de llamar directamente a un endpoint de leaderboard.
- `GET /leaderboard/:levelId` es publico.
- `GET /levels` y `GET /levels/:id` son publicos.
- `PUT /levels/:id` esta protegido pero no hay rol admin implementado; cualquier usuario autenticado podria upsertear niveles.
- `GET /progress` puede devolver 404 para usuarios nuevos.
- Cache de leaderboard dura 30s; despues de sincronizar progreso podria haber datos cacheados si ya se consulto ese leaderboard justo antes.
- La API no usa paginacion real salvo que `ResponseFactory` tenga soporte generico; leaderboard solo usa `limit`.

## 14. Checklist Para Alimentar A Otra IA Del Frontend

Pedirle a la IA del frontend que:

1. Cree o revise un `apiClient` tipado con los endpoints de este documento.
2. Normalice respuestas `{ success, data, message }`.
3. Modele tipos:
   - `AuthUser`
   - `ProgressDto`
   - `LeaderboardEntryDto`
   - `LevelDto`
   - `LevelData`
4. Implemente manejo de token JWT.
5. Agregue tests unitarios de API client.
6. Agregue tests de estado/auth/progress.
7. Agregue tests de UI para empty/error/loading states.
8. Agregue al CI: lint, typecheck, test, build.
9. Si hay Playwright/Cypress, agregar flujo e2e register -> play -> sync -> leaderboard.
10. Preferir mocks basados en OpenAPI (`/api-docs.json`) para evitar divergencia de contratos.

