import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Etiqueta situada encima de un campo (en color de error si el campo es inválido).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.error = false});
  final String texto;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.tokens.xs + 2),
    child: Text(
      texto,
      style: context.textos.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: error ? context.colores.error : context.colores.onSurfaceVariant,
      ),
    ),
  );
}

/// Mensaje de error con ícono, para campos personalizados (chips, franjas, segmentos).
class TextoError extends StatelessWidget {
  const TextoError(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = context.colores;
    return Padding(
      padding: EdgeInsets.only(top: context.tokens.xs + 2, left: context.tokens.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, size: 16, color: cs.error),
          ),
          SizedBox(width: context.tokens.xs + 2),
          Expanded(
            child: Text(texto, style: context.textos.bodySmall?.copyWith(color: cs.error)),
          ),
        ],
      ),
    );
  }
}

/// Campo de selección que abre un selector (hoja inferior o diálogo) y participa en el [Form].
///
/// El valor real vive en el ViewModel; el validador se le pasa ya resuelto.
class CampoSelector<T> extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.valor,
    required this.texto,
    required this.hint,
    required this.icono,
    required this.validator,
    required this.onTap,
    required this.focusNode,
    this.habilitado = true,
  });

  final T? valor;
  final String? texto;
  final String hint;
  final IconData icono;
  final String? Function() validator;
  final Future<void> Function() onTap;
  final FocusNode focusNode;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: valor,
      validator: (_) => validator(),
      builder: (field) {
        if (field.value != valor) {
          // Mantiene sincronizado el FormField con el ViewModel.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(valor);
          });
        }
        return ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) => Focus(
            focusNode: focusNode,
            child: InkWell(
              borderRadius: BorderRadius.circular(context.tokens.radioCampo),
              onTap: !habilitado
                  ? null
                  : () async {
                      focusNode.requestFocus();
                      await onTap();
                    },
              child: InputDecorator(
                isFocused: focusNode.hasFocus,
                isEmpty: texto == null,
                decoration: InputDecoration(
                  enabled: habilitado,
                  hintText: hint,
                  errorText: field.errorText,
                  prefixIcon: Icon(icono),
                  suffixIcon: const Icon(Icons.expand_more),
                ),
                child: Text(
                  texto ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textos.bodyMedium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
