import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../data/salon_repository.dart';
import '../../models/cliente.dart';
import '../../models/enums.dart';
import '../../models/turno.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../viewmodels/clientes_viewmodel.dart';
import '../../viewmodels/turno_form_viewmodel.dart';
import '../../widgets/comunes.dart';
import 'cliente_form_sheet.dart';

enum _AccionCliente { nuevoTurno, editar, eliminar, verTurno }

/// RF4 — Pantalla Clientes.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  TextEditingController? _busquedaCtrl;
  TextEditingController get _busqueda => _busquedaCtrl!;
  final ScrollController _scroll = ScrollController();

  ClientesViewModel get _vm => AppScope.of(context).clientes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _busquedaCtrl ??= TextEditingController(text: _vm.busqueda);
  }

  @override
  void dispose() {
    _busquedaCtrl?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _aviso(String texto, {SnackBarAction? accion}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), action: accion));
  }

  Future<void> _nuevoCliente() async {
    final c = await mostrarFormularioCliente(context);
    if (c != null) _aviso('Cliente ${c.nombre} registrado');
  }

  Future<void> _abrirDetalle(Cliente c) async {
    final vm = _vm;
    final resultado = await showModalBottomSheet<(_AccionCliente, int?)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DetalleClienteSheet(vm: vm, clienteId: c.id),
    );
    if (!mounted || resultado == null) return;
    final (accion, turnoId) = resultado;
    switch (accion) {
      case _AccionCliente.verTurno:
        if (turnoId != null) context.push('/turno/$turnoId');
      case _AccionCliente.nuevoTurno:
        final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(clienteId: c.id));
        if (t != null && mounted) {
          AppScope.of(context).agenda.seleccionarFecha(t.inicio);
          _aviso(
            'Turno guardado para el ${Formato.fechaCorta(t.inicio)}',
            accion: SnackBarAction(label: 'Ver', onPressed: () => context.push('/turno/${t.id}')),
          );
        }
      case _AccionCliente.editar:
        final actual = vm.cliente(c.id);
        if (actual == null) return;
        final editado = await mostrarFormularioCliente(context, editando: actual);
        if (editado != null) _aviso('Cliente ${editado.nombre} actualizado');
      case _AccionCliente.eliminar:
        await _eliminar(c);
    }
  }

  Future<void> _eliminar(Cliente c) async {
    final vm = _vm;
    final programados = vm.programadosDe(c.id);
    if (programados > 0) {
      final proximo = vm.proximoProgramado(c.id);
      _aviso(
        'No se puede eliminar: ${c.nombre} tiene '
        '${programados == 1 ? '1 turno programado' : '$programados turnos programados'}.',
        accion: proximo == null
            ? null
            : SnackBarAction(label: 'Ver', onPressed: () => context.push('/turno/${proximo.id}')),
      );
      return;
    }
    final ok = await confirmar(
      context,
      titulo: '¿Eliminar a ${c.nombre}?',
      mensaje: 'Se eliminará el cliente junto con su historial de turnos completados y cancelados.',
      textoCancelar: 'Cancelar',
      textoConfirmar: 'Eliminar',
    );
    if (!ok || !mounted) return;
    final r = vm.eliminar(c.id);
    switch (r) {
      case ResultadoEliminar.eliminado:
        _aviso('Cliente ${c.nombre} eliminado');
      case ResultadoEliminar.tieneProgramados:
        _aviso('No se puede eliminar: ${c.nombre} tiene turnos programados.');
      case ResultadoEliminar.noExiste:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    final t = context.tokens;
    final cs = context.colores;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Nuevo cliente',
            onPressed: _nuevoCliente,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          SizedBox(width: t.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoCliente,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nuevo cliente'),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final clientes = vm.clientes;
          return CustomScrollView(
            key: const PageStorageKey('clientes-lista'),
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(t.l, t.xs, t.l, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _busqueda,
                        onChanged: vm.buscar,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: vm.busqueda.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _busqueda.clear();
                                    vm.buscar('');
                                  },
                                ),
                          filled: true,
                          fillColor: cs.surfaceContainerHigh,
                          contentPadding: EdgeInsets.symmetric(horizontal: t.l, vertical: t.m),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: t.m),
                      SegmentedButton<FiltroGenero>(
                        segments: [
                          for (final f in FiltroGenero.values) ButtonSegment(value: f, label: Text(f.etiqueta)),
                        ],
                        selected: {vm.filtro},
                        onSelectionChanged: (s) => vm.filtrar(s.first),
                      ),
                      SizedBox(height: t.m),
                      Text(
                        '${vm.total} clientes · ${vm.mujeres} mujeres · ${vm.hombres} hombres',
                        style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      SizedBox(height: t.xs),
                    ],
                  ),
                ),
              ),
              if (clientes.isEmpty)
                SliverToBoxAdapter(
                  child: EstadoVacio(
                    imagen: vm.sinClientes
                        ? 'assets/images/ilustraciones/sin_clientes.png'
                        : 'assets/images/ilustraciones/sin_resultados.png',
                    titulo: vm.sinClientes ? 'Aún no hay clientes' : 'Sin resultados',
                    mensaje: vm.sinClientes
                        ? 'Registra el primer cliente con el botón de abajo.'
                        : 'Ningún cliente coincide con la búsqueda o el filtro.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(t.l, 0, t.l, 96),
                  sliver: SliverToBoxAdapter(
                    // Lista de clientes con ListView.separated (dentro del scroll principal).
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: clientes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final c = clientes[i];
                        return _FilaCliente(cliente: c, turnos: vm.turnosDe(c.id), onTap: () => _abrirDetalle(c));
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({required this.cliente, required this.turnos, required this.onTap});

  final Cliente cliente;
  final int turnos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.s + 2),
        child: Row(
          children: [
            AvatarCliente(inicial: cliente.inicial, genero: cliente.genero),
            SizedBox(width: t.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textos.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${Formato.telefono(cliente.telefono)} · ${cliente.genero.etiqueta}',
                    style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: t.s),
            Text(Formato.turnos(turnos), style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Hoja con los datos del cliente, su historial y las acciones.
class _DetalleClienteSheet extends StatelessWidget {
  const _DetalleClienteSheet({required this.vm, required this.clienteId});

  final ClientesViewModel vm;
  final int clienteId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final c = vm.cliente(clienteId);
        if (c == null) return const SizedBox(height: 120);
        final historial = vm.historialDe(c.id);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(t.l + 4, 0, t.l + 4, t.l + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarCliente(inicial: c.inicial, genero: c.genero, size: 56),
                    SizedBox(width: t.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nombre, style: context.textos.titleLarge?.copyWith(fontSize: 20)),
                          _Linea(icono: Icons.phone_outlined, texto: Formato.telefono(c.telefono)),
                          if (c.correo != null) _Linea(icono: Icons.mail_outline, texto: c.correo!),
                          _Linea(
                            icono: Icons.event_available_outlined,
                            texto: 'Cliente desde el ${Formato.fechaNumerica(c.fechaRegistro)} · ${c.genero.etiqueta}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.l),
                Text('Historial de turnos · ${historial.length}', style: context.textos.titleSmall),
                SizedBox(height: t.s),
                if (historial.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: t.s),
                    child: Text(
                      'Este cliente aún no tiene turnos.',
                      style: context.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                for (final turno in historial)
                  InkWell(
                    onTap: () => context.pop((_AccionCliente.verTurno, turno.id)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: t.s),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${Formato.diaMes(turno.inicio)} · ${vm.serviciosDe(turno)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textos.bodyMedium,
                            ),
                          ),
                          SizedBox(width: t.s),
                          EstadoBadge(turno.estado),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: t.l),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FilledButton.icon(
                        onPressed: () => context.pop((_AccionCliente.nuevoTurno, null)),
                        icon: const Icon(Icons.add),
                        label: const FittedBox(child: Text('Nuevo turno')),
                      ),
                    ),
                    SizedBox(width: t.s),
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop((_AccionCliente.editar, null)),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const FittedBox(child: Text('Editar')),
                      ),
                    ),
                    SizedBox(width: t.s),
                    IconButton.outlined(
                      tooltip: 'Eliminar',
                      onPressed: () => context.pop((_AccionCliente.eliminar, null)),
                      color: cs.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icono, size: 15, color: cs.onSurfaceVariant),
          SizedBox(width: context.tokens.xs + 2),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
