import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/salon_repository.dart';

/// Turco — Gestión de turnos de una peluquería mixta.
/// Autora: Ana Maria Pérez Jimenez.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppScope.crear(repo: SalonRepository(), child: const TurcoApp()));
}
