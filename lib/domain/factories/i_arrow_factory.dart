import 'package:arrow_maze/domain/entities/arrow.dart';
import 'package:arrow_maze/domain/factories/arrow_spec.dart';

/// Puerto Factory para crear entidades Arrow a partir de su especificación.
abstract interface class IArrowFactory {
  Arrow create(ArrowSpec spec);
}
