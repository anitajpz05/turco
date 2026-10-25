/// Estilista del salón (solo lectura).
class Estilista {
  const Estilista({required this.id, required this.nombre, required this.avatar, required this.servicioIds});

  final int id;
  final String nombre;

  /// Ruta del avatar dentro de assets/.
  final String avatar;

  /// Servicios que realiza.
  final Set<int> servicioIds;

  String get nombreCorto => nombre.split(' ').first;

  bool realizaTodos(Iterable<int> servicios) => servicios.every(servicioIds.contains);
}
