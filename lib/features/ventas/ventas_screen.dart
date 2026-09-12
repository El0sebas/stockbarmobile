import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  // Catálogo compartido con el Dashboard (ver lib/data/mock_data.dart).
  final List<Map<String, dynamic>> _productosDB = mockProductos;

  // Mismo historial que consulta el Dashboard (ver lib/data/mock_data.dart).
  final List<Map<String, dynamic>> _ventas = mockVentas;

  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final ventasFiltradas = _ventas.where((venta) {
      final texto = '${venta['id']} ${venta['cliente']} ${venta['metodo']}'
          .toLowerCase();

      return texto.contains(_filtro.toLowerCase());
    }).toList();

    return Scaffold(
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

            const SizedBox(height: 20),

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

                        return Container(
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
                                      color: listo
                                          ? AppColors.success.withValues(
                                              alpha: .12,
                                            )
                                          : AppColors.actionAmber.withValues(
                                              alpha: .12,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      listo ? Icons.check : Icons.schedule,
                                      color: listo
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
                                          venta['metodo'].toString(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

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

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (listo
                                                  ? AppColors.success
                                                  : AppColors.actionAmber)
                                              .withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      listo ? 'Listo' : 'Pendiente',
                                      style: TextStyle(
                                        color: listo
                                            ? AppColors.success
                                            : AppColors.actionAmber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // ==================================
                                  // PENDIENTE -> LISTO
                                  // ==================================
                                  if (!listo)
                                    TextButton.icon(
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.success,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Venta completada',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioNuevaVenta(context),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================================
  // NUEVA VENTA
  // ==========================================================

  void _abrirFormularioNuevaVenta(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        String metodoPago = 'Efectivo';
        String cliente = 'Cliente General';
        String filtroProducto = '';

        final List<Map<String, dynamic>> carrito = [];

        return StatefulBuilder(
          builder: (context, setStateModal) {
            double calcularTotal() {
              return carrito.fold(
                0,
                (sum, item) => sum + (item['precio'] * item['cantidad']),
              );
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

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .88,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 18,
                    right: 18,
                    top: 15,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
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
                              // CLIENTE + PAGO
                              // ======================================
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 500) {
                                    return Column(
                                      children: [
                                        DropdownButtonFormField<String>(
                                          initialValue: cliente,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Cliente',
                                          ),
                                          items:
                                              [
                                                'Cliente General',
                                                'Juan David Posso',
                                              ].map((c) {
                                                return DropdownMenuItem(
                                                  value: c,
                                                  child: Text(
                                                    c,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setStateModal(() {
                                                cliente = value;
                                              });
                                            }
                                          },
                                        ),

                                        const SizedBox(height: 12),

                                        DropdownButtonFormField<String>(
                                          initialValue: metodoPago,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Método de Pago',
                                          ),
                                          items:
                                              [
                                                'Efectivo',
                                                'Nequi',
                                                'Bancolombia',
                                              ].map((m) {
                                                return DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setStateModal(() {
                                                metodoPago = value;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: cliente,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Cliente',
                                          ),
                                          items:
                                              [
                                                'Cliente General',
                                                'Juan David Posso',
                                              ].map((c) {
                                                return DropdownMenuItem(
                                                  value: c,
                                                  child: Text(
                                                    c,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setStateModal(() {
                                                cliente = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: metodoPago,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Método de Pago',
                                          ),
                                          items:
                                              [
                                                'Efectivo',
                                                'Nequi',
                                                'Bancolombia',
                                              ].map((m) {
                                                return DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setStateModal(() {
                                                metodoPago = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
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
                                                filtroProducto.toLowerCase(),
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
                                        final disponible = stockDisponible(p);

                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            p['nombre'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
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
                                                    color: AppColors.actionAmber
                                                        .withValues(alpha: .12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Por vencer (${sugerencia['dias']}d)',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.actionAmber,
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
                                                : () =>
                                                      abrirSelectorCantidad(p),
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
                                            padding: const EdgeInsets.symmetric(
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Lote: $numeroLote',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
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
                                                                fontSize: 13,
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
                                                    color:
                                                        AppColors.actionAmber,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () {
                                                    setStateModal(() {
                                                      carrito.removeAt(index);
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

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: carrito.isEmpty
                              ? null
                              : () {
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
                                    'cliente': cliente,
                                    'metodo': metodoPago,
                                    'total': calcularTotal().toInt(),
                                    'estado': 'Pendiente',
                                  };

                                  setState(() {
                                    _ventas.insert(0, nuevaVenta);
                                  });

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Venta registrada como pendiente. Stock descontado.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
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
