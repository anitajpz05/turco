import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Datos iniciales que otras pantallas envían al formulario (vía `extra`).
class TurnoFormArgs {
  const TurnoFormArgs({this.clienteId, this.servicioId, this.fecha});
  final int? clienteId;
  final int? servicioId;
  final DateTime? fecha;
}

/// Campos del formulario en el orden en que aparecen (para mover el foco al primer error).
enum CampoTurno { cliente, servicios, estilista, fecha, hora, notas }

/// ViewModel del formulario de turno (crear y editar).
///
/// Contiene toda la lógica: estilistas válidos, cálculo de franjas libres,
/// duración, hora de fin y precio total. La vista solo pinta y delega.
class TurnoFormViewModel extends ChangeNotifier {
  TurnoFormViewModel(this._repo, {this.editando, TurnoFormArgs? args}) {
    final e = editando;
    if (e != null) {
      _clienteId = e.clienteId;
      _servicioIds.addAll(e.servicioIds);
      _estilistaId = e.estilistaId;
      _fecha = Horario.soloFecha(e.inicio);
      _hora = Horario.minutosDe(e.inicio);
      notas = e.notas ?? '';
    } else if (args != null) {
      if (args.clienteId != null && _repo.cliente(args.clienteId!) != null) _clienteId = args.clienteId;
      if (args.servicioId != null && _repo.servicio(args.servicioId!) != null) _servicioIds.add(args.servicioId!);
      if (args.fecha != null && fechaSeleccionable(args.fecha!)) _fecha = Horario.soloFecha(args.fecha!);
    }
    final c = cliente;
    if (c != null) _publico = FiltroPublico.desdeGenero(c.genero);
    _inicial = _huella();
    _repo.addListener(_alCambiarRepo);
  }

  final SalonRepository _repo;
  final Turno? editando;
  bool get esEdicion => editando != null;

  int? _clienteId;
  final List<int> _servicioIds = [];
  FiltroPublico _publico = FiltroPublico.todos;
  int? _estilistaId;
  DateTime? _fecha;
  int? _hora; // minutos desde medianoche
  String notas = '';
  static const int maxNotas = 500;

  late final String _inicial;
  bool _guardado = false;
  String? _aviso;
  String? _errorGuardado;

  // ------------------------------------------------------------- Lectura

  int? get clienteId => _clienteId;
  List<int> get servicioIds => List.unmodifiable(_servicioIds);
  FiltroPublico get publico => _publico;
  int? get estilistaId => _estilistaId;
  DateTime? get fecha => _fecha;
  int? get hora => _hora;
  String? get errorGuardado => _errorGuardado;

  Cliente? get cliente => _clienteId == null ? null : _repo.cliente(_clienteId!);
  Estilista? get estilista => _estilistaId == null ? null : _repo.estilista(_estilistaId!);

  List<Cliente> get clientes => [..._repo.clientes]..sort((a, b) => a.nombre.compareTo(b.nombre));

  bool estaElegido(int servicioId) => _servicioIds.contains(servicioId);

  /// Servicios agrupados por categoría según el filtro de público
  /// (los ya elegidos se muestran siempre para poder quitarlos).
  Map<Categoria, List<Servicio>> get serviciosPorCategoria {
    final mapa = <Categoria, List<Servicio>>{};
    for (final cat in Categoria.values) {
      final l = _repo.servicios
          .where((s) => s.categoria == cat && (_publico.admite(s.publico) || estaElegido(s.id)))
          .toList();
      if (l.isNotEmpty) mapa[cat] = l;
    }
    return mapa;
  }

  List<Servicio> get serviciosElegidos => _repo.serviciosPorIds(_servicioIds);

  /// Solo los estilistas que realizan TODOS los servicios elegidos.
  List<Estilista> get estilistasValidos => _servicioIds.isEmpty ? const [] : _repo.estilistasPara(_servicioIds);

  int get duracion => Turno.duracionDe(serviciosElegidos);
  double get precio => Turno.precioDe(serviciosElegidos);
  int? get finMinutos => _hora == null ? null : _hora! + duracion;

  /// Franjas de 30 minutos con su disponibilidad (se recalculan con servicios, estilista y fecha).
  List<Franja> get franjas {
    if (_fecha == null) {
      return [for (final m in Horario.franjas) Franja(m, MotivoFranja.libre)];
    }
    return _repo.franjas(
      fecha: _fecha!,
      duracionMin: duracion,
      estilistaId: _estilistaId,
      clienteId: _clienteId,
      excluirTurnoId: editando?.id,
    );
  }

  bool get hayFranjasLibres => franjas.any((f) => f.disponible);

  bool get hayCambios => !_guardado && _huella() != _inicial;

  /// No se permiten fechas pasadas ni domingos.
  bool fechaSeleccionable(DateTime d) =>
      !Horario.esDomingo(d) && !Horario.soloFecha(d).isBefore(Horario.soloFecha(_repo.ahora));

  DateTime get primeraFechaPermitida => Horario.soloFecha(_repo.ahora);

  DateTime get fechaInicialPicker {
    if (_fecha != null && fechaSeleccionable(_fecha!)) return _fecha!;
    var d = primeraFechaPermitida;
    while (!fechaSeleccionable(d)) {
      d = Horario.sumarDias(d, 1);
    }
    return d;
  }

  /// Aviso de un solo uso para mostrar en un SnackBar (p. ej. estilista limpiado).
  String? consumirAviso() {
    final a = _aviso;
    _aviso = null;
    return a;
  }

  // ------------------------------------------------------------- Acciones

  void elegirCliente(int id) {
    _clienteId = id;
    final c = cliente;
    if (c != null) _publico = FiltroPublico.desdeGenero(c.genero);
    _revisarHora();
    notifyListeners();
  }

  void elegirPublico(FiltroPublico p) {
    _publico = p;
    notifyListeners();
  }

  void alternarServicio(int id) {
    if (!_servicioIds.remove(id)) _servicioIds.add(id);
    final e = estilista;
    if (e != null && !e.realizaTodos(_servicioIds)) {
      _estilistaId = null;
      _aviso = '${e.nombreCorto} no realiza todos los servicios elegidos. Elige otro estilista.';
    }
    _revisarHora();
    notifyListeners();
  }

  void elegirEstilista(int id) {
    _estilistaId = id;
    _revisarHora();
    notifyListeners();
  }

  void elegirFecha(DateTime d) {
    _fecha = Horario.soloFecha(d);
    _revisarHora();
    notifyListeners();
  }

  void elegirHora(int minutos) {
    final f = franjas.where((x) => x.minutos == minutos).firstOrNull;
    if (f == null || !f.disponible) return;
    _hora = minutos;
    notifyListeners();
  }

  void cambiarNotas(String v) {
    notas = v;
  }

  /// Si la hora elegida deja de estar disponible, se limpia y se avisa.
  void _revisarHora() {
    if (_hora == null || _fecha == null) return;
    final f = franjas.where((x) => x.minutos == _hora).firstOrNull;
    if (f == null || !f.disponible) {
      _hora = null;
      _aviso ??= 'La hora elegida ya no está disponible. Elige otra.';
    }
  }

  void _alCambiarRepo() {
    if (_guardado) return;
    _revisarHora();
    notifyListeners();
  }

  // ---------------------------------------------------------- Validaciones

  String? validarCliente() => cliente == null ? 'Selecciona un cliente' : null;

  String? validarServicios() => _servicioIds.isEmpty ? 'Elige al menos un servicio' : null;

  String? validarEstilista() {
    final e = estilista;
    if (e == null) return 'Selecciona un estilista';
    if (!e.realizaTodos(_servicioIds)) return '${e.nombreCorto} no realiza todos los servicios elegidos';
    return null;
  }

  String? validarFecha() {
    if (_fecha == null || !fechaSeleccionable(_fecha!)) return 'Elige una fecha válida (no domingos)';
    return null;
  }

  String? validarHora() {
    if (_hora == null) return 'Elige una hora para el turno';
    if (_fecha != null && _hora! + duracion > Horario.cierreMin) return 'El turno debe terminar antes de las 19:00';
    return null;
  }

  String? validarNotas(String? v) => (v?.length ?? 0) > maxNotas ? 'Máximo $maxNotas caracteres' : null;

  CampoTurno? get primerCampoConError {
    if (validarCliente() != null) return CampoTurno.cliente;
    if (validarServicios() != null) return CampoTurno.servicios;
    if (validarEstilista() != null) return CampoTurno.estilista;
    if (validarFecha() != null) return CampoTurno.fecha;
    if (validarHora() != null) return CampoTurno.hora;
    if (validarNotas(notas) != null) return CampoTurno.notas;
    return null;
  }

  /// Guarda el turno aplicando todas las reglas de negocio del modelo.
  Turno? guardar() {
    _errorGuardado = null;
    if (primerCampoConError != null) return null;
    final inicio = Horario.enMinutos(_fecha!, _hora!);
    _guardado = true; // evita reaccionar a la notificación del propio guardado
    try {
      final e = editando;
      final t = e == null
          ? _repo.crearTurno(
              clienteId: _clienteId!,
              estilistaId: _estilistaId!,
              servicioIds: List.of(_servicioIds),
              inicio: inicio,
              notas: notas,
            )
          : _repo.actualizarTurno(
              id: e.id,
              clienteId: _clienteId!,
              estilistaId: _estilistaId!,
              servicioIds: List.of(_servicioIds),
              inicio: inicio,
              notas: notas,
            );
      return t;
    } on StateError catch (err) {
      _guardado = false;
      _errorGuardado = err.message;
      notifyListeners();
      return null;
    }
  }

  String _huella() =>
      '$_clienteId|${_servicioIds.join(',')}|$_estilistaId|${_fecha?.toIso8601String()}|$_hora|${notas.trim()}';

  @override
  void dispose() {
    _repo.removeListener(_alCambiarRepo);
    super.dispose();
  }
}
