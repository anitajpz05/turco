/// Reglas de horario del salón: lunes a sábado de 9:00 a 19:00,
/// franjas de inicio cada 30 minutos. Domingo cerrado.
class Horario {
  Horario._();

  static const int aperturaMin = 9 * 60;
  static const int cierreMin = 19 * 60;
  static const int pasoMin = 30;

  /// Minutos desde medianoche de todas las franjas de inicio posibles (09:00 … 18:30).
  static List<int> get franjas => [for (int m = aperturaMin; m < cierreMin; m += pasoMin) m];

  static bool esDomingo(DateTime d) => d.weekday == DateTime.sunday;

  static DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime enMinutos(DateTime fecha, int minutos) =>
      DateTime(fecha.year, fecha.month, fecha.day, minutos ~/ 60, minutos % 60);

  static int minutosDe(DateTime d) => d.hour * 60 + d.minute;

  /// Lunes de la semana que contiene [d].
  static DateTime lunesDe(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  /// Suma días de calendario sin depender de Duration (evita saltos por horario de verano).
  static DateTime sumarDias(DateTime d, int dias) => DateTime(d.year, d.month, d.day + dias);

  /// Dos intervalos [a1,a2) y [b1,b2) se solapan si a1 < b2 y b1 < a2.
  /// Un turno que termina a las 10:00 no se solapa con otro que empieza a las 10:00.
  static bool seSolapan(DateTime a1, DateTime a2, DateTime b1, DateTime b2) => a1.isBefore(b2) && b1.isBefore(a2);
}
