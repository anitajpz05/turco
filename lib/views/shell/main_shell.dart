import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Contenedor con la barra de navegación inferior (StatefulShellRoute.indexedStack).
/// Cada pestaña conserva su propio estado y su pila de navegación.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _ir(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Atrás del sistema: desde otra pestaña vuelve a la Agenda; desde la Agenda sale de la app.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _ir(0);
      },
      child: Scaffold(
        // Mensajero propio para que los SnackBar de cada pestaña aparezcan sobre su botón flotante.
        body: ScaffoldMessenger(child: navigationShell),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _ir,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_cut_outlined),
              selectedIcon: Icon(Icons.content_cut),
              label: 'Servicios',
            ),
            NavigationDestination(
              icon: Icon(Icons.contact_page_outlined),
              selectedIcon: Icon(Icons.contact_page),
              label: 'Estilistas',
            ),
          ],
        ),
      ),
    );
  }
}
