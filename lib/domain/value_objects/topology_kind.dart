/// Value Object: la FORMA topológica de un tablero.
///   - [square] → cuadrícula ortogonal de 4 puertos (N/E/S/O).
///   - [hex]    → cuadrícula hexagonal pointy-top de 6 puertos.
///
/// Es el discriminador que el pipeline de carga usa para elegir la
/// `ITopologyStrategy` y la `IArrowFactory` correctas. Se serializa con el
/// nombre del enum (`name`); el default siempre es [square] para no romper la
/// retro-compatibilidad de los niveles cuadrados existentes.
enum TopologyKind {
  square,
  hex;

  /// Parsea el valor crudo del JSON.
  /// `'hex'` → [hex]; cualquier otra cosa (incluido null o basura) → [square].
  static TopologyKind parse(String? raw) =>
      raw == 'hex' ? TopologyKind.hex : TopologyKind.square;
}
