import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/estilista.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// ViewModel del Detalle de turno. Se mantiene sincronizado con el repositorio.
class TurnoDetalleViewModel extends ChangeNotifier {
  TurnoDetalleViewModel(this._repo, this.turnoId) {
    _repo.addListener(notifyListeners);
  }

  final SalonRepository _repo;

  /// null si el identificador de la ruta no es un número.
  final int? turnoId;

  Turno? get turno => turnoId == null ? null : _repo.turno(turnoId!);
  bool get existe => turno != null;

  Cliente? get cliente => turno == null ? null : _repo.cliente(turno!.clienteId);
  Estilista? get estilista => turno == null ? null : _repo.estilista(turno!.estilistaId);
  List<Servicio> get servicios => turno == null ? const [] : _repo.serviciosDe(turno!);
  int get duracion => Turno.duracionDe(servicios);
  double get total => Turno.precioDe(servicios);
  DateTime? get fin => turno?.inicio.add(Duration(minutes: duracion));

  /// Solo los turnos programados se pueden editar, completar o cancelar.
  bool get editable => turno?.esProgramado ?? false;

  void completar() {
    if (editable) _repo.completarTurno(turnoId!);
  }

  void cancelar() {
    if (editable) _repo.cancelarTurno(turnoId!);
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
