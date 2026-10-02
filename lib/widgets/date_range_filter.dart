import 'package:flutter/material.dart';

// Filtro por rango de fechas, reutilizado en VentasScreen y JornadaScreen
// (historial): reemplaza el filtro por estado, más útil para ver "las
// ventas/jornadas de esta semana" que un simple Pendiente/Listo.
class DateRangeFilter extends StatelessWidget {
  final DateTime? desde;
  final DateTime? hasta;
  final ValueChanged<DateTime?> onDesdeChange;
  final ValueChanged<DateTime?> onHastaChange;

  const DateRangeFilter({
    super.key,
    required this.desde,
    required this.hasta,
    required this.onDesdeChange,
    required this.onHastaChange,
  });

  Future<void> _elegir(
    BuildContext context,
    DateTime? actual,
    ValueChanged<DateTime?> onChange,
  ) async {
    final elegido = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegido != null) onChange(elegido);
  }

  String _formato(DateTime? fecha) {
    if (fecha == null) return '';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _elegir(context, desde, onDesdeChange),
            icon: const Icon(Icons.calendar_today, size: 14),
            label: Text(
              desde == null ? 'Desde' : _formato(desde),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _elegir(context, hasta, onHastaChange),
            icon: const Icon(Icons.calendar_today, size: 14),
            label: Text(
              hasta == null ? 'Hasta' : _formato(hasta),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        if (desde != null || hasta != null)
          IconButton(
            onPressed: () {
              onDesdeChange(null);
              onHastaChange(null);
            },
            icon: const Icon(Icons.clear, size: 18),
            tooltip: 'Quitar filtro de fechas',
          ),
      ],
    );
  }
}
