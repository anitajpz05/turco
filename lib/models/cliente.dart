import 'enums.dart';

/// Cliente del salón.
class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.genero,
    this.correo,
    required this.fechaRegistro,
  });

  final int id;
  final String nombre;

  /// 8 dígitos, único.
  final String telefono;
  final Genero genero;
  final String? correo;
  final DateTime fechaRegistro;

  String get inicial => nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();

  Cliente copyWith({String? nombre, String? telefono, Genero? genero, String? correo, bool borrarCorreo = false}) {
    return Cliente(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      genero: genero ?? this.genero,
      correo: borrarCorreo ? null : (correo ?? this.correo),
      fechaRegistro: fechaRegistro,
    );
  }
}
