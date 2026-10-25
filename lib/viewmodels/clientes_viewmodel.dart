import 'package:flutter/foundation.dart';

import '../data/salon_repository.dart';
import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/turno.dart';
import '../utils/formato.dart';

/// ViewModel de la pantalla Clientes: búsqueda, filtro por género y bajas.
class ClientesViewModel extends ChangeNotifier {
  ClientesViewModel(this._repo) {
    _repo.addListener(notifyListeners);
  }

  final SalonRepository _repo;
  SalonRepository get repo => _repo;

  String _busqueda = '';
  FiltroGenero _filtro = FiltroGenero.todos;

  String get busqueda => _busqueda;
  FiltroGenero get filtro => _filtro;

  /// Búsqueda por nombre o teléfono; ignora mayúsculas y acentos y se combina con el género.
  List<Cliente> get clientes {
    final q = normalizar(_busqueda.trim());
    final qDigitos = q.replaceAll(' ', '');
    return _repo.clientes.where((c) {
      if (!_filtro.admite(c.genero)) return false;
      if (q.isEmpty) return true;
      return normalizar(c.nombre).contains(q) || (qDigitos.isNotEmpty && c.telefono.contains(qDigitos));
    }).toList();
  }

  int get total => _repo.clientes.length;
  int get mujeres => _repo.clientes.where((c) => c.genero == Genero.mujer).length;
  int get hombres => _repo.clientes.where((c) => c.genero == Genero.hombre).length;
  bool get sinClientes => _repo.clientes.isEmpty;

  int turnosDe(int clienteId) => _repo.turnosDeCliente(clienteId).length;
  int programadosDe(int clienteId) => _repo.programadosDeCliente(clienteId);
  List<Turno> historialDe(int clienteId) => _repo.turnosDeCliente(clienteId);
  String serviciosDe(Turno t) => _repo.serviciosDe(t).map((s) => s.nombre).join(' + ');
  Cliente? cliente(int id) => _repo.cliente(id);

  /// Primer turno programado del cliente (para el botón "Ver" del aviso).
  Turno? proximoProgramado(int clienteId) {
    final l = _repo.turnosDeCliente(clienteId).where((t) => t.esProgramado).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    return l.isEmpty ? null : l.first;
  }

  void buscar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  void filtrar(FiltroGenero f) {
    _filtro = f;
    notifyListeners();
  }

  ResultadoEliminar eliminar(int clienteId) => _repo.eliminarCliente(clienteId);

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
