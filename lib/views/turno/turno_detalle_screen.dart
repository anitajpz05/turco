import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../viewmodels/turno_detalle_viewmodel.dart';
import '../../widgets/comunes.dart';

/// RF2 — Detalle de turno (/turno/:id).
class TurnoDetalleScreen extends StatefulWidget {
  const TurnoDetalleScreen({super.key, required this.turnoId});

  final int? turnoId;

  @override
  State<TurnoDetalleScreen> createState() => _TurnoDetalleScreenState();
}

class _TurnoDetalleScreenState extends State<TurnoDetalleScreen> {
  TurnoDetalleViewModel? _vm;
  final ScrollController _notasScroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= TurnoDetalleViewModel(AppScope.of(context).repo, widget.turnoId);
  }

  @override
  void dispose() {
    _vm?.dispose();
    _notasScroll.dispose();
    super.dispose();
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/agenda');
    }
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String get _rango {
    final vm = _vm!;
    return '${Formato.hora(vm.turno!.inicio)} a ${Formato.hora(vm.fin!)}';
  }

  Future<void> _completar() async {
    final vm = _vm!;
    final ok = await confirmar(
      context,
      titulo: '¿Completar este turno?',
      mensaje: 'El turno de ${vm.cliente?.nombre ?? 'este cliente'} ($_rango) quedará como completado.',
      textoConfirmar: 'Completar',
      destructivo: false,
      icono: Icons.check_circle_outline,
    );
    if (ok && mounted) {
      vm.completar();
      _aviso('Turno completado');
    }
  }

  Future<void> _cancelar() async {
    final vm = _vm!;
    final ok = await confirmar(
      context,
      titulo: '¿Cancelar este turno?',
      mensaje:
          'El horario de ${vm.cliente?.nombre ?? 'este cliente'} ($_rango) quedará libre. Esta acción no se puede deshacer.',
      textoConfirmar: 'Cancelar turno',
    );
    if (ok && mounted) {
      vm.cancelar();
      _aviso('Turno cancelado');
    }
  }

  Future<void> _editar() async {
    final t = await context.push<Turno>('/turno/${widget.turnoId}/editar');
    if (t != null && mounted) {
      AppScope.of(context).agenda.seleccionarFecha(t.inicio);
      _aviso('Turno guardado para el ${Formato.fechaCorta(t.inicio)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final turno = vm.turno;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(tooltip: 'Volver', icon: const Icon(Icons.arrow_back), onPressed: _volver),
            title: const Text('Detalle del turno'),
          ),
          body: turno == null ? _noEncontrado(context) : _contenido(context, vm, turno),
          bottomNavigationBar: turno == null ? null : _barraAcciones(context, vm, turno),
        );
      },
    );
  }

  Widget _noEncontrado(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: EstadoVacio(
        imagen: 'assets/images/ilustraciones/no_encontrado.png',
        error: true,
        titulo: 'No encontramos este turno',
        mensaje: 'El turno no existe o ya no está disponible.',
        accion: FilledButton.icon(
          onPressed: _volver,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver a la agenda'),
        ),
      ),
    ),
  );

  Widget _contenido(BuildContext context, TurnoDetalleViewModel vm, Turno turno) {
    final t = context.tokens;
    final cs = context.colores;
    final cliente = vm.cliente;
    final estilo = context.textos;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(t.l, t.xs, t.l, t.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cliente, fecha, hora y estilista
          Card(
            child: Padding(
              padding: EdgeInsets.all(t.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarCliente(
                        inicial: cliente?.inicial ?? '?',
                        genero: cliente?.genero ?? Genero.mujer,
                        size: 48,
                      ),
                      SizedBox(width: t.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente?.nombre ?? 'Cliente eliminado',
                              style: estilo.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 14, color: cs.onSurfaceVariant),
                                SizedBox(width: t.xs),
                                Text(
                                  cliente == null ? '—' : Formato.telefono(cliente.telefono),
                                  style: estilo.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      EstadoBadge(turno.estado),
                    ],
                  ),
                  SizedBox(height: t.m),
                  _Dato(
                    icono: Icons.calendar_today_outlined,
                    etiqueta: 'Fecha',
                    valor: Formato.fechaLarga(turno.inicio),
                  ),
                  SizedBox(height: t.s),
                  _Dato(
                    icono: Icons.schedule,
                    etiqueta: 'Hora',
                    valor:
                        '${Formato.hora(turno.inicio)} a ${Formato.hora(vm.fin!)} (${Formato.duracion(vm.duracion)})',
                  ),
                  SizedBox(height: t.s),
                  _Dato(icono: Icons.person_outline, etiqueta: 'Estilista', valor: vm.estilista?.nombre ?? '—'),
                ],
              ),
            ),
          ),
          SizedBox(height: t.m),
          // Servicios
          Card(
            child: Padding(
              padding: EdgeInsets.all(t.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Servicios', style: estilo.titleSmall),
                  SizedBox(height: t.s),
                  for (final s in vm.servicios) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: t.s),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.nombre, style: estilo.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                Text(
                                  Formato.duracion(s.duracionMin),
                                  style: estilo.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(Formato.precio(s.precio), style: estilo.titleSmall),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                  SizedBox(height: t.s),
                  Row(
                    children: [
                      Expanded(child: Text('Total · ${Formato.duracion(vm.duracion)}', style: estilo.titleSmall)),
                      Text(
                        Formato.precio(vm.total),
                        style: estilo.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: t.m),
          // Notas con scroll propio
          Card(
            child: Padding(
              padding: EdgeInsets.all(t.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Notas', style: estilo.titleSmall),
                  SizedBox(height: t.s),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: Scrollbar(
                      controller: _notasScroll,
                      child: SingleChildScrollView(
                        controller: _notasScroll,
                        child: Text(
                          turno.notas ?? 'Sin notas',
                          style: estilo.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            fontStyle: turno.notas == null ? FontStyle.italic : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: t.m),
          Text(
            'Creado el ${Formato.fechaNumerica(turno.creado)} ${Formato.hora(turno.creado)} · '
            'Modificado el ${Formato.fechaNumerica(turno.modificado)} ${Formato.hora(turno.modificado)}',
            style: estilo.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _barraAcciones(BuildContext context, TurnoDetalleViewModel vm, Turno turno) {
    final t = context.tokens;
    final cs = context.colores;
    if (!vm.editable) {
      return Container(
        color: cs.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: t.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 18, color: cs.onSurfaceVariant),
                SizedBox(width: t.s),
                Flexible(
                  child: Text(
                    'Turno ${turno.estado.etiqueta.toLowerCase()}: solo lectura',
                    style: context.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      color: cs.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(t.m, t.m, t.m, t.m),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const FittedBox(child: Text('Editar')),
                ),
              ),
              SizedBox(width: t.s),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _completar,
                  icon: const Icon(Icons.check, size: 20),
                  label: const FittedBox(child: Text('Completar')),
                ),
              ),
              SizedBox(width: t.s),
              Expanded(
                child: TextButton.icon(
                  onPressed: _cancelar,
                  style: TextButton.styleFrom(foregroundColor: cs.error, minimumSize: Size(64, t.altoBoton)),
                  icon: const Icon(Icons.block, size: 20),
                  label: const FittedBox(child: Text('Cancelar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});
  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(icono, size: 20, color: cs.primary),
        ),
        SizedBox(width: t.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: context.textos.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
              ),
              Text(valor, style: context.textos.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
