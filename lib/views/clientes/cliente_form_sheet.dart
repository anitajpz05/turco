import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/cliente.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/cliente_form_viewmodel.dart';
import '../../widgets/campos.dart';

/// Abre el formulario de cliente en una hoja inferior. Devuelve el cliente guardado.
/// Se reutiliza desde la pantalla Clientes y desde el formulario de turno.
Future<Cliente?> mostrarFormularioCliente(BuildContext context, {Cliente? editando}) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (_) => ClienteFormSheet(editando: editando),
  );
}

class ClienteFormSheet extends StatefulWidget {
  const ClienteFormSheet({super.key, this.editando});
  final Cliente? editando;

  @override
  State<ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.editando?.nombre);
  late final TextEditingController _telefono = TextEditingController(text: widget.editando?.telefono);
  late final TextEditingController _correo = TextEditingController(text: widget.editando?.correo);
  final _fNombre = FocusNode();
  final _fTelefono = FocusNode();
  final _fGenero = FocusNode();
  final _fCorreo = FocusNode();
  ClienteFormViewModel? _vm;
  AutovalidateMode _auto = AutovalidateMode.disabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= ClienteFormViewModel(AppScope.of(context).repo, editando: widget.editando);
  }

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _correo]) {
      c.dispose();
    }
    for (final f in [_fNombre, _fTelefono, _fGenero, _fCorreo]) {
      f.dispose();
    }
    _vm?.dispose();
    super.dispose();
  }

  bool _err(String? e) => _auto != AutovalidateMode.disabled && e != null;

  void _guardar() {
    final vm = _vm!;
    final valido = _formKey.currentState!.validate();
    if (!valido) {
      setState(() => _auto = AutovalidateMode.onUserInteraction);
      // El foco va al primer campo con error.
      if (vm.validarNombre(_nombre.text) != null) {
        _fNombre.requestFocus();
      } else if (vm.validarTelefono(_telefono.text) != null) {
        _fTelefono.requestFocus();
      } else if (vm.validarGenero() != null) {
        _fGenero.requestFocus();
      } else {
        _fCorreo.requestFocus();
      }
      return;
    }
    final c = vm.guardar(nombre: _nombre.text, telefono: _telefono.text, correo: _correo.text);
    if (c != null) context.pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm!;
    final t = context.tokens;
    final cs = context.colores;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListenableBuilder(
        listenable: Listenable.merge([vm, _nombre, _telefono, _correo]),
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(t.l + 4, 0, t.l + 4, t.l + 4),
          child: Form(
            key: _formKey,
            autovalidateMode: _auto,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(vm.esEdicion ? 'Editar cliente' : 'Nuevo cliente', style: context.textos.titleLarge),
                SizedBox(height: t.l),
                Etiqueta('Nombre', error: _err(vm.validarNombre(_nombre.text))),
                TextFormField(
                  controller: _nombre,
                  focusNode: _fNombre,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  buildCounter: _sinContador,
                  decoration: const InputDecoration(hintText: 'Nombre y apellidos'),
                  validator: vm.validarNombre,
                  onFieldSubmitted: (_) => _fTelefono.requestFocus(),
                ),
                SizedBox(height: t.m),
                Etiqueta('Teléfono', error: _err(vm.validarTelefono(_telefono.text))),
                TextFormField(
                  controller: _telefono,
                  focusNode: _fTelefono,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: const InputDecoration(hintText: '8 dígitos'),
                  validator: vm.validarTelefono,
                  onFieldSubmitted: (_) => _fCorreo.requestFocus(),
                ),
                SizedBox(height: t.m),
                Etiqueta('Género', error: _err(vm.validarGenero())),
                FormField<Genero>(
                  validator: (_) => vm.validarGenero(),
                  builder: (field) => Focus(
                    focusNode: _fGenero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<Genero>(
                          segments: [for (final g in Genero.values) ButtonSegment(value: g, label: Text(g.etiqueta))],
                          selected: vm.genero == null ? <Genero>{} : {vm.genero!},
                          emptySelectionAllowed: true,
                          showSelectedIcon: true,
                          style: field.hasError
                              ? ButtonStyle(side: WidgetStatePropertyAll(BorderSide(color: cs.error)))
                              : null,
                          onSelectionChanged: (s) {
                            if (s.isEmpty) return;
                            vm.elegirGenero(s.first);
                            field.didChange(s.first);
                          },
                        ),
                        if (field.hasError) TextoError(field.errorText!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: t.m),
                Etiqueta('Correo (opcional)', error: _err(vm.validarCorreo(_correo.text))),
                TextFormField(
                  controller: _correo,
                  focusNode: _fCorreo,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'nombre@correo.com'),
                  validator: vm.validarCorreo,
                  onFieldSubmitted: (_) => _guardar(),
                ),
                if (vm.errorGuardado != null) TextoError(vm.errorGuardado!),
                SizedBox(height: t.l + 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
                    ),
                    SizedBox(width: t.s + 2),
                    Expanded(
                      child: FilledButton(onPressed: _guardar, child: const Text('Guardar cliente')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget? _sinContador(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
