import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/enums.dart';
import '../../models/servicio.dart';
import '../../models/turno.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../viewmodels/servicios_viewmodel.dart';
import '../../viewmodels/turno_form_viewmodel.dart';
import '../../widgets/comunes.dart';

/// RF5 — Catálogo de servicios en cuadrícula.
class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Abre el formulario con el servicio ya seleccionado (el dato viaja con `extra`).
  Future<void> _reservar(Servicio s) async {
    final t = await context.push<Turno>('/turno/nuevo', extra: TurnoFormArgs(servicioId: s.id));
    if (t == null || !mounted) return;
    AppScope.of(context).agenda.seleccionarFecha(t.inicio);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Turno guardado para el ${Formato.fechaCorta(t.inicio)}'),
          action: SnackBarAction(label: 'Ver', onPressed: () => context.push('/turno/${t.id}')),
        ),
      );
  }

  /// 2 columnas en menos de 600 dp, 3 entre 600 y 840 dp y 4 en más de 840 dp.
  static int columnasPara(double ancho) => ancho < 600 ? 2 : (ancho <= 840 ? 3 : 4);

  @override
  Widget build(BuildContext context) {
    final ServiciosViewModel vm = AppScope.of(context).servicios;
    final t = context.tokens;
    final cs = context.colores;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Servicios'),
            Text(
              'Toca un servicio para reservar',
              style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final servicios = vm.servicios;
          return CustomScrollView(
            key: const PageStorageKey('servicios-grid'),
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(t.l, 0, t.l, t.m),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilaChips<Categoria?>(
                        opciones: const [null, ...Categoria.values],
                        seleccion: vm.categoria,
                        etiqueta: (c) => c == null ? 'Todas' : c.etiqueta,
                        onSelected: vm.filtrarCategoria,
                      ),
                      SizedBox(height: t.s + 2),
                      SegmentedButton<FiltroPublico>(
                        segments: [
                          for (final p in FiltroPublico.values) ButtonSegment(value: p, label: Text(p.etiqueta)),
                        ],
                        selected: {vm.publico},
                        onSelectionChanged: (s) => vm.filtrarPublico(s.first),
                      ),
                    ],
                  ),
                ),
              ),
              if (servicios.isEmpty)
                SliverToBoxAdapter(
                  child: EstadoVacio(
                    imagen: 'assets/images/ilustraciones/sin_resultados.png',
                    titulo: 'Sin servicios',
                    mensaje: 'Ningún servicio coincide con los filtros elegidos.',
                    accion: OutlinedButton(onPressed: vm.limpiarFiltros, child: const Text('Quitar filtros')),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(t.l, 0, t.l, t.l),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final columnas = columnasPara(c.maxWidth);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: servicios.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnas,
                            mainAxisSpacing: t.m,
                            crossAxisSpacing: t.m,
                            mainAxisExtent: 186,
                          ),
                          itemBuilder: (context, i) =>
                              _TarjetaServicio(servicio: servicios[i], onTap: () => _reservar(servicios[i])),
                        );
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

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio, required this.onTap});

  final Servicio servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(t.s + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(t.radioCampo),
                  ),
                  alignment: Alignment.center,
                  child: ImagenTema(
                    servicio.categoria.imagen,
                    color: Theme.of(context).brightness == Brightness.dark ? cs.primary : cs.onPrimaryContainer,
                    size: 38,
                  ),
                ),
              ),
              SizedBox(height: t.s),
              Text(
                servicio.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textos.titleSmall?.copyWith(fontSize: 15),
              ),
              SizedBox(height: t.xs),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                  SizedBox(width: t.xs),
                  Expanded(
                    child: Text(
                      Formato.duracion(servicio.duracionMin),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    Formato.precio(servicio.precio),
                    style: context.textos.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: t.s),
              Container(
                padding: EdgeInsets.symmetric(horizontal: t.s, vertical: t.xs),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(t.radioChip),
                ),
                child: Text(
                  servicio.publico.etiqueta,
                  style: context.textos.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
