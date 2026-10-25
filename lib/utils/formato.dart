/// Utilidades de formato en español (sin dependencias externas).
class Formato {
  Formato._();

  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _diasAbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// "Octubre 2026"
  static String mesAnio(DateTime d) => '${_cap(_meses[d.month - 1])} ${d.year}';

  /// "Lun"
  static String diaAbrev(DateTime d) => _diasAbrev[d.weekday - 1];

  /// "Miércoles 21 de octubre de 2026"
  static String fechaLarga(DateTime d) => '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';

  /// "mié 21 de octubre"
  static String fechaCorta(DateTime d) =>
      '${_diasAbrev[d.weekday - 1].toLowerCase()} ${d.day} de ${_meses[d.month - 1]}';

  /// "19/10"
  static String diaMes(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

  /// "15/10/2026"
  static String fechaNumerica(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

  /// "09:00"
  static String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

  /// 570 → "09:30"
  static String horaMin(int minutos) => '${_dos(minutos ~/ 60)}:${_dos(minutos % 60)}';

  /// 90 → "1 h 30 min"
  static String duracion(int minutos) {
    final h = minutos ~/ 60, m = minutos % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  /// 45 → "$ 45"; 12.5 → "$ 12.50"
  static String precio(double v) => v == v.roundToDouble() ? '\$ ${v.toInt()}' : '\$ ${v.toStringAsFixed(2)}';

  /// "52345678" → "52 345 678"
  static String telefono(String t) => t.length == 8 ? '${t.substring(0, 2)} ${t.substring(2, 5)} ${t.substring(5)}' : t;

  /// "1 turno" / "3 turnos"
  static String turnos(int n) => n == 1 ? '1 turno' : '$n turnos';
}

/// Normaliza texto para búsquedas: minúsculas y sin acentos.
String normalizar(String s) {
  const con = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const sin = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = con.indexOf(ch);
    b.write(i >= 0 ? sin[i] : ch);
  }
  return b.toString();
}
