import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../widgets/comunes.dart';

/// Tarjeta de un turno en la Agenda: barra de estado, horas, cliente, servicios, estilista y estado.
class TurnoCard extends StatelessWidget {
  const TurnoCard({
    super.key,
    required this.inicio,
    required this.fin,
    required this.cliente,
    required this.servicios,
    required this.estilista,
    required this.estado,
    this.onTap,
    this.onLongPress,
  });

  final DateTime inicio;
  final DateTime fin;
  final String cliente;
  final String servicios;
  final String estilista;
  final EstadoTurno estado;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.colores;
    final colores = ColoresEstado.de(estado, cs);
    return Opacity(
      opacity: estado == EstadoTurno.cancelado ? 0.75 : 1,
      child: Card(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.fromLTRB(t.s + 2, t.m, t.m, t.m),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(color: colores.barra, borderRadius: BorderRadius.circular(2)),
                  ),
                  SizedBox(width: t.m),
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formato.hora(inicio),
                          style: context.textos.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Text(Formato.hora(fin), style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  SizedBox(width: t.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textos.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: t.xs / 2),
                        Text(
                          servicios,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textos.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        SizedBox(height: t.xs),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                            SizedBox(width: t.xs),
                            Expanded(
                              child: Text(
                                estilista,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textos.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                            EstadoBadge(estado),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
