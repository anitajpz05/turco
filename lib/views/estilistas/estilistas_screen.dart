import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/estilista.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/estilistas_viewmodel.dart';
import '../../widgets/comunes.dart';

/// RF6 — Estilistas con CustomScrollView + SliverAppBar plegable + SliverList.
class EstilistasScreen extends StatefulWidget {
  const EstilistasScreen({super.key});

  @override
  State<EstilistasScreen> createState() => _EstilistasScreenState();
}

class _EstilistasScreenState extends State<EstilistasScreen> {
  final ScrollController _scroll = ScrollController();
  static const double _alturaExpandida = 172;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = AppScope.of(context).estilistas;
    final t = context.tokens;
    final cs = context.colores;
    return Scaffold(
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final estilistas = vm.estilistas;
          final resumen = '${estilistas.length} profesionales · ${vm.totalProgramadosHoy} turnos programados hoy';
          return CustomScrollView(
            key: const PageStorageKey('estilistas-lista'),
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _alturaExpandida,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                surfaceTintColor: cs.primary,
                flexibleSpace: LayoutBuilder(
                  builder: (context, c) {
                    final top = MediaQuery.paddingOf(context).top;
                    final minimo = kToolbarHeight + top;
                    final progreso = ((c.maxHeight - minimo) / (_alturaExpandida + top - minimo)).clamp(0.0, 1.0);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Título compacto (barra plegada)
                        Positioned(
                          left: t.l,
                          right: t.l,
                          top: top,
                          height: kToolbarHeight,
                          child: Opacity(
                            opacity: 1 - progreso,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Estilistas',
                                style: context.textos.titleLarge?.copyWith(color: cs.onPrimary),
                              ),
                            ),
                          ),
                        ),
                        // Cabecera expandida
                        Positioned(
                          left: t.l + 4,
                          right: t.l + 4,
                          bottom: t.l + 4,
                          child: Opacity(
                            opacity: progreso,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.contact_page_outlined, color: cs.onPrimary, size: 28),
                                SizedBox(height: t.s),
                                Text('Estilistas', style: context.textos.headlineMedium?.copyWith(color: cs.onPrimary)),
                                SizedBox(height: t.xs),
                                Text(
                                  resumen,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textos.bodyMedium?.copyWith(color: cs.onPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(t.l, t.l, t.l, t.l),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final e = estilistas[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: t.m),
                      child: _TarjetaEstilista(
                        estilista: e,
                        vm: vm,
                        // El identificador viaja como parámetro de consulta.
                        onTap: () =>
                            context.go('/agenda?estilista=${e.id}', extra: DateTime.now().microsecondsSinceEpoch),
                      ),
                    );
                  }, childCount: estilistas.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaEstilista extends StatelessWidget {
  const _TarjetaEstilista({required this.estilista, required this.vm, required this.onTap});

  final Estilista estilista;
  final EstilistasViewModel vm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    final hoy = vm.programadosHoy(estilista.id);
    final grupos = vm.serviciosPorCategoria(estilista);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(t.l - 2),
          child: Row(
            children: [
              AvatarEstilista(estilista: estilista),
              SizedBox(width: t.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estilista.nombre, style: context.textos.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: t.s),
                    // Servicios agrupados por categoría
                    Wrap(
                      spacing: t.s,
                      runSpacing: t.s,
                      children: [
                        for (final g in grupos.entries)
                          Tooltip(
                            message: g.value.join(', '),
                            child: Container(
                              height: 32,
                              padding: EdgeInsets.symmetric(horizontal: t.m),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(t.radioChip),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Text(
                                g.key.etiqueta,
                                style: context.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: t.s),
                    Text(
                      hoy == 0 ? 'Sin turnos hoy' : (hoy == 1 ? '1 turno hoy' : '$hoy turnos hoy'),
                      style: context.textos.bodySmall?.copyWith(
                        color: hoy == 0 ? cs.onSurfaceVariant : cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
