import '../models/cliente.dart';
import '../models/enums.dart';
import '../models/estilista.dart';
import '../models/horario.dart';
import '../models/servicio.dart';
import '../models/turno.dart';

/// Datos de prueba cargados en memoria al iniciar la app.
///
/// Las fechas de los turnos se calculan a partir de [DateTime.now] para que
/// nunca queden vencidas: los turnos pasados quedan completados o cancelados
/// y los futuros, programados.
class DatosPrueba {
  DatosPrueba._(this.servicios, this.estilistas, this.clientes, this.turnos);

  final List<Servicio> servicios;
  final List<Estilista> estilistas;
  final List<Cliente> clientes;
  final List<Turno> turnos;

  // 13 servicios en 5 categorías: 5 solo mujeres, 4 solo hombres, 4 unisex.
  static const List<Servicio> _servicios = [
    Servicio(
      id: 1,
      nombre: 'Corte mujer',
      categoria: Categoria.corte,
      duracionMin: 60,
      precio: 30,
      publico: Publico.mujeres,
    ),
    Servicio(
      id: 2,
      nombre: 'Corte caballero',
      categoria: Categoria.corte,
      duracionMin: 45,
      precio: 25,
      publico: Publico.hombres,
    ),
    Servicio(
      id: 3,
      nombre: 'Corte clásico',
      categoria: Categoria.corte,
      duracionMin: 30,
      precio: 18,
      publico: Publico.hombres,
    ),
    Servicio(
      id: 4,
      nombre: 'Corte de puntas',
      categoria: Categoria.corte,
      duracionMin: 30,
      precio: 15,
      publico: Publico.unisex,
    ),
    Servicio(
      id: 5,
      nombre: 'Color completo',
      categoria: Categoria.color,
      duracionMin: 120,
      precio: 70,
      publico: Publico.mujeres,
    ),
    Servicio(
      id: 6,
      nombre: 'Mechas',
      categoria: Categoria.color,
      duracionMin: 90,
      precio: 55,
      publico: Publico.mujeres,
    ),
    Servicio(
      id: 7,
      nombre: 'Matiz de canas',
      categoria: Categoria.color,
      duracionMin: 45,
      precio: 30,
      publico: Publico.unisex,
    ),
    Servicio(id: 8, nombre: 'Barba', categoria: Categoria.barba, duracionMin: 45, precio: 20, publico: Publico.hombres),
    Servicio(
      id: 9,
      nombre: 'Afeitado',
      categoria: Categoria.barba,
      duracionMin: 30,
      precio: 15,
      publico: Publico.hombres,
    ),
    Servicio(
      id: 10,
      nombre: 'Peinado evento',
      categoria: Categoria.peinado,
      duracionMin: 60,
      precio: 40,
      publico: Publico.unisex,
    ),
    Servicio(
      id: 11,
      nombre: 'Brushing',
      categoria: Categoria.peinado,
      duracionMin: 45,
      precio: 22,
      publico: Publico.mujeres,
    ),
    Servicio(
      id: 12,
      nombre: 'Hidratación',
      categoria: Categoria.tratamiento,
      duracionMin: 45,
      precio: 28,
      publico: Publico.unisex,
    ),
    Servicio(
      id: 13,
      nombre: 'Keratina',
      categoria: Categoria.tratamiento,
      duracionMin: 90,
      precio: 60,
      publico: Publico.mujeres,
    ),
  ];

  // 5 estilistas: Marta solo mujeres, Pedro solo hombres, Lucía ambos.
  static const List<Estilista> _estilistas = [
    Estilista(id: 1, nombre: 'Marta Salazar', avatar: 'assets/images/avatares/marta.png', servicioIds: {1, 5, 6, 11}),
    Estilista(id: 2, nombre: 'Pedro Vega', avatar: 'assets/images/avatares/pedro.png', servicioIds: {2, 3, 8, 9}),
    Estilista(
      id: 3,
      nombre: 'Lucía Torres',
      avatar: 'assets/images/avatares/lucia.png',
      servicioIds: {12, 13, 1, 2, 4},
    ),
    Estilista(id: 4, nombre: 'Rafael Núñez', avatar: 'assets/images/avatares/rafael.png', servicioIds: {8, 9, 2, 4}),
    Estilista(id: 5, nombre: 'Elena Ríos', avatar: 'assets/images/avatares/elena.png', servicioIds: {10, 11, 7, 12}),
  ];

  static const String _notasLargas =
      'Cliente con cuero cabelludo sensible: usar productos sin sulfatos y agua tibia, nunca caliente. '
      'En la visita anterior pidió que la keratina no tocara la raíz y que se dejara reposar el tiempo completo '
      'antes de secar. Prefiere conversar poco durante el servicio y le gusta que le expliquen cada paso del '
      'tratamiento antes de empezar. Traerá una foto de referencia para el corte de puntas. Si se atrasa más de '
      'quince minutos, avisar por teléfono antes de reasignar el horario.';

  static DatosPrueba generar(DateTime ahora) {
    final hoyReal = Horario.soloFecha(ahora);
    // El salón cierra los domingos: si hoy es domingo, el "día base" es el lunes.
    final base = Horario.esDomingo(hoyReal) ? Horario.sumarDias(hoyReal, 1) : hoyReal;

    /// Día laborable a [n] días laborables de la base (salta domingos).
    DateTime dia(int n) {
      var d = base;
      final paso = n >= 0 ? 1 : -1;
      for (int i = 0; i < n.abs(); i++) {
        d = Horario.sumarDias(d, paso);
        if (Horario.esDomingo(d)) d = Horario.sumarDias(d, paso);
      }
      return d;
    }

    final clientes = <Cliente>[
      Cliente(
        id: 1,
        nombre: 'Laura Gómez',
        telefono: '52111222',
        genero: Genero.mujer,
        correo: 'laura.gomez@correo.com',
        fechaRegistro: Horario.sumarDias(hoyReal, -120),
      ),
      Cliente(
        id: 2,
        nombre: 'Carlos Ruiz',
        telefono: '52345678',
        genero: Genero.hombre,
        correo: 'carlos.ruiz@correo.com',
        fechaRegistro: Horario.sumarDias(hoyReal, -95),
      ),
      Cliente(
        id: 3,
        nombre: 'Ana Martín',
        telefono: '53220140',
        genero: Genero.mujer,
        fechaRegistro: Horario.sumarDias(hoyReal, -80),
      ),
      Cliente(
        id: 4,
        nombre: 'Diego Pérez',
        telefono: '55908771',
        genero: Genero.hombre,
        fechaRegistro: Horario.sumarDias(hoyReal, -61),
      ),
      Cliente(
        id: 5,
        nombre: 'Sofía Díaz',
        telefono: '54667310',
        genero: Genero.mujer,
        correo: 'sofia.diaz@correo.com',
        fechaRegistro: Horario.sumarDias(hoyReal, -54),
      ),
      Cliente(
        id: 6,
        nombre: 'Javier Soto',
        telefono: '52774009',
        genero: Genero.hombre,
        fechaRegistro: Horario.sumarDias(hoyReal, -12),
      ),
      Cliente(
        id: 7,
        nombre: 'Marta Peña',
        telefono: '53441902',
        genero: Genero.mujer,
        fechaRegistro: Horario.sumarDias(hoyReal, -40),
      ),
      Cliente(
        id: 8,
        nombre: 'Andrés López',
        telefono: '56123987',
        genero: Genero.hombre,
        correo: 'andres.lopez@correo.com',
        fechaRegistro: Horario.sumarDias(hoyReal, -33),
      ),
      Cliente(
        id: 9,
        nombre: 'Valeria Castro',
        telefono: '58240611',
        genero: Genero.mujer,
        fechaRegistro: Horario.sumarDias(hoyReal, -27),
      ),
      Cliente(
        id: 10,
        nombre: 'Luis Romero',
        telefono: '59031477',
        genero: Genero.hombre,
        fechaRegistro: Horario.sumarDias(hoyReal, -15),
      ),
    ];

    int duracion(List<int> ids) => ids.fold(0, (s, id) => s + _servicios.firstWhere((x) => x.id == id).duracionMin);

    final turnos = <Turno>[];
    int sig = 1;

    /// [estado] null = se decide por la hora (pasado → completado, futuro → programado).
    void t(
      int diaN,
      String hora,
      int cliente,
      int estilista,
      List<int> servicios, {
      String? notas,
      EstadoTurno? estado,
    }) {
      final p = hora.split(':');
      final fecha = dia(diaN);
      final inicio = DateTime(fecha.year, fecha.month, fecha.day, int.parse(p[0]), int.parse(p[1]));
      final fin = inicio.add(Duration(minutes: duracion(servicios)));
      final est = estado ?? (inicio.isAfter(ahora) ? EstadoTurno.programado : EstadoTurno.completado);
      final id = sig++;
      // Creado unos días antes del turno, y nunca en el futuro.
      var creado = DateTime(fecha.year, fecha.month, fecha.day - (3 + id % 4), 9, 15 + id);
      if (creado.isAfter(ahora)) creado = DateTime(hoyReal.year, hoyReal.month, hoyReal.day - 1, 9, 15 + id);
      final retocado = creado.add(const Duration(hours: 26));
      var modificado = (id % 3 == 0 && retocado.isBefore(ahora)) ? retocado : creado;
      if (est != EstadoTurno.programado) {
        final cierre = fin.isBefore(ahora) ? fin : ahora;
        if (cierre.isAfter(modificado)) modificado = cierre;
      }
      turnos.add(
        Turno(
          id: id,
          clienteId: cliente,
          estilistaId: estilista,
          servicioIds: List.unmodifiable(servicios),
          inicio: inicio,
          notas: notas,
          estado: est,
          creado: creado,
          modificado: modificado,
        ),
      );
    }

    // ---- Hace 3 días laborables
    t(-3, '10:00', 1, 1, [6], estado: EstadoTurno.completado, notas: 'Mechas finas, tono miel.');
    t(-3, '11:00', 8, 4, [2], estado: EstadoTurno.completado);
    // ---- Hace 2 días laborables
    t(-2, '09:30', 2, 2, [2], estado: EstadoTurno.completado, notas: 'Degradado bajo.');
    t(-2, '16:00', 10, 4, [8, 9], estado: EstadoTurno.cancelado, notas: 'Canceló por viaje.');
    // ---- Ayer (laborable)
    t(-1, '12:00', 7, 5, [11], estado: EstadoTurno.completado);
    t(-1, '14:00', 5, 3, [1], estado: EstadoTurno.cancelado, notas: 'Reprogramará la próxima semana.');
    // ---- Hoy (6 turnos; Rafael no tiene turnos hoy)
    t(0, '09:00', 1, 1, [1], notas: 'Solo las puntas y flequillo.');
    t(0, '10:00', 2, 2, [
      2,
      8,
    ], notas: 'Prefiere la máquina en el número 2 a los lados. Llega siempre diez minutos antes y pide agua.');
    t(0, '10:30', 3, 1, [5, 11], notas: 'Color castaño claro.');
    t(0, '12:00', 4, 2, [8], estado: EstadoTurno.cancelado, notas: 'Avisó que no puede venir.');
    t(0, '15:00', 5, 3, [4, 12, 13], notas: _notasLargas); // 3 servicios y notas > 300 caracteres
    t(0, '18:00', 9, 5, [10], notas: 'Peinado para boda.'); // termina exactamente a las 19:00
    // ---- Mañana (laborable)
    t(1, '10:00', 4, 4, [2, 8, 9]); // 3 servicios, sin notas
    // ---- Dentro de 2 días laborables
    t(2, '11:00', 3, 3, [4], notas: 'Corte de mantenimiento.');
    t(2, '17:00', 8, 2, [3]);
    // ---- Dentro de 3 días laborables
    t(3, '09:30', 9, 1, [1], notas: 'Quiere un cambio de look.');
    t(3, '13:00', 10, 5, [7]);

    return DatosPrueba._(_servicios, _estilistas, clientes, turnos);
  }
}
