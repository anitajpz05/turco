import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../viewmodels/agenda_viewmodel.dart';
import '../../viewmodels/turno_form_viewmodel.dart';
import '../../widgets/boton_tema.dart';
import '../../widgets/comunes.dart';
import 'turno_card.dart';

enum _AccionRapida { completar, cancelar }

/// RF1 — Pantalla Agenda (inicial).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.estilistaId, this.marca});

  /// Filtro recibido como parámetro de consulta (/agenda?estilista=3).
  final int? estilistaId;

  /// Marca de cada navegación desde Estilistas, para reaplicar el filtro aunque el id se repita.
  final Object? marca;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final ScrollController _scroll = ScrollController();

  AgendaViewModel get _vm => AppScope.of(context).agenda;

  @override
  void initState() {
    super.initState();
    _aplicarParametro(widget.estilistaId);
  }

  @override
  void didUpdateWidget(covariant AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estilistaId != oldWidget.estilistaId || widget.marca != oldWidget.marca) {
      _aplicarParametro(widget.estilistaId);
    }
  }

  void _aplicarParametro(int? id) {
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vm.aplicarEstilistaDesdeRuta(id);
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _vm.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Elegir fecha',
    );
    if (d != null) _vm.seleccionarFecha(d);
  }

  Future<void> _nuevoTurno() async {
    final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(fecha: _vm.fecha));
    if (t == null || !mounted) return;
    _vm.seleccionarFecha(t.inicio);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Turno guardado para el ${Formato.fechaCorta(t.inicio)}'),
          action: SnackBarAction(label: 'Ver', onPressed: () => context.push('/turno/${t.id}')),
        ),
      );
  }

  Future<void> _accionesRapidas(Turno t) async {
    final vm = _vm;
    final accion = await showModalBottomSheet<_AccionRapida>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tk = ctx.tokens;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(tk.l + 4, 0, tk.l + 4, tk.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vm.clienteDe(t)} · ${Formato.hora(t.inicio)}',
                  style: ctx.textos.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: tk.xs),
                Text(
                  '${vm.serviciosDe(t)} · ${vm.estilistaDe(t)}',
                  style: ctx.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                SizedBox(height: tk.s),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Marcar como completado'),
                  onTap: () => ctx.pop(_AccionRapida.completar),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  iconColor: cs.error,
                  textColor: cs.error,
                  leading: const Icon(Icons.block),
                  title: const Text('Cancelar turno'),
                  onTap: () => ctx.pop(_AccionRapida.cancelar),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (accion == null || !mounted) return;
    final rango = '${Formato.hora(t.inicio)} a ${Formato.hora(vm.finDe(t))}';
    final cliente = vm.clienteDe(t);
    if (accion == _AccionRapida.completar) {
      final ok = await confirmar(
        context,
        titulo: '¿Completar este turno?',
        mensaje: 'El turno de $cliente ($rango) quedará como completado.',
        textoConfirmar: 'Completar',
        destructivo: false,
        icono: Icons.check_circle_outline,
      );
      if (ok) {
        vm.completar(t.id);
        _aviso('Turno de $cliente completado');
      }
    } else {
      final ok = await confirmar(
        context,
        titulo: '¿Cancelar este turno?',
        mensaje: 'El horario de $cliente ($rango) quedará libre. Esta acción no se puede deshacer.',
        textoConfirmar: 'Cancelar turno',
      );
      if (ok) {
        vm.cancelar(t.id);
        _aviso('Turno de $cliente cancelado');
      }
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const LogoTurco(),
            SizedBox(width: t.m),
            Text('Turco', style: context.textos.titleLarge),
          ],
        ),
        actions: [
          const BotonTema(),
          SizedBox(width: t.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoTurno,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo turno'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final turnos = vm.turnos;
          return ListView.builder(
            key: const PageStorageKey('agenda-lista'),
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(t.l, t.xs, t.l, 96),
            itemCount: 1 + (turnos.isEmpty ? 1 : turnos.length),
            itemBuilder: (context, i) {
              if (i == 0) return _Cabecera(vm: vm, onElegirFecha: _elegirFecha);
              if (turnos.isEmpty) {
                return EstadoVacio(
                  imagen: 'assets/images/ilustraciones/agenda_vacia.png',
                  titulo: vm.diaCerrado
                      ? 'El salón está cerrado'
                      : (vm.diaSinTurnos ? 'No hay turnos para este día' : 'Sin resultados'),
                  mensaje: vm.diaCerrado
                      ? 'Los domingos no se atienden turnos. Elige otro día.'
                      : (vm.diaSinTurnos
                            ? 'Crea el primer turno con el botón de abajo o cambia los filtros.'
                            : 'Ningún turno coincide con los filtros elegidos.'),
                );
              }
              final turno = turnos[i - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: t.s + 2),
                child: TurnoCard(
                  inicio: turno.inicio,
                  fin: vm.finDe(turno),
                  cliente: vm.clienteDe(turno),
                  servicios: vm.serviciosDe(turno),
                  estilista: vm.estilistaDe(turno),
                  estado: turno.estado,
                  onTap: () => context.push('/turno/${turno.id}'),
                  onLongPress: turno.estado == EstadoTurno.programado ? () => _accionesRapidas(turno) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Mes, tira de días, resumen y filtros.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.vm, required this.onElegirFecha});

  final AgendaViewModel vm;
  final VoidCallback onElegirFecha;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    final semana = vm.semana;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mes y navegación por semanas
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              onPressed: vm.semanaAnterior,
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
            ),
            Flexible(
              child: Text(
                Formato.mesAnio(vm.fecha),
                overflow: TextOverflow.ellipsis,
                style: context.textos.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              onPressed: vm.semanaSiguiente,
              icon: const Icon(Icons.chevron_right),
              visualDensity: VisualDensity.compact,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onElegirFecha,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              label: const Text('Elegir fecha'),
            ),
          ],
        ),
        SizedBox(height: t.xs),
        // Tira de días (ListView.builder horizontal)
        SizedBox(
          height: 62,
          child: LayoutBuilder(
            builder: (context, c) => ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: semana.length,
              itemExtent: c.maxWidth / 7,
              itemBuilder: (context, i) {
                final d = semana[i];
                final sel = d.year == vm.fecha.year && d.month == vm.fecha.month && d.day == vm.fecha.day;
                final cerrado = vm.esCerrado(d);
                final colorTexto = sel ? cs.onPrimary : (cerrado ? cs.outline : cs.onSurface);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    type: sel ? MaterialType.canvas : MaterialType.transparency,
                    color: sel ? cs.primary : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => vm.seleccionarFecha(d),
                      child: Opacity(
                        opacity: cerrado && !sel ? 0.75 : 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              Formato.diaAbrev(d),
                              style: context.textos.labelSmall?.copyWith(
                                color: sel ? cs.onPrimary : (cerrado ? cs.outline : cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.day}',
                              style: context.textos.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorTexto,
                                decoration: vm.esHoy(d) && !sel ? TextDecoration.underline : null,
                                decorationColor: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: t.s),
        Text(
          vm.diaCerrado ? 'Domingo: salón cerrado · no se atienden turnos' : 'Domingo: salón cerrado',
          style: context.textos.labelSmall?.copyWith(
            fontWeight: FontWeight.w400,
            color: vm.diaCerrado ? cs.error : cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.m),
        // Resumen del día (en un día sin turnos se muestra solo el mensaje vacío, como en el diseño)
        if (!vm.diaSinTurnos) ...[
          Row(
            children: [
              Expanded(
                child: _Resumen(valor: '${vm.programados}', etiqueta: 'Programados', color: cs.primary),
              ),
              SizedBox(width: t.s),
              Expanded(
                child: _Resumen(valor: '${vm.completados}', etiqueta: 'Completados', color: cs.tertiary),
              ),
              SizedBox(width: t.s),
              Expanded(
                child: _Resumen(
                  valor: Formato.precio(vm.ingresoEstimado),
                  etiqueta: 'Ingreso est.',
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: t.m),
        ],
        // Filtro por estilista
        FilaChips<int?>(
          opciones: [null, ...vm.estilistas.map((e) => e.id)],
          seleccion: vm.estilistaId,
          etiqueta: (id) => id == null ? 'Todos' : vm.estilistas.firstWhere((e) => e.id == id).nombreCorto,
          onSelected: vm.filtrarEstilista,
        ),
        SizedBox(height: t.s + 2),
        // Filtro por estado
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<FiltroEstado>(
            segments: [
              for (final f in FiltroEstado.values)
                ButtonSegment(
                  value: f,
                  label: Text(f.etiqueta, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                ),
            ],
            selected: {vm.filtroEstado},
            showSelectedIcon: true,
            onSelectionChanged: (s) => vm.filtrarEstado(s.first),
          ),
        ),
        SizedBox(height: t.m),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.valor, required this.etiqueta, required this.color});
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.m, vertical: t.s + 2),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(t.radioResumen)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: context.textos.titleLarge?.copyWith(fontSize: 20, color: color)),
          ),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textos.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
