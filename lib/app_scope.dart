import 'package:flutter/widgets.dart';

import 'data/salon_repository.dart';
import 'viewmodels/agenda_viewmodel.dart';
import 'viewmodels/clientes_viewmodel.dart';
import 'viewmodels/estilistas_viewmodel.dart';
import 'viewmodels/servicios_viewmodel.dart';
import 'viewmodels/tema_viewmodel.dart';

/// Inyección de dependencias sin paquetes externos: un [InheritedWidget]
/// que expone el modelo y los ViewModels de las pestañas.
///
/// Los ViewModels de pestaña viven mientras vive la app, por eso cada destino
/// conserva sus filtros, búsqueda y fecha al cambiar de pestaña.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repo,
    required this.tema,
    required this.agenda,
    required this.clientes,
    required this.servicios,
    required this.estilistas,
    required super.child,
  });

  factory AppScope.crear({required SalonRepository repo, required Widget child}) => AppScope(
    repo: repo,
    tema: TemaViewModel(),
    agenda: AgendaViewModel(repo),
    clientes: ClientesViewModel(repo),
    servicios: ServiciosViewModel(repo),
    estilistas: EstilistasViewModel(repo),
    child: child,
  );

  final SalonRepository repo;
  final TemaViewModel tema;
  final AgendaViewModel agenda;
  final ClientesViewModel clientes;
  final ServiciosViewModel servicios;
  final EstilistasViewModel estilistas;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
