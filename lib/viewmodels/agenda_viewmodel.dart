import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/turno.dart';

enum FiltroEstado {
  todos('Todos', null),
  programados('Program.', EstadoTurno.programado),
  completados('Complet.', EstadoTurno.completado),
  cancelados('Cancel.', EstadoTurno.cancelado);

  const FiltroEstado(this.etiqueta, this.estado);
  final String etiqueta;
  final EstadoTurno? estado;
}

/// ViewModel de la Agenda: fecha seleccionada, filtros y resumen del día.
class AgendaViewModel extends ChangeNotifier {
  /// Fecha inicial: hoy (si es domingo, día cerrado, se muestra el lunes).
  AgendaViewModel(this._repo) : _fecha = _diaInicial(_repo.ahora) {
    _repo.addListener(notifyListeners);
  }

  final SalonRepository _repo;
  SalonRepository get repo => _repo;

  static DateTime _diaInicial(DateTime ahora) {
    final hoy = Horario.soloFecha(ahora);
    return Horario.esDomingo(hoy) ? Horario.sumarDias(hoy, 1) : hoy;
  }

  DateTime _fecha;
  int? _estilistaId;
  FiltroEstado _filtroEstado = FiltroEstado.todos;

  DateTime get fecha => _fecha;
  int? get estilistaId => _estilistaId;
  FiltroEstado get filtroEstado => _filtroEstado;

  List<Estilista> get estilistas => _repo.estilistas;

  /// Los siete días (lunes a domingo) de la semana de la fecha seleccionada.
  List<DateTime> get semana {
    final lunes = Horario.lunesDe(_fecha);
    return [for (int i = 0; i < 7; i++) Horario.sumarDias(lunes, i)];
  }

  bool esHoy(DateTime d) => Horario.mismoDia(d, _repo.ahora);
  bool esCerrado(DateTime d) => Horario.esDomingo(d);
  bool get diaCerrado => Horario.esDomingo(_fecha);

  List<Turno> get _delDia => _repo.turnosDelDia(_fecha);

  /// Turnos del día que cumplen los filtros, ordenados por hora.
  List<Turno> get turnos => _delDia
      .where((t) => _estilistaId == null || t.estilistaId == _estilistaId)
      .where((t) => _filtroEstado.estado == null || t.estado == _filtroEstado.estado)
      .toList();

  bool get diaSinTurnos => _delDia.isEmpty;

  int get programados => _delDia.where((t) => t.estado == EstadoTurno.programado).length;
  int get completados => _delDia.where((t) => t.estado == EstadoTurno.completado).length;

  /// Suma de los totales de los turnos programados y completados (sin cancelados).
  double get ingresoEstimado =>
      _delDia.where((t) => t.estado != EstadoTurno.cancelado).fold(0.0, (s, t) => s + _repo.precioDe(t));

  // ---- Datos derivados de cada turno (para la vista)
  String clienteDe(Turno t) => _repo.cliente(t.clienteId)?.nombre ?? 'Cliente eliminado';
  String estilistaDe(Turno t) => _repo.estilista(t.estilistaId)?.nombreCorto ?? '—';
  String serviciosDe(Turno t) => _repo.serviciosDe(t).map((s) => s.nombre).join(' + ');
  DateTime finDe(Turno t) => _repo.finDe(t);

  // ---- Acciones
  void seleccionarFecha(DateTime d) {
    _fecha = Horario.soloFecha(d);
    notifyListeners();
  }

  void semanaAnterior() => seleccionarFecha(Horario.sumarDias(_fecha, -7));
  void semanaSiguiente() => seleccionarFecha(Horario.sumarDias(_fecha, 7));

  void filtrarEstilista(int? id) {
    _estilistaId = id;
    notifyListeners();
  }

  void filtrarEstado(FiltroEstado f) {
    _filtroEstado = f;
    notifyListeners();
  }

  /// Filtro recibido desde la ruta (/agenda?estilista=3): muestra hoy con ese estilista.
  void aplicarEstilistaDesdeRuta(int id) {
    if (_repo.estilista(id) == null) return;
    _estilistaId = id;
    _fecha = _diaInicial(_repo.ahora);
    _filtroEstado = FiltroEstado.todos;
    notifyListeners();
  }

  void completar(int turnoId) => _repo.completarTurno(turnoId);
  void cancelar(int turnoId) => _repo.cancelarTurno(turnoId);

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
