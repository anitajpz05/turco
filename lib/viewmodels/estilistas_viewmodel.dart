import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/enums.dart';
import '../models/estilista.dart';

/// ViewModel de la pantalla Estilistas.
class EstilistasViewModel extends ChangeNotifier {
  EstilistasViewModel(this._repo) {
    _repo.addListener(notifyListeners);
  }

  final SalonRepository _repo;

  List<Estilista> get estilistas => _repo.estilistas;

  int programadosHoy(int estilistaId) => _repo.programadosHoyDe(estilistaId);

  int get totalProgramadosHoy => _repo.estilistas.fold(0, (s, e) => s + programadosHoy(e.id));

  /// Servicios que realiza agrupados por categoría (en el orden del catálogo).
  Map<Categoria, List<String>> serviciosPorCategoria(Estilista e) {
    final mapa = <Categoria, List<String>>{};
    for (final s in _repo.servicios.where((s) => e.servicioIds.contains(s.id))) {
      mapa.putIfAbsent(s.categoria, () => []).add(s.nombre);
    }
    return mapa;
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
