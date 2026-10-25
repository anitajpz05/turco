import 'package:flutter_test/flutter_test.dart';
import 'package:turco/data/salon_repository.dart';
import 'package:turco/models/enums.dart';
import 'package:turco/models/horario.dart';

void main() {
  // Martes 20/10/2026 a las 08:00: todos los turnos de "hoy" son futuros.
  final ahora = DateTime(2026, 10, 20, 8);
  SalonRepository repo() => SalonRepository(reloj: () => ahora);

  test('datos de prueba cumplen los mínimos del enunciado', () {
    final r = repo();
    expect(r.servicios.length, greaterThanOrEqualTo(12));
    expect(r.servicios.map((s) => s.categoria).toSet().length, Categoria.values.length);
    expect(r.servicios.where((s) => s.publico == Publico.mujeres).length, greaterThanOrEqualTo(3));
    expect(r.servicios.where((s) => s.publico == Publico.hombres).length, greaterThanOrEqualTo(3));
    expect(r.servicios.where((s) => s.publico == Publico.unisex).length, greaterThanOrEqualTo(3));
    expect(r.estilistas.length, greaterThanOrEqualTo(5));
    expect(r.clientes.length, greaterThanOrEqualTo(10));
    expect(r.clientes.where((c) => c.genero == Genero.mujer).length, greaterThanOrEqualTo(5));
    expect(r.clientes.where((c) => c.genero == Genero.hombre).length, greaterThanOrEqualTo(5));
    expect(r.turnos.length, greaterThanOrEqualTo(16));
    expect(r.turnosDelDia(ahora).length, greaterThanOrEqualTo(4));
    expect(r.turnos.where((t) => t.estado == EstadoTurno.completado).length, greaterThanOrEqualTo(3));
    expect(r.turnos.where((t) => t.estado == EstadoTurno.cancelado).length, greaterThanOrEqualTo(2));
    expect(r.turnos.any((t) => t.servicioIds.length >= 3), isTrue);
    expect(r.turnos.any((t) => t.notas == null), isTrue);
    expect(r.turnos.any((t) => (t.notas ?? '').length > 300), isTrue);
    expect(r.turnos.any((t) => Horario.minutosDe(r.finDe(t)) == Horario.cierreMin), isTrue);
    expect(r.clientes.any((c) => r.turnosDeCliente(c.id).isEmpty), isTrue);
    expect(r.estilistas.any((e) => r.programadosHoyDe(e.id) == 0), isTrue);
    expect(r.turnos.any((t) => Horario.esDomingo(t.inicio)), isFalse);
    for (final t in r.turnos) {
      expect(r.estilista(t.estilistaId)!.realizaTodos(t.servicioIds), isTrue, reason: 'turno ${t.id}');
      expect(
        t.inicio.isAfter(ahora) == t.esProgramado || t.estado == EstadoTurno.cancelado,
        isTrue,
        reason: 'turno ${t.id}',
      );
    }
  });

  test('ningún par de turnos programados se solapa', () {
    final r = repo();
    final p = r.turnos.where((t) => t.esProgramado).toList();
    for (var i = 0; i < p.length; i++) {
      for (var j = i + 1; j < p.length; j++) {
        final a = p[i], b = p[j];
        if (a.estilistaId != b.estilistaId && a.clienteId != b.clienteId) continue;
        expect(
          Horario.seSolapan(a.inicio, r.finDe(a), b.inicio, r.finDe(b)),
          isFalse,
          reason: 'turnos ${a.id} y ${b.id}',
        );
      }
    }
  });

  test('reglas de solape, cierre y cancelación', () {
    final r = repo();
    final carlos = r.turnosDelDia(ahora).firstWhere((t) => t.clienteId == 2); // 10:00-11:30 con Pedro
    // Solapa con Pedro
    expect(
      r.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [3], inicio: DateTime(2026, 10, 20, 11)),
      isNotNull,
    );
    // Termina justo cuando empieza otro: no solapa
    expect(
      r.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [3], inicio: DateTime(2026, 10, 20, 9, 30)),
      isNull,
    );
    // Después de las 19:00
    expect(
      r.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [2], inicio: DateTime(2026, 10, 20, 18, 30)),
      isNotNull,
    );
    // Al cancelar, el horario queda libre
    r.cancelarTurno(carlos.id);
    expect(r.validarTurno(clienteId: 6, estilistaId: 2, servicioIds: [3], inicio: DateTime(2026, 10, 20, 11)), isNull);
  });

  test('no se elimina un cliente con turnos programados', () {
    final r = repo();
    expect(r.eliminarCliente(2), ResultadoEliminar.tieneProgramados);
    expect(r.eliminarCliente(6), ResultadoEliminar.eliminado);
  });
}
