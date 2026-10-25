import 'enums.dart';

/// Servicio del catálogo (solo lectura).
class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.duracionMin,
    required this.precio,
    required this.publico,
  });

  final int id;
  final String nombre;
  final Categoria categoria;
  final int duracionMin;
  final double precio;
  final Publico publico;
}
