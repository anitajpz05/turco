import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Botón de la barra superior para elegir el modo de tema (Sistema, Claro, Oscuro).
class BotonTema extends StatelessWidget {
  const BotonTema({super.key});

  static const _opciones = [
    (ThemeMode.system, 'Sistema', Icons.smartphone_outlined),
    (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = AppScope.of(context).tema;
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => PopupMenuButton<ThemeMode>(
        tooltip: 'Cambiar tema',
        icon: const Icon(Icons.brightness_6_outlined),
        initialValue: vm.modo,
        onSelected: vm.cambiar,
        itemBuilder: (context) => [
          for (final (modo, texto, icono) in _opciones)
            PopupMenuItem<ThemeMode>(
              value: modo,
              child: Row(
                children: [
                  Icon(icono, size: 22, color: cs.onSurfaceVariant),
                  const SizedBox(width: 16),
                  Expanded(child: Text(texto)),
                  if (vm.modo == modo) Icon(Icons.check, size: 20, color: cs.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
