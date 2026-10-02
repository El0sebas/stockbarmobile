import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/date_range_filter.dart';

class JornadaScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const JornadaScreen({super.key, required this.usuario});

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen> {
  DateTime? _filtroDesde;
  DateTime? _filtroHasta;

  void _abrirJornada() {
    setState(() {
      mockJornadas.insert(0, {
        'id_jornada': mockJornadas.length + 1,
        'usuario_apertura': widget.usuario['nombre'],
        'fecha_hora_apertura': DateTime.now(),
        'usuario_cierre': null,
        'fecha_hora_cierre': null,
        'estado': 'ABIERTA',
      });
    });
  }

  Future<void> _cerrarJornada() async {
    // Antes cerraba directo, sin preguntar nada; ahora pide una confirmación
    // simple. El desglose de la jornada se ve aparte, en cualquier momento,
    // tocando la tarjeta en el historial (ver _verDetalleJornada).
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar jornada?'),
        content: const Text(
          'No podrás registrar más ventas hasta abrir una nueva jornada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cerrar jornada',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() {
      final abierta = jornadaAbierta();
      if (abierta == null) return;
      abierta['usuario_cierre'] = widget.usuario['nombre'];
      abierta['fecha_hora_cierre'] = DateTime.now();
      abierta['estado'] = 'CERRADA';
    });
  }

  // Desglose de una jornada (abierta o cerrada): ventas completadas, total
  // vendido y forma de pago — mismo criterio que el detalle de jornada web.
  void _verDetalleJornada(BuildContext context, Map<String, dynamic> jornada) {
    final ventasDeLaJornada = mockVentas.where(
      (v) => v['id_jornada'] == jornada['id_jornada'] && v['estado'] == 'Listo',
    );

    final totalVendido = ventasDeLaJornada.fold<num>(
      0,
      (sum, v) => sum + (v['total'] as num),
    );

    final totalesPorMetodo = <String, num>{};
    for (final v in ventasDeLaJornada) {
      final pagos = (v['pagos'] as List).cast<Map<String, dynamic>>();
      for (final p in pagos) {
        final metodo = p['metodo'].toString();
        totalesPorMetodo[metodo] =
            (totalesPorMetodo[metodo] ?? 0) + (p['monto'] as num);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle de jornada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (jornada['estado'] == 'ABIERTA'
                                    ? AppColors.success
                                    : Colors.grey)
                                .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        jornada['estado'].toString(),
                        style: TextStyle(
                          color: jornada['estado'] == 'ABIERTA'
                              ? AppColors.success
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Apertura: ${formatearFecha(jornada['fecha_hora_apertura'] as DateTime)} • ${jornada['usuario_apertura']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                Text(
                  jornada['fecha_hora_cierre'] != null
                      ? 'Cierre: ${formatearFecha(jornada['fecha_hora_cierre'] as DateTime)} • ${jornada['usuario_cierre']}'
                      : 'Cierre: —',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 14),
                const Divider(),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ventas completadas',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            '${ventasDeLaJornada.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total vendido',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        Text(
                          '\$$totalVendido',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.actionAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(),

                const Text(
                  'Forma de pago',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (totalesPorMetodo.isEmpty)
                  const Text(
                    'Sin ventas completadas en esta jornada todavía.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  ...totalesPorMetodo.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '\$${e.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final abierta = jornadaAbierta();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final jornadasFiltradas = mockJornadas
        .where(
          (j) => estaEnRangoFecha(
            j['fecha_hora_apertura'] as DateTime?,
            _filtroDesde,
            _filtroHasta,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Jornada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  abierta != null ? Icons.door_front_door : Icons.lock_outline,
                  size: 32,
                  color: abierta != null ? AppColors.success : Colors.grey,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        abierta != null
                            ? 'Jornada abierta'
                            : 'Sin jornada abierta',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        abierta != null
                            ? 'Desde ${formatearFecha(abierta['fecha_hora_apertura'] as DateTime)} por ${abierta['usuario_apertura']}'
                            : 'Debes abrir una jornada antes de registrar ventas.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: abierta != null ? _cerrarJornada : _abrirJornada,
            icon: Icon(abierta != null ? Icons.lock_outline : Icons.lock_open),
            label: Text(abierta != null ? 'Cerrar jornada' : 'Abrir jornada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: abierta != null
                  ? AppColors.danger
                  : AppColors.actionAmber,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Historial de jornadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          DateRangeFilter(
            desde: _filtroDesde,
            hasta: _filtroHasta,
            onDesdeChange: (fecha) => setState(() => _filtroDesde = fecha),
            onHastaChange: (fecha) => setState(() => _filtroHasta = fecha),
          ),
          const SizedBox(height: 12),

          if (jornadasFiltradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  mockJornadas.isEmpty
                      ? 'Todavía no se ha abierto ninguna jornada.'
                      : 'No hay jornadas con ese filtro.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...jornadasFiltradas.map(
              (j) => GestureDetector(
                onTap: () => _verDetalleJornada(context, j),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Apertura: ${formatearFecha(j['fecha_hora_apertura'] as DateTime)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              j['fecha_hora_cierre'] != null
                                  ? 'Cierre: ${formatearFecha(j['fecha_hora_cierre'] as DateTime)}'
                                  : 'Cierre: —',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (j['estado'] == 'ABIERTA'
                                      ? AppColors.success
                                      : Colors.grey)
                                  .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          j['estado'].toString(),
                          style: TextStyle(
                            color: j['estado'] == 'ABIERTA'
                                ? AppColors.success
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
