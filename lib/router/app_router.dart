import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/turno_form_viewmodel.dart';
import '../views/agenda/agenda_screen.dart';
import '../views/clientes/clientes_screen.dart';
import '../views/estilistas/estilistas_screen.dart';
import '../views/servicios/servicios_screen.dart';
import '../views/shell/main_shell.dart';
import '../views/turno/turno_detalle_screen.dart';
import '../views/turno/turno_form_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _agendaKey = GlobalKey<NavigatorState>(debugLabel: 'agenda');
final GlobalKey<NavigatorState> _clientesKey = GlobalKey<NavigatorState>(debugLabel: 'clientes');
final GlobalKey<NavigatorState> _serviciosKey = GlobalKey<NavigatorState>(debugLabel: 'servicios');
final GlobalKey<NavigatorState> _estilistasKey = GlobalKey<NavigatorState>(debugLabel: 'estilistas');

/// Rutas de la app (solo go_router).
///
/// | Ruta               | Pantalla                                    |
/// |--------------------|---------------------------------------------|
/// | /agenda            | Agenda (acepta ?estilista=ID)               |
/// | /clientes          | Clientes                                    |
/// | /servicios         | Servicios                                   |
/// | /estilistas        | Estilistas                                  |
/// | /turno/nuevo       | Formulario (crear) — datos iniciales: extra |
/// | /turno/:id         | Detalle de turno                            |
/// | /turno/:id/editar  | Formulario (editar)                         |
GoRouter crearRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/agenda',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _agendaKey,
          routes: [
            GoRoute(
              path: '/agenda',
              builder: (context, state) => AgendaScreen(
                estilistaId: int.tryParse(state.uri.queryParameters['estilista'] ?? ''),
                marca: state.extra,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _clientesKey,
          routes: [GoRoute(path: '/clientes', builder: (context, state) => const ClientesScreen())],
        ),
        StatefulShellBranch(
          navigatorKey: _serviciosKey,
          routes: [GoRoute(path: '/servicios', builder: (context, state) => const ServiciosScreen())],
        ),
        StatefulShellBranch(
          navigatorKey: _estilistasKey,
          routes: [GoRoute(path: '/estilistas', builder: (context, state) => const EstilistasScreen())],
        ),
      ],
    ),
    // Detalle y formulario se abren por encima de la barra inferior.
    GoRoute(
      path: '/turno/nuevo',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          TurnoFormScreen(args: state.extra is TurnoFormArgs ? state.extra as TurnoFormArgs : null),
    ),
    GoRoute(
      path: '/turno/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => TurnoDetalleScreen(turnoId: int.tryParse(state.pathParameters['id'] ?? '')),
      routes: [
        GoRoute(
          path: 'editar',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => TurnoFormScreen(turnoId: int.tryParse(state.pathParameters['id'] ?? '')),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const TurnoDetalleScreen(turnoId: null),
);
