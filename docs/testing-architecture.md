# Testing Architecture — Arrow Maze (Frontend Flutter/Dart)

> Documento **obligatorio**. Toda prueba de este repo DEBE seguir esta metodología.
> Es la "arquitectura de pruebas" del curso (Uncle Bob – *The Test Boundary*, y
> Khonikov *Unit Testing* caps. 2–4). Los tests son **documentación viva**: cuentan
> una historia de negocio en lenguaje ubicuo, sin fragilidad ni acoplamiento estructural.

## 0. Reglas no negociables

1. **Cobertura obligatoria:** debe existir prueba para **cada** función, entidad,
   value object, agregado, servicio de dominio y servicio de aplicación. Sin excepción.
2. **Patrón AAA** en cada test, expresado como **Given / When / Then**.
3. **Nombre de test:** `should_[resultado_esperado]_when_[condicion]` (en inglés).
4. **Arquitectura de pruebas de 3 niveles** (ver §2). Nunca mocks crudos ni `new X(...)`
   dentro del `test`.
5. **State over interaction:** verifica estado/resultado, NO llamadas internas.
   Excepción: usa mocks para verificar interacción **solo** cuando la interacción ES
   el comportamiento observable (ej. decorators/logger, o llamadas a servicios externos
   como el `apiClient`).
6. Un test **no debe romperse** al refactorizar la implementación interna. Si al cambiar
   la estructura de un agregado se rompen 20 tests, el diseño de pruebas está mal.

## 1. Los 4 pilares de un buen unit test (Khonikov)

Cada test debe balancear: **protección ante regresiones**, **resistencia al refactor**,
**feedback rápido** y **mantenibilidad**. Si un test es frágil (se rompe por cambios
internos), sacrifica resistencia al refactor → está mal diseñado.

## 2. Arquitectura de pruebas — 3 niveles

| Nivel | Qué es | Responsabilidad |
|---|---|---|
| **Superior — el Test** (`test(...)`) | Habla lenguaje de negocio (ubicuo). Solo dice QUÉ pasa. | La especificación/historia. Given/When/Then. Cero detalle técnico visible. |
| **Medio — Testing API (Builder)** | Traduce negocio → técnico. Contiene la "suciedad". | Encapsula mocks/fakes y la orquestación del SUT. Métodos `given.../when.../then...` encadenables (devuelven `this`). |
| **Inferior — Object Mother** | Fábrica de datos de dominio. | Crea agregados y value objects **válidos y consistentes**. Métodos estáticos. Centraliza todo `Aggregate(...)`. |

**Regla de oro:** si mañana cambia el constructor de un agregado o la librería de mocks,
solo tocas el **Mother** o la **Testing API**. Los `test(...)` no se enteran.

## 3. Herramientas en Dart/Flutter

- Runner: `package:test` (dominio/aplicación puros) y `flutter_test` (widget/UI).
- Mocks: **mocktail** (sin codegen) para verificar interacción.
- Repositorios/puertos: **fakes in-memory** hechos a mano (NO mocks) — como en el backend.
- `group(...)` agrupa; `test('should_..._when_...')` es el caso; `expect(actual, matcher)`.

## 4. Ubicación de archivos

```
test/
  _support/
    mothers/        # BoardMother, ArrowMother, UserMother, ...
    apis/           # RemoveArrowTestApi, LoginTestApi, ...
    fakes/          # FakeLevelRepository (in-memory), ...
  domain/           # espeja lib/domain (un test por entidad/VO/agregado/servicio)
  application/      # un test por caso de uso / app service
```

## 5. Plantilla (ejemplo ILUSTRATIVO — ajusta a las firmas reales del dominio)

**Object Mother** — fabrica agregados válidos:

```dart
// test/_support/mothers/board_mother.dart
class BoardMother {
  static Board withEscapableArrow({int lives = 3}) {
    // tablero mínimo donde la flecha 'a1' tiene su carril despejado
    return LevelBuilder()... // construye un Board válido y consistente
  }

  static Board withBlockedArrow({int lives = 3}) {
    // la flecha 'a1' está bloqueada por otra pieza
    ...
  }

  static Board almostCleared() {
    // solo queda una flecha, que al salir vacía el tablero
    ...
  }
}
```

**Testing API (Builder)** — oculta mocks/fakes y orquesta el SUT:

```dart
// test/_support/apis/remove_arrow_test_api.dart
class RemoveArrowTestApi {
  late Board _board;

  RemoveArrowTestApi givenABoardWithEscapableArrow() {
    _board = BoardMother.withEscapableArrow();
    return this;
  }

  RemoveArrowTestApi givenABoardWithBlockedArrow() {
    _board = BoardMother.withBlockedArrow();
    return this;
  }

  RemoveArrowTestApi whenArrowIsTapped(String arrowId) {
    _board.tryRemoveArrow(CellId(arrowId)); // ejecuta el SUT
    return this;
  }

  void thenArrowShouldEscape() =>
      expect(_board.pullEvents().whereType<ArrowEscaped>(), isNotEmpty);

  void thenALifeShouldBeLost({required int to}) =>
      expect(_board.lives.value, equals(to));

  void thenLevelShouldBeCleared() =>
      expect(_board.status, equals(GameStatus.levelCleared));
}
```

**Test limpio** — se lee como una historia de negocio:

```dart
// test/domain/remove_arrow_test.dart
void main() {
  group('Board — remove arrow', () {
    test('should_remove_arrow_when_path_is_clear', () {
      RemoveArrowTestApi()
          .givenABoardWithEscapableArrow()
          .whenArrowIsTapped('a1')
          .thenArrowShouldEscape();
    });

    test('should_lose_a_life_when_arrow_is_blocked', () {
      RemoveArrowTestApi()
          .givenABoardWithBlockedArrow()
          .whenArrowIsTapped('a1')
          .thenALifeShouldBeLost(to: 2);
    });
  });
}
```

**Interacción (cuando SÍ va un mock)** — ej. app service que llama al `apiClient`:

```dart
class _MockApiClient extends Mock implements IApiClient {}
// ...verificar que se llamó al puerto externo es el comportamiento observable:
verify(() => api.putProgress(any())).called(1);
```

## 6. Checklist antes de dar por hecho un test

- [ ] ¿Se lee como negocio (Given/When/Then) sin mocks visibles en el `test`?
- [ ] ¿La creación del objeto vive en un **Mother**, no en el test?
- [ ] ¿La configuración de mocks/fakes vive en la **Testing API**, no en el test?
- [ ] ¿Verifica estado/resultado (no interacción), salvo que la interacción sea lo observable?
- [ ] ¿El nombre sigue `should_..._when_...`?
- [ ] ¿Existe cobertura para esa entidad/VO/agregado/servicio? (es obligatorio)

## 7. Referencias

- Khonikov, *Unit Testing*, caps. 2–4: test doubles, AAA, Object Mother, 4 pilares.
- R. C. Martin, *Clean Architecture*, cap. 28: *The Test Boundary*.
