# Turco — Gestión de turnos de una peluquería

Primer Examen Parcial · Programación para Dispositivos Móviles · Ingeniería Informática, 3er año

**Estudiante:** Ana Maria Jimenez Pérez
**Application id:** `com.anamariaperez.turco`
**Nombre visible:** Turco

Aplicación Flutter para Android que usa la recepción del salón para registrar clientes, programar turnos con un estilista y llevar la agenda diaria. Todos los datos viven en memoria y se cargan desde datos de prueba al iniciar (sin servidor, base de datos ni almacenamiento local).

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.29 o superior (canal stable) |
| Dart | 3.7 o superior (incluido con Flutter) |
| Android Studio | con los plugins *Flutter* y *Dart* |
| JDK | 17 (el que trae Android Studio) |

Paquetes usados: `go_router` (navegación) y `flutter_localizations` (del SDK, para el selector de fecha en español). No se usan manejadores de estado externos ni paquetes de almacenamiento.

## Inicializar y ejecutar

```bash
flutter pub get          # descarga dependencias y genera android/local.properties
flutter run              # ejecuta en el emulador o teléfono conectado
```

Desde Android Studio: **File → Open…** y elegir la carpeta del proyecto; esperar a que termine `pub get`, elegir el dispositivo y pulsar **Run ▶**.

Si al abrir el proyecto en otro equipo falta algún archivo generado de la plataforma Android, se regenera sin tocar el código con:

```bash
flutter create --org com.anamariaperez --project-name turco --platforms android .
```

## Generar el APK release

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Copiarlo a `entrega/` y publicarlo en **Releases** de GitHub (la carpeta `build/` no se sube).

## Pruebas

```bash
flutter test             # verifica datos de prueba y reglas de negocio (solapes, 19:00, cancelación, bajas)
```

## Arquitectura (MVVM con ChangeNotifier)

- **Modelo** (`lib/models`, `lib/data`): entidades `Servicio`, `Estilista`, `Cliente`, `Turno` y `SalonRepository`, que guarda los datos en memoria y aplica todas las reglas de negocio (horario 9:00–19:00 de lunes a sábado, franjas de 30 min, solapes por estilista y por cliente, turnos pasados, baja de clientes). Duración, hora de fin y precio se calculan; no se guardan.
- **ViewModels** (`lib/viewmodels`): un `ChangeNotifier` por pantalla (filtros, búsqueda, fecha seleccionada, formulario). Los de las pestañas viven toda la sesión, así cada pestaña conserva su estado.
- **Vistas** (`lib/views`): solo pintan con `ListenableBuilder` y delegan en el ViewModel.
- **Inyección**: `AppScope` (`InheritedWidget`) sin paquetes externos.
- **Tema** (`lib/theme`): Material 3, fuente Poppins, `ColorScheme` claro y oscuro, radios y espacios como `ThemeExtension` (`TurcoTokens`). Los widgets no usan colores fijos. El tema se cambia entre Sistema, Claro y Oscuro desde la Agenda.

## Navegación (go_router + StatefulShellRoute.indexedStack)

| Ruta | Pantalla |
|---|---|
| `/agenda` (inicial) | Agenda — acepta `?estilista=ID` |
| `/clientes` | Clientes |
| `/servicios` | Servicios |
| `/estilistas` | Estilistas |
| `/turno/nuevo` | Formulario de turno (crear) — datos iniciales con `extra` |
| `/turno/:id` | Detalle de turno |
| `/turno/:id/editar` | Formulario de turno (editar) |

Detalle y formulario se abren sobre la barra inferior (`parentNavigatorKey`). Se usan `pathParameters`, `queryParameters`, `extra` y retorno con `context.pop(valor)`.

## Estructura de carpetas

```
turco/
├── android/                 Proyecto Android (Kotlin DSL)
├── assets/
│   ├── fonts/               Poppins (Regular, Medium, SemiBold, Bold)
│   └── images/              Logo, imágenes de categoría, avatares e ilustraciones (exportados del diseño)
├── capturas/                Capturas reales de la app corriendo
├── entrega/                 APK release
├── lib/
│   ├── main.dart            Punto de entrada
│   ├── app.dart             MaterialApp.router y tema
│   ├── app_scope.dart       Inyección de modelo y ViewModels
│   ├── data/                SalonRepository (reglas) y datos de prueba
│   ├── models/              Entidades, enumeraciones y reglas de horario
│   ├── router/              Configuración de GoRouter
│   ├── theme/               Tema claro/oscuro y tokens de diseño
│   ├── utils/               Formatos en español y normalización de texto
│   ├── viewmodels/          ViewModels (ChangeNotifier)
│   ├── views/               Pantallas: agenda, turno, clientes, servicios, estilistas, shell
│   └── widgets/             Widgets reutilizables
├── test/                    Pruebas de datos y reglas
├── analysis_options.yaml
└── pubspec.yaml
```

## Datos de prueba

13 servicios en 5 categorías (5 solo mujeres, 4 solo hombres, 4 unisex), 5 estilistas (Marta solo mujeres, Pedro solo hombres, Lucía ambos), 10 clientes (5 mujeres y 5 hombres; Javier Soto sin turnos) y 17 turnos en siete días laborables alrededor de hoy, calculados con `DateTime.now()`: 6 hoy, al menos 4 completados y 3 cancelados, uno con 3 servicios, uno sin notas, uno con notas de más de 300 caracteres y uno que termina a las 19:00. Rafael no tiene turnos hoy. Si la app se abre un domingo (salón cerrado), el "día de hoy" de los datos pasa al lunes.
