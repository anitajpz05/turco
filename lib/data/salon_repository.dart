import 'package:flutter/foundation.dart';

import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';
import 'datos_prueba.dart';

/// Estado de una franja horaria en el formulario de turno.
enum MotivoFranja { libre, ocupadaEstilista, ocupadaCliente, pasada, excedeCierre }

class Franja {
  const Franja(this.minutos, this.motivo);
  final int minutos;
  final MotivoFranja motivo;
  bool get disponible => motivo == MotivoFranja.libre;
}

/// Resultado de intentar eliminar un cliente.
enum ResultadoEliminar { eliminado, tieneProgramados, noExiste }

/// Modelo de la aplicación: datos en memoria y reglas de negocio.
///
/// Es la única fuente de verdad. Al ser un [ChangeNotifier], todas las
/// pantallas que lo escuchan se actualizan de inmediato ante cualquier cambio.
class SalonRepository extends ChangeNotifier {
  SalonRepository({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now {
    final datos = DatosPrueba.generar(_reloj());
    _servicios = List.unmodifiable(datos.servicios);
    _estilistas = List.unmodifiable(datos.estilistas);
    _clientes.addAll(datos.clientes);
    _turnos.addAll(datos.turnos);
    _siguienteCliente = _clientes.fold(0, (m, c) => c.id > m ? c.id : m) + 1;
    _siguienteTurno = _turnos.fold(0, (m, t) => t.id > m ? t.id : m) + 1;
  }

  final DateTime Function() _reloj;
  DateTime get ahora => _reloj();

  late final List<Servicio> _servicios;
  late final List<Estilista> _estilistas;
  final List<Cliente> _clientes = [];
  final List<Turno> _turnos = [];
  int _siguienteCliente = 1;
  int _siguienteTurno = 1;

  // ---------------------------------------------------------------- Lecturas

  List<Servicio> get servicios => _servicios;
  List<Estilista> get estilistas => _estilistas;
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Turno> get turnos => List.unmodifiable(_turnos);

  Servicio? servicio(int id) => _servicios.where((s) => s.id == id).firstOrNull;
  Estilista? estilista(int id) => _estilistas.where((e) => e.id == id).firstOrNull;
  Cliente? cliente(int id) => _clientes.where((c) => c.id == id).firstOrNull;
  Turno? turno(int id) => _turnos.where((t) => t.id == id).firstOrNull;

  List<Servicio> serviciosDe(Turno t) => serviciosPorIds(t.servicioIds);

  List<Servicio> serviciosPorIds(Iterable<int> ids) => ids.map(servicio).whereType<Servicio>().toList();

  int duracionDe(Turno t) => Turno.duracionDe(serviciosDe(t));
  double precioDe(Turno t) => Turno.precioDe(serviciosDe(t));
  DateTime finDe(Turno t) => t.inicio.add(Duration(minutes: duracionDe(t)));

  /// Turnos de un día ordenados por hora de inicio.
  List<Turno> turnosDelDia(DateTime dia) {
    final lista = _turnos.where((t) => Horario.mismoDia(t.inicio, dia)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    return lista;
  }

  /// Historial de un cliente, del más reciente al más antiguo.
  List<Turno> turnosDeCliente(int clienteId) {
    final lista = _turnos.where((t) => t.clienteId == clienteId).toList()..sort((a, b) => b.inicio.compareTo(a.inicio));
    return lista;
  }

  int programadosDeCliente(int clienteId) => _turnos.where((t) => t.clienteId == clienteId && t.esProgramado).length;

  int programadosHoyDe(int estilistaId) =>
      _turnos.where((t) => t.estilistaId == estilistaId && t.esProgramado && Horario.mismoDia(t.inicio, ahora)).length;

  /// Estilistas que realizan todos los servicios indicados.
  List<Estilista> estilistasPara(Iterable<int> servicioIds) =>
      _estilistas.where((e) => e.realizaTodos(servicioIds)).toList();

  // ----------------------------------------------------- Reglas de horario

  /// Indica si el intervalo choca con algún turno programado del estilista o del cliente.
  /// Los cancelados no ocupan horario; los completados ya pasaron.
  MotivoFranja? _conflicto({
    required DateTime inicio,
    required DateTime fin,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
  }) {
    for (final t in _turnos) {
      if (t.id == excluirTurnoId || !t.esProgramado) continue;
      if (!Horario.mismoDia(t.inicio, inicio)) continue;
      if (!Horario.seSolapan(inicio, fin, t.inicio, finDe(t))) continue;
      if (estilistaId != null && t.estilistaId == estilistaId) return MotivoFranja.ocupadaEstilista;
      if (clienteId != null && t.clienteId == clienteId) return MotivoFranja.ocupadaCliente;
    }
    return null;
  }

  /// Estado de cada franja de 30 minutos de [fecha] para un turno de [duracionMin].
  List<Franja> franjas({
    required DateTime fecha,
    required int duracionMin,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
  }) {
    final ahora = this.ahora;
    final dur = duracionMin <= 0 ? Horario.pasoMin : duracionMin;
    return [
      for (final m in Horario.franjas)
        Franja(m, _motivoFranja(fecha, m, dur, ahora, estilistaId, clienteId, excluirTurnoId)),
    ];
  }

  MotivoFranja _motivoFranja(
    DateTime fecha,
    int minutos,
    int dur,
    DateTime ahora,
    int? estilistaId,
    int? clienteId,
    int? excluirTurnoId,
  ) {
    final inicio = Horario.enMinutos(fecha, minutos);
    if (!inicio.isAfter(ahora)) return MotivoFranja.pasada;
    if (minutos + dur > Horario.cierreMin) return MotivoFranja.excedeCierre;
    return _conflicto(
          inicio: inicio,
          fin: inicio.add(Duration(minutes: dur)),
          estilistaId: estilistaId,
          clienteId: clienteId,
          excluirTurnoId: excluirTurnoId,
        ) ??
        MotivoFranja.libre;
  }

  /// Valida todas las reglas de negocio antes de guardar. Devuelve el mensaje de error o null.
  String? validarTurno({
    required int clienteId,
    required int estilistaId,
    required List<int> servicioIds,
    required DateTime inicio,
    int? excluirTurnoId,
  }) {
    if (cliente(clienteId) == null) return 'El cliente no existe.';
    final est = estilista(estilistaId);
    if (est == null) return 'El estilista no existe.';
    if (servicioIds.isEmpty) return 'Elige al menos un servicio.';
    if (!est.realizaTodos(servicioIds)) return '${est.nombreCorto} no realiza todos los servicios elegidos.';
    if (Horario.esDomingo(inicio)) return 'El salón está cerrado los domingos.';
    if (!inicio.isAfter(ahora)) return 'No se pueden programar turnos en el pasado.';
    final m = Horario.minutosDe(inicio);
    if (m < Horario.aperturaMin || m % Horario.pasoMin != 0) return 'La hora debe ser una franja de 30 minutos.';
    final dur = Turno.duracionDe(serviciosPorIds(servicioIds));
    if (m + dur > Horario.cierreMin) return 'El turno terminaría después de las 19:00.';
    final c = _conflicto(
      inicio: inicio,
      fin: inicio.add(Duration(minutes: dur)),
      estilistaId: estilistaId,
      clienteId: clienteId,
      excluirTurnoId: excluirTurnoId,
    );
    if (c == MotivoFranja.ocupadaEstilista) return '${est.nombreCorto} ya tiene un turno en ese horario.';
    if (c == MotivoFranja.ocupadaCliente) return 'El cliente ya tiene un turno en ese horario.';
    return null;
  }

  // ----------------------------------------------------- Escrituras turnos

  /// Crea un turno. Lanza [StateError] si viola alguna regla.
  Turno crearTurno({
    required int clienteId,
    required int estilistaId,
    required List<int> servicioIds,
    required DateTime inicio,
    String? notas,
  }) {
    final error = validarTurno(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: servicioIds,
      inicio: inicio,
    );
    if (error != null) throw StateError(error);
    final ahora = this.ahora;
    final t = Turno(
      id: _siguienteTurno++,
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: List.unmodifiable(servicioIds),
      inicio: inicio,
      notas: _limpiar(notas),
      estado: EstadoTurno.programado,
      creado: ahora,
      modificado: ahora,
    );
    _turnos.add(t);
    notifyListeners();
    return t;
  }

  /// Reprograma/edita un turno programado.
  Turno actualizarTurno({
    required int id,
    required int clienteId,
    required int estilistaId,
    required List<int> servicioIds,
    required DateTime inicio,
    String? notas,
  }) {
    final i = _turnos.indexWhere((t) => t.id == id);
    if (i < 0) throw StateError('El turno no existe.');
    if (!_turnos[i].esProgramado) throw StateError('Solo se pueden editar turnos programados.');
    final error = validarTurno(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: servicioIds,
      inicio: inicio,
      excluirTurnoId: id,
    );
    if (error != null) throw StateError(error);
    final limpio = _limpiar(notas);
    final t = _turnos[i].copyWith(
      clienteId: clienteId,
      estilistaId: estilistaId,
      servicioIds: List.unmodifiable(servicioIds),
      inicio: inicio,
      notas: limpio,
      borrarNotas: limpio == null,
      modificado: ahora,
    );
    _turnos[i] = t;
    notifyListeners();
    return t;
  }

  void completarTurno(int id) => _cambiarEstado(id, EstadoTurno.completado);

  /// La cancelación es la baja: el turno se conserva en el historial y su horario queda libre.
  void cancelarTurno(int id) => _cambiarEstado(id, EstadoTurno.cancelado);

  void _cambiarEstado(int id, EstadoTurno estado) {
    final i = _turnos.indexWhere((t) => t.id == id);
    if (i < 0 || !_turnos[i].esProgramado) return;
    _turnos[i] = _turnos[i].copyWith(estado: estado, modificado: ahora);
    notifyListeners();
  }

  // ---------------------------------------------------- Escrituras clientes

  bool telefonoEnUso(String telefono, {int? excluirId}) =>
      _clientes.any((c) => c.telefono == telefono && c.id != excluirId);

  Cliente crearCliente({required String nombre, required String telefono, required Genero genero, String? correo}) {
    if (telefonoEnUso(telefono)) throw StateError('Ese teléfono ya está registrado.');
    final c = Cliente(
      id: _siguienteCliente++,
      nombre: nombre.trim(),
      telefono: telefono,
      genero: genero,
      correo: _limpiar(correo),
      fechaRegistro: ahora,
    );
    _clientes.add(c);
    notifyListeners();
    return c;
  }

  Cliente actualizarCliente(Cliente c) {
    final i = _clientes.indexWhere((x) => x.id == c.id);
    if (i < 0) throw StateError('El cliente no existe.');
    if (telefonoEnUso(c.telefono, excluirId: c.id)) throw StateError('Ese teléfono ya está registrado.');
    _clientes[i] = c;
    notifyListeners();
    return c;
  }

  /// No se elimina un cliente con turnos programados. Si no los tiene, se elimina
  /// junto con su historial de turnos completados y cancelados.
  ResultadoEliminar eliminarCliente(int id) {
    if (cliente(id) == null) return ResultadoEliminar.noExiste;
    if (programadosDeCliente(id) > 0) return ResultadoEliminar.tieneProgramados;
    _turnos.removeWhere((t) => t.clienteId == id);
    _clientes.removeWhere((c) => c.id == id);
    notifyListeners();
    return ResultadoEliminar.eliminado;
  }

  static String? _limpiar(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
