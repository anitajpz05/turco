import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/salon_repository.dart';
import '../../models/enums.dart';
import '../../models/horario.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../viewmodels/turno_form_viewmodel.dart';
import '../../widgets/campos.dart';
import '../../widgets/comunes.dart';
import '../clientes/cliente_form_sheet.dart';

/// RF3 — Formulario de turno (crear: /turno/nuevo, editar: /turno/:id/editar).
class TurnoFormScreen extends StatefulWidget {
  const TurnoFormScreen({super.key, this.args, this.turnoId});

  /// Datos iniciales enviados con `extra` (cliente, servicio o fecha).
  final TurnoFormArgs? args;

  /// Identificador del turno a editar (parámetro de ruta).
  final int? turnoId;

  bool get esEdicion => turnoId != null;

  @override
  State<TurnoFormScreen> createState() => _TurnoFormScreenState();
}

class _TurnoFormScreenState extends State<TurnoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notas = TextEditingController();
  final _scroll = ScrollController();
  final Map<CampoTurno, FocusNode> _focos = {for (final c in CampoTurno.values) c: FocusNode()};
  AutovalidateMode _auto = AutovalidateMode.disabled;

  TurnoFormViewModel? _vm;
  bool _noEditable = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm != null || _noEditable) return;
    final repo = AppScope.of(context).repo;
    if (widget.esEdicion) {
      final t = repo.turno(widget.turnoId!);
      if (t == null || !t.esProgramado) {
        _noEditable = true;
        return;
      }
      _vm = TurnoFormViewModel(repo, editando: t);
    } else {
      _vm = TurnoFormViewModel(repo, args: widget.args);
    }
    _notas.text = _vm!.notas;
    _vm!.addListener(_alCambiarVm);
  }

  @override
  void dispose() {
    _vm?.removeListener(_alCambiarVm);
    _vm?.dispose();
    _notas.dispose();
    _scroll.dispose();
    for (final f in _focos.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// Muestra los avisos del ViewModel (estilista limpiado, hora ya no disponible…).
  void _alCambiarVm() {
    final aviso = _vm?.consumirAviso();
    if (aviso != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  // ---------------------------------------------------------------- Acciones

  Future<void> _intentarSalir() async {
    final vm = _vm;
    if (vm == null || !vm.hayCambios) {
      context.pop();
      return;
    }
    final descartar = await confirmar(
      context,
      titulo: '¿Descartar los cambios?',
      mensaje: 'Tienes cambios sin guardar en este turno. Si sales ahora se perderán.',
      textoCancelar: 'Seguir editando',
      textoConfirmar: 'Descartar',
    );
    if (descartar && mounted) context.pop();
  }

  void _guardar() {
    final vm = _vm!;
    FocusScope.of(context).unfocus();
    setState(() => _auto = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) {
      final campo = vm.primerCampoConError;
      if (campo != null) _enfocar(campo);
      return;
    }
    final t = vm.guardar();
    if (t == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(vm.errorGuardado ?? 'No se pudo guardar el turno')));
      return;
    }
    context.pop(t); // el resultado viaja de vuelta a la pantalla anterior
  }

  /// Lleva el foco (y el scroll) al primer campo con error.
  void _enfocar(CampoTurno campo) {
    final nodo = _focos[campo]!;
    nodo.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = nodo.context;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.15);
      }
    });
  }

  Future<void> _elegirCliente() async {
    final vm = _vm!;
    final id = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final clientes = vm.clientes;
        final tk = ctx.tokens;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(tk.l + 4, 0, tk.l + 4, tk.s),
                child: Text('Selecciona un cliente', style: ctx.textos.titleLarge),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clientes.length,
                  itemBuilder: (ctx, i) {
                    final c = clientes[i];
                    return ListTile(
                      leading: AvatarCliente(inicial: c.inicial, genero: c.genero, size: 40),
                      title: Text(c.nombre),
                      subtitle: Text('${Formato.telefono(c.telefono)} · ${c.genero.etiqueta}'),
                      trailing: c.id == vm.clienteId ? Icon(Icons.check, color: ctx.colores.primary) : null,
                      onTap: () => ctx.pop(c.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (id != null) vm.elegirCliente(id);
  }

  Future<void> _crearCliente() async {
    final c = await mostrarFormularioCliente(context);
    if (c != null && mounted) {
      _vm!.elegirCliente(c.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Cliente ${c.nombre} registrado')));
    }
  }

  Future<void> _elegirEstilista() async {
    final vm = _vm!;
    final validos = vm.estilistasValidos;
    final id = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (ctx) {
        final tk = ctx.tokens;
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: tk.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(tk.l + 4, 0, tk.l + 4, tk.s),
                child: Text('Selecciona un estilista', style: ctx.textos.titleLarge),
              ),
              if (validos.isEmpty)
                Padding(
                  padding: EdgeInsets.all(tk.l + 4),
                  child: Text(
                    vm.servicioIds.isEmpty
                        ? 'Primero elige los servicios.'
                        : 'Ningún estilista realiza todos los servicios elegidos. Quita algún servicio.',
                    style: ctx.textos.bodyMedium?.copyWith(color: ctx.colores.onSurfaceVariant),
                  ),
                ),
              for (final e in validos)
                ListTile(
                  leading: AvatarEstilista(estilista: e, size: 40),
                  title: Text(e.nombre),
                  trailing: e.id == vm.estilistaId ? Icon(Icons.check, color: ctx.colores.primary) : null,
                  onTap: () => ctx.pop(e.id),
                ),
            ],
          ),
        );
      },
    );
    if (id != null) vm.elegirEstilista(id);
  }

  Future<void> _elegirFecha() async {
    final vm = _vm!;
    final d = await showDatePicker(
      context: context,
      initialDate: vm.fechaInicialPicker,
      firstDate: vm.primeraFechaPermitida,
      lastDate: Horario.sumarDias(vm.primeraFechaPermitida, 365),
      selectableDayPredicate: vm.fechaSeleccionable, // sin domingos ni fechas pasadas
      helpText: 'Fecha del turno',
    );
    if (d != null) vm.elegirFecha(d);
  }

  // ---------------------------------------------------------------- Vista

  @override
  Widget build(BuildContext context) {
    if (_noEditable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar turno')),
        body: Center(
          child: SingleChildScrollView(
            child: EstadoVacio(
              imagen: 'assets/images/ilustraciones/no_encontrado.png',
              error: true,
              titulo: 'No se puede editar este turno',
              mensaje: 'El turno no existe o ya no está programado.',
              accion: FilledButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go('/agenda'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ),
          ),
        ),
      );
    }
    final vm = _vm!;
    return ListenableBuilder(
      listenable: Listenable.merge([vm, _notas]),
      builder: (context, _) => PopScope(
        canPop: !vm.hayCambios,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _intentarSalir();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(tooltip: 'Volver', icon: const Icon(Icons.arrow_back), onPressed: _intentarSalir),
            title: Text(vm.esEdicion ? 'Editar turno' : 'Nuevo turno'),
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: _auto,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(
                      context.tokens.l,
                      context.tokens.xs,
                      context.tokens.l,
                      context.tokens.l,
                    ),
                    child: _campos(context, vm),
                  ),
                ),
                _BarraInferior(vm: vm, onCancelar: _intentarSalir, onGuardar: _guardar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _conError(String? Function() v) => _auto != AutovalidateMode.disabled && v() != null;

  Widget _campos(BuildContext context, TurnoFormViewModel vm) {
    final t = context.tokens;
    final cs = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Cliente
        Etiqueta('Cliente', error: _conError(vm.validarCliente)),
        CampoSelector<int>(
          valor: vm.clienteId,
          texto: vm.cliente?.nombre,
          hint: 'Selecciona un cliente',
          icono: Icons.person_outline,
          validator: vm.validarCliente,
          focusNode: _focos[CampoTurno.cliente]!,
          onTap: _elegirCliente,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _crearCliente,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            label: const Text('Crear cliente nuevo'),
          ),
        ),
        // ---- Servicios para
        const Etiqueta('Servicios para'),
        SegmentedButton<FiltroPublico>(
          segments: [for (final p in FiltroPublico.values) ButtonSegment(value: p, label: Text(p.etiqueta))],
          selected: {vm.publico},
          onSelectionChanged: (s) => vm.elegirPublico(s.first),
        ),
        SizedBox(height: t.m),
        // ---- Servicios (selección múltiple agrupada por categoría)
        Text('Servicios', style: context.textos.titleSmall?.copyWith(fontSize: 16)),
        SizedBox(height: t.xs),
        FormField<List<int>>(
          validator: (_) => vm.validarServicios(),
          builder: (field) => Focus(
            focusNode: _focos[CampoTurno.servicios]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entrada in vm.serviciosPorCategoria.entries) ...[
                  Padding(
                    padding: EdgeInsets.only(top: t.s, bottom: t.xs + 2),
                    child: Text(
                      entrada.key.etiqueta.toUpperCase(),
                      style: context.textos.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: t.s,
                    runSpacing: t.s,
                    children: [
                      for (final s in entrada.value)
                        FilterChip(
                          label: Text(s.nombre),
                          selected: vm.estaElegido(s.id),
                          onSelected: (_) {
                            vm.alternarServicio(s.id);
                            field.didChange(vm.servicioIds);
                          },
                        ),
                    ],
                  ),
                ],
                if (field.hasError) TextoError(field.errorText!),
              ],
            ),
          ),
        ),
        SizedBox(height: t.m),
        // ---- Estilista
        Etiqueta('Estilista', error: _conError(vm.validarEstilista)),
        CampoSelector<int>(
          valor: vm.estilistaId,
          texto: vm.estilista?.nombre,
          hint: vm.servicioIds.isEmpty ? 'Primero elige los servicios' : 'Selecciona un estilista',
          icono: Icons.content_cut,
          validator: vm.validarEstilista,
          focusNode: _focos[CampoTurno.estilista]!,
          onTap: _elegirEstilista,
        ),
        SizedBox(height: t.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
            SizedBox(width: t.s),
            Expanded(
              child: Text(
                'Solo se muestran estilistas que realizan todos los servicios elegidos.',
                style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        SizedBox(height: t.l),
        // ---- Fecha
        Etiqueta('Fecha', error: _conError(vm.validarFecha)),
        CampoSelector<DateTime>(
          valor: vm.fecha,
          texto: vm.fecha == null ? null : Formato.fechaLarga(vm.fecha!),
          hint: 'Selecciona una fecha',
          icono: Icons.calendar_today_outlined,
          validator: vm.validarFecha,
          focusNode: _focos[CampoTurno.fecha]!,
          onTap: _elegirFecha,
        ),
        SizedBox(height: t.l),
        // ---- Hora (cuadrícula de franjas)
        Text('Hora de inicio', style: context.textos.titleSmall?.copyWith(fontSize: 16)),
        SizedBox(height: t.s),
        const _Leyenda(),
        SizedBox(height: t.s + 2),
        FormField<int>(
          validator: (_) => vm.validarHora(),
          builder: (field) {
            final franjas = vm.franjas;
            if (field.value != vm.hora) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (field.mounted) field.didChange(vm.hora);
              });
            }
            return Focus(
              focusNode: _focos[CampoTurno.hora]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.fecha != null && !vm.hayFranjasLibres)
                    Padding(
                      padding: EdgeInsets.only(bottom: t.s),
                      child: Text(
                        'No quedan horas libres para este día con los servicios y el estilista elegidos. '
                        'Prueba con otra fecha u otro estilista.',
                        style: context.textos.bodyMedium?.copyWith(color: cs.error),
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, c) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: franjas.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth >= 600 ? 6 : 4,
                        mainAxisExtent: 40,
                        mainAxisSpacing: t.s,
                        crossAxisSpacing: t.s,
                      ),
                      itemBuilder: (context, i) {
                        final f = franjas[i];
                        return _FranjaBoton(
                          franja: f,
                          elegida: f.minutos == vm.hora,
                          conError: field.hasError,
                          onTap: () {
                            vm.elegirHora(f.minutos);
                            field.didChange(vm.hora);
                          },
                        );
                      },
                    ),
                  ),
                  if (field.hasError) TextoError(field.errorText!),
                ],
              ),
            );
          },
        ),
        SizedBox(height: t.l),
        // ---- Notas
        const Etiqueta('Notas (opcional)'),
        TextFormField(
          controller: _notas,
          focusNode: _focos[CampoTurno.notas]!,
          minLines: 3,
          maxLines: 5,
          maxLength: TurnoFormViewModel.maxNotas,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Indicaciones para el estilista'),
          validator: vm.validarNotas,
          onChanged: vm.cambiarNotas,
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final t = context.tokens;
    Widget item(String texto, BoxDecoration deco) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: deco),
        SizedBox(width: t.xs + 2),
        Text(texto, style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
    final r = BorderRadius.circular(3);
    return Wrap(
      spacing: t.l,
      runSpacing: t.xs,
      children: [
        item(
          'Libre',
          BoxDecoration(
            borderRadius: r,
            border: Border.all(color: cs.outline),
          ),
        ),
        item('No disponible', BoxDecoration(borderRadius: r, color: cs.surfaceContainerHigh)),
        item('Elegida', BoxDecoration(borderRadius: r, color: cs.primary)),
      ],
    );
  }
}

class _FranjaBoton extends StatelessWidget {
  const _FranjaBoton({required this.franja, required this.elegida, required this.conError, required this.onTap});

  final Franja franja;
  final bool elegida;
  final bool conError;
  final VoidCallback onTap;

  String get _motivo => switch (franja.motivo) {
    MotivoFranja.libre => 'Libre',
    MotivoFranja.ocupadaEstilista => 'Ocupada por el estilista',
    MotivoFranja.ocupadaCliente => 'El cliente ya tiene un turno',
    MotivoFranja.pasada => 'Hora pasada',
    MotivoFranja.excedeCierre => 'Terminaría después de las 19:00',
  };

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final t = context.tokens;
    final disponible = franja.disponible;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.radioFranja),
      side: elegida || !disponible
          ? BorderSide.none
          : BorderSide(color: conError ? cs.error : cs.outline, width: conError ? 1.5 : 1),
    );
    return Tooltip(
      message: _motivo,
      child: Material(
        color: elegida ? cs.primary : (disponible ? cs.surface : cs.surfaceContainerHigh),
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disponible ? onTap : null,
          child: Center(
            child: Text(
              Formato.horaMin(franja.minutos),
              style: context.textos.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: elegida ? cs.onPrimary : (disponible ? cs.onSurface : cs.outline.withAlpha(150)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.vm, required this.onCancelar, required this.onGuardar});

  final TurnoFormViewModel vm;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final t = context.tokens;
    // Con el teclado abierto solo se deja el resumen (siempre visible) para evitar overflow.
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fin = vm.finMinutos;
    final estilo = context.textos.labelLarge?.copyWith(color: cs.onPrimaryContainer);
    Widget dato(IconData i, String s) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 18, color: cs.onPrimaryContainer),
        SizedBox(width: t.xs + 2),
        Text(s, style: estilo),
      ],
    );
    return Material(
      color: cs.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(t.l, t.m, t.l, t.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: t.m, vertical: t.s),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(t.radioCampo),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: FittedBox(child: dato(Icons.schedule, Formato.duracion(vm.duracion)))),
                    Flexible(
                      child: FittedBox(
                        child: dato(Icons.flag_outlined, 'Fin ${fin == null ? '--:--' : Formato.horaMin(fin)}'),
                      ),
                    ),
                    Flexible(child: FittedBox(child: dato(Icons.paid_outlined, Formato.precio(vm.precio)))),
                  ],
                ),
              ),
              if (!teclado) ...[
                SizedBox(height: t.m),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: onCancelar, child: const Text('Cancelar')),
                    ),
                    SizedBox(width: t.s + 2),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onGuardar,
                        icon: const Icon(Icons.check, size: 20),
                        label: const FittedBox(child: Text('Guardar turno')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
