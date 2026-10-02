import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../utils/factura.dart';
import '../../widgets/date_range_filter.dart';

class VentasScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const VentasScreen({super.key, required this.usuario});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  // Catálogo compartido con el Dashboard (ver lib/data/mock_data.dart).
  final List<Map<String, dynamic>> _productosDB = mockProductos;

  // Mismo historial que consulta el Dashboard (ver lib/data/mock_data.dart).
  final List<Map<String, dynamic>> _ventas = mockVentas;

  String _filtro = '';
  DateTime? _filtroDesde;
  DateTime? _filtroHasta;

  // Resume los métodos de una venta pagada por partes (ej. "Efectivo + Nequi")
  // en vez de un solo método fijo, ya que ahora una venta puede tener 1+ pagos.
  String _resumenPagos(Map<String, dynamic> venta) {
    final pagos = (venta['pagos'] as List).cast<Map<String, dynamic>>();
    return pagos.map((p) => p['metodo']).join(' + ');
  }

  Future<void> _generarYGuardarFactura(Map<String, dynamic> venta) async {
    try {
      final bytes = await generarFacturaPdfBytes(venta, clientes: mockClientes);
      final idFactura = 'VNT-${venta['id'].toString().padLeft(3, '0')}';
      final ruta = await guardarFacturaPdf(bytes, 'factura-$idFactura');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Factura $idFactura generada en: $ruta'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta registrada, pero no se pudo generar la factura: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Devuelve al lote correspondiente lo descontado al confirmar la venta
  // (ver descontarStock en el botón "Confirmar Venta"), buscando por nombre
  // de producto + número de lote ya que es lo que queda guardado en el
  // snapshot de la venta.
  void _restaurarStock(Map<String, dynamic> venta) {
    final productos = (venta['productos'] as List).cast<Map<String, dynamic>>();
    for (final item in productos) {
      final producto = _productosDB.firstWhere(
        (p) => p['nombre'] == item['nombre'],
        orElse: () => const {},
      );
      if (producto.isEmpty) continue;
      final lotes = (producto['lotes'] as List).cast<Map<String, dynamic>>();
      final lote = lotes.firstWhere(
        (l) => l['numero_lote'] == item['lote'],
        orElse: () => const {},
      );
      if (lote.isEmpty) continue;
      lote['cantidad_disponible'] =
          (lote['cantidad_disponible'] as int) + (item['cantidad'] as int);
    }
  }

  Future<void> _confirmarAnularVenta(Map<String, dynamic> venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Anular esta venta?'),
        content: const Text(
          'El stock se repone y la venta queda marcada como anulada en el historial (no se borra).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Anular',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() {
      _restaurarStock(venta);
      venta['estado'] = 'Anulada';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Venta anulada y stock repuesto.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // DETALLE DE VENTA
  // ==========================================================

  void _verDetalleVenta(BuildContext context, Map<String, dynamic> venta) {
    final productos = (venta['productos'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final pagos = (venta['pagos'] as List).cast<Map<String, dynamic>>();
    final fecha = venta['fecha_hora_venta'] as DateTime?;
    final listo = venta['estado'] == 'Listo';
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

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
                        'Venta #${venta['id'].toString().padLeft(3, '0')}',
                        style: const TextStyle(
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
                            (listo ? AppColors.success : AppColors.actionAmber)
                                .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listo ? 'Listo' : 'Pendiente',
                        style: TextStyle(
                          color: listo
                              ? AppColors.success
                              : AppColors.actionAmber,
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
                Text(
                  venta['cliente'].toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (fecha != null)
                  Text(
                    formatearFecha(fecha),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                const SizedBox(height: 14),
                const Divider(),

                const Text(
                  'Productos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (productos.isEmpty)
                  const Text(
                    'Sin productos registrados.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  ...productos.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p['nombre']} x${p['cantidad']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '\$${(p['precio'] as num) * (p['cantidad'] as num)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                const Divider(),

                const Text(
                  'Pagos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                if (pagos.isEmpty)
                  const Text(
                    'Sin pagos registrados.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                else
                  ...pagos.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p['metodo'].toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '\$${p['monto']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Container(height: 1, color: borderColor),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${venta['total']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.actionAmber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _generarYGuardarFactura(venta),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Descargar factura'),
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
    final ventasFiltradas = _ventas.where((venta) {
      final texto = '${venta['id']} ${venta['cliente']} ${_resumenPagos(venta)}'
          .toLowerCase();

      return texto.contains(_filtro.toLowerCase()) &&
          estaEnRangoFecha(
            venta['fecha_hora_venta'] as DateTime?,
            _filtroDesde,
            _filtroHasta,
          );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _filtro = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar factura o cliente...',
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 10),

            DateRangeFilter(
              desde: _filtroDesde,
              hasta: _filtroHasta,
              onDesdeChange: (fecha) => setState(() => _filtroDesde = fecha),
              onHastaChange: (fecha) => setState(() => _filtroHasta = fecha),
            ),

            const SizedBox(height: 12),

            const Text(
              'Historial de Transacciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ventasFiltradas.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay transacciones.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: ventasFiltradas.length,
                      itemBuilder: (context, index) {
                        final venta = ventasFiltradas[index];

                        final bool listo = venta['estado'] == 'Listo';
                        final bool anulada = venta['estado'] == 'Anulada';

                        return GestureDetector(
                          onTap: () => _verDetalleVenta(context, venta),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color:
                                            (anulada
                                                    ? AppColors.danger
                                                    : listo
                                                    ? AppColors.success
                                                    : AppColors.actionAmber)
                                                .withValues(alpha: .12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        anulada
                                            ? Icons.close
                                            : listo
                                            ? Icons.check
                                            : Icons.schedule,
                                        color: anulada
                                            ? AppColors.danger
                                            : listo
                                            ? AppColors.success
                                            : AppColors.actionAmber,
                                        size: 20,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Venta #${venta['id'].toString().padLeft(3, '0')}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            venta['cliente'].toString(),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            _resumenPagos(venta),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Estado + total agrupados junto al dinero,
                                    // en vez de que el estado quede suelto en
                                    // una fila aparte más abajo.
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (anulada
                                                        ? AppColors.danger
                                                        : listo
                                                        ? AppColors.success
                                                        : AppColors.actionAmber)
                                                    .withValues(alpha: .12),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            anulada
                                                ? 'Anulada'
                                                : listo
                                                ? 'Listo'
                                                : 'Pendiente',
                                            style: TextStyle(
                                              color: anulada
                                                  ? AppColors.danger
                                                  : listo
                                                  ? AppColors.success
                                                  : AppColors.actionAmber,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${venta['total']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.actionAmber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // ==================================
                                // PENDIENTE -> LISTO -> ANULADA
                                // ==================================
                                if (anulada)
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block,
                                        color: Colors.grey,
                                        size: 14,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Venta anulada — stock repuesto',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (listo)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.success,
                                            size: 14,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Venta completada',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _confirmarAnularVenta(venta),
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 15,
                                        ),
                                        label: const Text(
                                          'Anular',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          venta['estado'] = 'Listo';
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Venta marcada como lista.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text(
                                        'Marcar como listo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Mismo botón sólido (fondo ámbar +
                                      // texto blanco) que "Abrir jornada"
                                      // y el resto de acciones de la app:
                                      // un texto tintado sin relleno se
                                      // leía como una etiqueta, no como
                                      // algo tocable.
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.actionAmber,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioNuevaVenta(context),
        tooltip: 'Nueva venta',
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  // ==========================================================
  // NUEVA VENTA
  // ==========================================================

  void _abrirFormularioNuevaVenta(BuildContext context) {
    if (jornadaAbierta() == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No hay jornada abierta'),
          content: const Text(
            'Debes abrir una jornada (pestaña "Jornada") antes de poder registrar ventas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        Map<String, dynamic> clienteSeleccionado = mockClientes.first;
        String nuevoPagoMetodo = mockMetodosPago.first;
        String filtroProducto = '';

        final List<Map<String, dynamic>> carrito = [];
        final List<Map<String, dynamic>> pagos = [];
        final montoPagoController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateModal) {
            double calcularTotal() {
              return carrito.fold(
                0,
                (sum, item) => sum + (item['precio'] * item['cantidad']),
              );
            }

            double calcularTotalPagado() {
              return pagos.fold(0, (sum, p) => sum + (p['monto'] as num));
            }

            void sinStock() {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No hay más stock disponible de este producto.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            // Misma restricción de edad que en la web (ver
            // utils/edad.js validarEdadCliente): un producto de categoría
            // +18 exige que el cliente seleccionado tenga fecha de
            // nacimiento registrada y sea mayor de edad. "Cliente General"
            // nunca la exige (verificación visual del cajero).
            bool puedeAgregar(Map<String, dynamic> producto) {
              if (producto['requiereEdad'] != true) return true;
              final mensaje = validarEdadCliente(clienteSeleccionado);
              if (mensaje != null) {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Verificación de edad requerida'),
                    content: Text(mensaje),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
                return false;
              }
              return true;
            }

            // Agrega (o suma) unidades de un producto al carrito. El stock
            // disponible es siempre la suma real de los lotes vigentes.
            void agregarAlCarrito(Map<String, dynamic> producto, int cantidad) {
              setStateModal(() {
                final index = carrito.indexWhere(
                  (item) => item['id'] == producto['id'],
                );

                if (index >= 0) {
                  carrito[index]['cantidad'] =
                      (carrito[index]['cantidad'] as int) + cantidad;
                } else {
                  carrito.add({
                    ...producto,
                    'cantidad': cantidad,
                    'loteInfo': lotesDisponibles(producto).first,
                  });
                }
              });
            }

            // ==============================================
            // ELEGIR CANTIDAD ANTES DE AGREGAR
            // ==============================================

            void abrirSelectorCantidad(Map<String, dynamic> producto) {
              final yaEnCarrito =
                  carrito.firstWhere(
                        (item) => item['id'] == producto['id'],
                        orElse: () => const {'cantidad': 0},
                      )['cantidad']
                      as int;

              final maxDisponible = stockDisponible(producto) - yaEnCarrito;

              if (maxDisponible <= 0) {
                sinStock();
                return;
              }

              int cantidadSeleccionada = 1;

              showDialog(
                context: context,
                builder: (dialogContext) {
                  return StatefulBuilder(
                    builder: (dialogContext, setStateDialog) {
                      return AlertDialog(
                        title: Text(
                          producto['nombre'].toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¿Cuántas unidades se van a entregar?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: cantidadSeleccionada > 1
                                      ? () => setStateDialog(
                                          () => cantidadSeleccionada--,
                                        )
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: AppColors.actionAmber,
                                    size: 34,
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '$cantidadSeleccionada',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      cantidadSeleccionada < maxDisponible
                                      ? () => setStateDialog(
                                          () => cantidadSeleccionada++,
                                        )
                                      : null,
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: AppColors.actionAmber,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stock disponible: $maxDisponible',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              agregarAlCarrito(producto, cantidadSeleccionada);
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Agregar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            }

            // Ajusta la cantidad de un producto ya en el carrito. Al llegar
            // a 0 se quita la línea; el tope siempre es el stock real
            // (suma de lotes vigentes), no un valor fijo.
            void cambiarCantidad(int index, int delta) {
              setStateModal(() {
                final item = carrito[index];
                final nuevaCantidad = (item['cantidad'] as int) + delta;

                if (nuevaCantidad <= 0) {
                  carrito.removeAt(index);
                  return;
                }

                if (nuevaCantidad > stockDisponible(item)) {
                  sinStock();
                  return;
                }

                carrito[index]['cantidad'] = nuevaCantidad;
              });
            }

            // El alto se calcula contra el espacio que realmente queda
            // visible ARRIBA del teclado (no contra el alto total de la
            // pantalla, que ignora el teclado) y el padding para esquivarlo
            // se aplica UNA sola vez, afuera de esa caja — así nunca queda
            // contenido (el monto del pago, el botón de confirmar) oculto
            // detrás del teclado sin poder hacerle scroll para verlo.
            final alturaDisponible =
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).viewInsets.bottom;

            return PopScope(
              // Salir con el botón/gesto de atrás sin confirmar borraba el
              // carrito armado hasta ese momento; con productos agregados,
              // se pide confirmar antes de descartar la venta.
              canPop: carrito.isEmpty,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                final descartar = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('¿Descartar esta venta?'),
                    content: Text(
                      'Se perderán los ${carrito.length} producto(s) agregados al carrito.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text(
                          'Descartar',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
                if (descartar == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: alturaDisponible * .88,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                        right: 18,
                        top: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ======================================
                          // HEADER
                          // ======================================

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Registrar Venta',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),

                          const Divider(),

                          // El contenido intermedio es lo único que se
                          // desplaza; encabezado, total y botón quedan
                          // siempre visibles y nunca se desbordan.
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),

                                  // ======================================
                                  // CLIENTE (define si aplica verificación
                                  // de edad para productos +18, ver
                                  // puedeAgregar más arriba)
                                  // ======================================
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                    initialValue: clienteSeleccionado,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Cliente',
                                    ),
                                    items: mockClientes.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c['nombre'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setStateModal(() {
                                          clienteSeleccionado = value;
                                        });
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  const Text(
                                    'Agregar producto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // ======================================
                                  // BUSCADOR + LISTA DE PRODUCTOS
                                  // (lista buscable, igual que en la web: nada
                                  // de tarjetas en fila; "por vencer" es solo
                                  // una sugerencia secundaria junto al precio).
                                  // ======================================
                                  TextField(
                                    onChanged: (value) {
                                      setStateModal(() {
                                        filtroProducto = value;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Buscar producto por nombre...',
                                      prefixIcon: Icon(Icons.search, size: 20),
                                      isDense: true,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 220,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final productosFiltrados = _productosDB
                                            .where(
                                              (p) => p['nombre']
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(
                                                    filtroProducto
                                                        .toLowerCase(),
                                                  ),
                                            )
                                            .toList();

                                        if (productosFiltrados.isEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No se encontraron productos.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: productosFiltrados.length,
                                          separatorBuilder: (_, _) => Divider(
                                            height: 1,
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder,
                                          ),
                                          itemBuilder: (context, index) {
                                            final p = productosFiltrados[index];
                                            final sugerencia =
                                                sugerenciaVencimiento(p);
                                            final disponible = stockDisponible(
                                              p,
                                            );

                                            return ListTile(
                                              dense: true,
                                              title: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      p['nombre'].toString(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  if (p['requiereEdad'] ==
                                                      true) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.danger
                                                            .withValues(
                                                              alpha: .12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        '+18',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.danger,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              subtitle: Row(
                                                children: [
                                                  Text(
                                                    '\$${p['precio']} · Stock: $disponible',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  if (sugerencia != null) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .actionAmber
                                                            .withValues(
                                                              alpha: .12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Por vencer (${sugerencia['dias']}d)',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .actionAmber,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle,
                                                  color: AppColors.actionAmber,
                                                ),
                                                onPressed: disponible <= 0
                                                    ? null
                                                    : () {
                                                        if (puedeAgregar(p)) {
                                                          abrirSelectorCantidad(
                                                            p,
                                                          );
                                                        }
                                                      },
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  const Text(
                                    'Detalle del Carrito',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  // ======================================
                                  // CARRITO
                                  // ======================================
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 180,
                                    ),
                                    child: carrito.isEmpty
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              child: Text(
                                                'Sin productos agregados',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: carrito.length,
                                            itemBuilder: (context, index) {
                                              final item = carrito[index];

                                              final loteInfo =
                                                  item['loteInfo']
                                                      as Map<String, dynamic>?;
                                              final numeroLote =
                                                  loteInfo?['numero_lote'] ??
                                                  'Sin lote';

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 7,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .scaffoldBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item['nombre']
                                                                .toString(),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 3,
                                                          ),
                                                          Text(
                                                            'Lote: $numeroLote',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          // ====================
                                                          // CANTIDAD A ENTREGAR
                                                          // ====================
                                                          Row(
                                                            children: [
                                                              _StepperButton(
                                                                icon: Icons
                                                                    .remove_circle_outline,
                                                                onPressed: () =>
                                                                    cambiarCantidad(
                                                                      index,
                                                                      -1,
                                                                    ),
                                                              ),
                                                              SizedBox(
                                                                width: 28,
                                                                child: Text(
                                                                  '${item['cantidad']}',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                              ),
                                                              _StepperButton(
                                                                icon: Icons
                                                                    .add_circle_outline,
                                                                onPressed: () =>
                                                                    cambiarCantidad(
                                                                      index,
                                                                      1,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$${item['precio'] * item['cantidad']}',
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .actionAmber,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      onPressed: () {
                                                        setStateModal(() {
                                                          carrito.removeAt(
                                                            index,
                                                          );
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.redAccent,
                                                        size: 19,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ======================================
                                  // PAGOS (pago por partes: la venta se
                                  // confirma solo cuando la suma de pagos
                                  // cuadra exacto con el total, igual que
                                  // en la web).
                                  // ======================================
                                  const Text(
                                    'Pagos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: nuevoPagoMetodo,
                                          isExpanded: true,
                                          isDense: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Método',
                                          ),
                                          items: mockMetodosPago.map((m) {
                                            return DropdownMenuItem(
                                              value: m,
                                              child: Text(m),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setStateModal(() {
                                                nuevoPagoMetodo = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: montoPagoController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Monto',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: AppColors.actionAmber,
                                        ),
                                        onPressed: () {
                                          final monto = num.tryParse(
                                            montoPagoController.text,
                                          );
                                          if (monto == null || monto <= 0) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'El monto del pago debe ser mayor que cero.',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                            return;
                                          }
                                          setStateModal(() {
                                            pagos.add({
                                              'metodo': nuevoPagoMetodo,
                                              'monto': monto,
                                            });
                                            montoPagoController.clear();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (pagos.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    ...pagos.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final pago = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pago['metodo'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '\$${pago['monto']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  setStateModal(() {
                                                    pagos.removeAt(index);
                                                  }),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const Divider(),

                          // ======================================
                          // TOTAL
                          // ======================================
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total General:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${calcularTotal().toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.actionAmber,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Builder(
                            builder: (context) {
                              final diferencia =
                                  calcularTotal() - calcularTotalPagado();
                              if (carrito.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              if (diferencia.abs() < 0.01) {
                                return const Text(
                                  'Cuadrado ✓',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return Text(
                                diferencia > 0
                                    ? 'Falta: \$${diferencia.toStringAsFixed(0)}'
                                    : 'Sobra: \$${(-diferencia).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  carrito.isEmpty ||
                                      (calcularTotal() - calcularTotalPagado())
                                              .abs() >=
                                          0.01
                                  ? null
                                  : () {
                                      // Re-validación defensiva de edad: por si
                                      // el cliente se cambió después de armar el
                                      // carrito (espejo de la revalidación en
                                      // handleConfirmarVenta de la web).
                                      final itemRestringido = carrito
                                          .firstWhere(
                                            (i) => i['requiereEdad'] == true,
                                            orElse: () => const {},
                                          );
                                      if (itemRestringido.isNotEmpty &&
                                          !puedeAgregar(itemRestringido)) {
                                        return;
                                      }

                                      // El descuento de stock es real: se resta
                                      // de los lotes vigentes en orden FEFO
                                      // (primero el que vence antes), igual que
                                      // en la web. Si algo cambió entre agregar
                                      // al carrito y confirmar, se valida de
                                      // nuevo aquí antes de tocar nada.
                                      for (final item in carrito) {
                                        if (stockDisponible(item) <
                                            (item['cantidad'] as int)) {
                                          sinStock();
                                          return;
                                        }
                                      }

                                      for (final item in carrito) {
                                        descontarStock(
                                          item,
                                          item['cantidad'] as int,
                                        );
                                      }

                                      final nuevaVenta = {
                                        'id': _ventas.length + 1,
                                        'cliente':
                                            clienteSeleccionado['nombre'],
                                        // Necesario para que el Dashboard del
                                        // Empleado Auxiliar pueda filtrar "mis
                                        // ventas en la jornada actual".
                                        'usuario': widget.usuario['nombre'],
                                        'id_jornada':
                                            jornadaAbierta()?['id_jornada'],
                                        'fecha_hora_venta': DateTime.now(),
                                        'productos': carrito
                                            .map(
                                              (item) => {
                                                'nombre': item['nombre'],
                                                'cantidad': item['cantidad'],
                                                'precio': item['precio'],
                                                'porcentajeIva':
                                                    item['porcentajeIva'] ?? 0,
                                                'lote':
                                                    (item['loteInfo']
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >?)?['numero_lote'] ??
                                                    'Sin lote',
                                              },
                                            )
                                            .toList(),
                                        'pagos':
                                            List<Map<String, dynamic>>.from(
                                              pagos,
                                            ),
                                        'total': calcularTotal().toInt(),
                                        'estado': 'Pendiente',
                                      };

                                      setState(() {
                                        _ventas.insert(0, nuevaVenta);
                                      });

                                      Navigator.pop(context);

                                      // Factura automática al confirmar (ver
                                      // utils/factura.dart): el pago ya está
                                      // completo en este punto (se exige cuadrar
                                      // los pagos antes de habilitar este botón).
                                      _generarYGuardarFactura(nuevaVenta);
                                    },
                              child: const Text(
                                'Confirmar Venta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Botón compacto +/- para ajustar la cantidad a entregar de una línea del
// carrito, sin recurrir a un diálogo aparte.
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 20, color: AppColors.actionAmber),
      ),
    );
  }
}
