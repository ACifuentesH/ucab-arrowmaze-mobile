/// Estado del juego como concepto del dominio.
///
/// Es un enum simple consumido mediante `switch` por sus clientes; NO es el
/// patrón State de GoF (no hay jerarquía polimórfica con comportamiento propio
/// por estado). Se decidió no forzar una jerarquía artificial solo para
/// reclamar el patrón — ver docs/DEVELOPMENT_PLAN.md, sección B.
enum GameStatus { playing, levelCleared, gameOver, paused }
