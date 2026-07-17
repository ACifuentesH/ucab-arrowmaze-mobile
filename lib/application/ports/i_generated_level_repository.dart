import 'package:arrow_maze/application/builders/level_definition.dart';

/// Puerto de persistencia para niveles generados por el usuario vía IA.
/// La implementación concreta (local Hive/SharedPreferences, remota…) vive
/// en infraestructura — el application layer solo conoce esta interfaz.
abstract interface class IGeneratedLevelRepository {
  Future<void> save(LevelDefinition definition);
  Future<List<LevelDefinition>> findAll();
  Future<LevelDefinition?> findById(String id);
  Future<void> delete(String id);
}
