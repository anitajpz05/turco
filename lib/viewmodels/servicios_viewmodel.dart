import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/enums.dart';
import '../models/servicio.dart';

/// ViewModel del catálogo de servicios (solo lectura) con filtros.
class ServiciosViewModel extends ChangeNotifier {
  ServiciosViewModel(this._repo);

  final SalonRepository _repo;

  Categoria? _categoria; // null = Todas
  FiltroPublico _publico = FiltroPublico.todos;

  Categoria? get categoria => _categoria;
  FiltroPublico get publico => _publico;

  List<Servicio> get servicios => _repo.servicios
      .where((s) => _categoria == null || s.categoria == _categoria)
      .where((s) => _publico.admite(s.publico))
      .toList();

  void filtrarCategoria(Categoria? c) {
    _categoria = c;
    notifyListeners();
  }

  void filtrarPublico(FiltroPublico p) {
    _publico = p;
    notifyListeners();
  }

  void limpiarFiltros() {
    _categoria = null;
    _publico = FiltroPublico.todos;
    notifyListeners();
  }
}
