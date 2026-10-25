import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class TurcoApp extends StatefulWidget {
  const TurcoApp({super.key});

  @override
  State<TurcoApp> createState() => _TurcoAppState();
}

class _TurcoAppState extends State<TurcoApp> {
  late final GoRouter _router = crearRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = AppScope.of(context).tema;
    return ListenableBuilder(
      listenable: tema,
      builder: (context, _) => MaterialApp.router(
        title: 'Turco',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        darkTheme: AppTheme.oscuro,
        themeMode: tema.modo,
        routerConfig: _router,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
