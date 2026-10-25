import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/enums.dart';

/// ViewModel del formulario de cliente (alta y edición). Contiene las validaciones.
class ClienteFormViewModel extends ChangeNotifier {
  ClienteFormViewModel(this._repo, {this.editando}) : _genero = editando?.genero;

  final SalonRepository _repo;
  final Cliente? editando;

  bool get esEdicion => editando != null;

  Genero? _genero;
  Genero? get genero => _genero;

  String? _errorGuardado;
  String? get errorGuardado => _errorGuardado;

  static final RegExp _correo = RegExp(r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');
  static final RegExp _ochoDigitos = RegExp(r'^\d{8}$');

  void elegirGenero(Genero g) {
    _genero = g;
    notifyListeners();
  }

  String? validarNombre(String? v) {
    final n = v?.trim() ?? '';
    if (n.isEmpty) return 'Escribe el nombre';
    if (n.length < 3 || n.length > 60) return 'Escribe entre 3 y 60 caracteres';
    return null;
  }

  String? validarTelefono(String? v) {
    final t = (v ?? '').replaceAll(' ', '');
    if (t.isEmpty) return 'Escribe el teléfono';
    if (!_ochoDigitos.hasMatch(t)) return 'Debe tener exactamente 8 dígitos';
    if (_repo.telefonoEnUso(t, excluirId: editando?.id)) return 'Ese teléfono ya está registrado';
    return null;
  }

  String? validarGenero() => _genero == null ? 'Selecciona un género' : null;

  String? validarCorreo(String? v) {
    final c = v?.trim() ?? '';
    if (c.isEmpty) return null; // opcional
    if (!_correo.hasMatch(c)) return 'Escribe un correo válido';
    return null;
  }

  /// Guarda el cliente. Devuelve null si falla (el motivo queda en [errorGuardado]).
  Cliente? guardar({required String nombre, required String telefono, String? correo}) {
    final tel = telefono.replaceAll(' ', '');
    final mail = (correo ?? '').trim();
    try {
      _errorGuardado = null;
      final e = editando;
      if (e == null) {
        return _repo.crearCliente(
          nombre: nombre.trim(),
          telefono: tel,
          genero: _genero!,
          correo: mail.isEmpty ? null : mail,
        );
      }
      return _repo.actualizarCliente(
        e.copyWith(
          nombre: nombre.trim(),
          telefono: tel,
          genero: _genero,
          correo: mail.isEmpty ? null : mail,
          borrarCorreo: mail.isEmpty,
        ),
      );
    } on StateError catch (err) {
      _errorGuardado = err.message;
      notifyListeners();
      return null;
    }
  }
}
