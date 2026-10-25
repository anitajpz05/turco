import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../models/estilista.dart';
import '../theme/app_theme.dart';

/// Imagen monocroma de assets teñida con un color del tema
/// (así las imágenes se adaptan al modo claro y oscuro).
class ImagenTema extends StatelessWidget {
  const ImagenTema(this.ruta, {super.key, required this.color, this.size = 24});

  final String ruta;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    ruta,
    width: size,
    height: size,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
  );
}

/// Logo de Turco (tijeras sobre un cuadrado redondeado).
class LogoTurco extends StatelessWidget {
  const LogoTurco({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(size * 0.31)),
      alignment: Alignment.center,
      child: ImagenTema('assets/images/logo.png', color: cs.onPrimary, size: size * 0.56),
    );
  }
}

/// Avatar circular con la inicial de un cliente (mujeres: primario; hombres: terciario).
class AvatarCliente extends StatelessWidget {
  const AvatarCliente({super.key, required this.inicial, required this.genero, this.size = 44});

  final String inicial;
  final Genero genero;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final mujer = genero == Genero.mujer;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: mujer ? cs.primaryContainer : cs.tertiaryContainer),
      child: Text(
        inicial,
        style: context.textos.titleMedium?.copyWith(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: mujer ? cs.onPrimaryContainer : cs.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// Avatar de un estilista a partir de su imagen en assets.
class AvatarEstilista extends StatelessWidget {
  const AvatarEstilista({super.key, required this.estilista, this.size = 56});

  final Estilista estilista;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
      child: ImagenTema(estilista.avatar, color: cs.onPrimaryContainer, size: size * 0.62),
    );
  }
}

/// Etiqueta de estado del turno con su color.
class EstadoBadge extends StatelessWidget {
  const EstadoBadge(this.estado, {super.key});
  final EstadoTurno estado;

  @override
  Widget build(BuildContext context) {
    final c = ColoresEstado.de(estado, context.colores);
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.s + 2, vertical: t.xs),
      decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(t.radioChip)),
      child: Text(
        estado.etiqueta,
        style: context.textos.labelSmall?.copyWith(color: c.texto, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Mensaje con ilustración para listas vacías o sin resultados.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.imagen,
    required this.titulo,
    required this.mensaje,
    this.error = false,
    this.accion,
  });

  final String imagen;
  final String titulo;
  final String mensaje;
  final bool error;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.xl, vertical: t.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: error ? cs.errorContainer : cs.primaryContainer),
            child: ImagenTema(imagen, color: error ? cs.error : cs.onPrimaryContainer, size: 56),
          ),
          SizedBox(height: t.l + 4),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: context.textos.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: t.s),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: context.textos.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (accion != null) ...[SizedBox(height: t.l + 4), accion!],
        ],
      ),
    );
  }
}

/// Diálogo de confirmación con el estilo del diseño. Devuelve true si se confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String textoConfirmar,
  String textoCancelar = 'Volver',
  bool destructivo = true,
  IconData icono = Icons.warning_amber_rounded,
}) async {
  final r = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(icono, color: destructivo ? cs.error : cs.primary),
        iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        title: Text(titulo, textAlign: TextAlign.start),
        content: Text(mensaje),
        alignment: Alignment.center,
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(textoCancelar)),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: destructivo ? cs.error : cs.primary),
            child: Text(textoConfirmar),
          ),
        ],
      );
    },
  );
  return r ?? false;
}

/// Fila de chips de filtro desplazable horizontalmente.
class FilaChips<T> extends StatelessWidget {
  const FilaChips({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.etiqueta,
    required this.onSelected,
  });

  final List<T> opciones;
  final T seleccion;
  final String Function(T) etiqueta;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in opciones)
            Padding(
              padding: EdgeInsets.only(right: t.s),
              child: FilterChip(label: Text(etiqueta(o)), selected: o == seleccion, onSelected: (_) => onSelected(o)),
            ),
        ],
      ),
    );
  }
}
