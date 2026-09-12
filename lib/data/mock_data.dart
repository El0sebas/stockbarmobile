// Datos semilla compartidos entre pantallas (Login, Ventas, Dashboard).
// Mismo criterio que en la web: una sola fuente de datos por entidad, para
// que "Producto X" tenga el mismo stock/precio se use donde se use, en vez
// de que cada pantalla mantenga su propia copia desconectada.
//
// TODO: cuando exista el backend (Node/Express + MySQL), estas listas se
// reemplazan por llamadas a la API REST vía un repositorio (ver CLAUDE.md,
// regla 3: el frontend no es fuente de verdad).

String _fechaEnDias(int dias) =>
    DateTime.now().add(Duration(days: dias)).toIso8601String().split('T')[0];

final List<Map<String, dynamic>> mockUsuarios = [
  {
    'id': 1,
    'nombre': 'Carlos Andrés Gómez',
    'correo': 'administrador@stockbar.com',
    'password': '123456',
    'rol': 'Administrador',
    'estado': 'Activo',
  },
  {
    'id': 2,
    'nombre': 'Juan David Posso',
    'correo': 'auxiliar@stockbar.com',
    'password': '123456',
    'rol': 'Empleado Auxiliar',
    'estado': 'Activo',
  },
];

// Cada producto se rastrea por lote (igual que en la web): el stock real es
// la suma de lo disponible en sus lotes, y una venta descuenta primero del
// lote que vence antes (FEFO), no de un contador plano desconectado de eso.
// Un lote con 'fecha_vencimiento': null es un producto que no maneja
// vencimiento (ej. cigarrillos) — nunca se excluye por fecha, pero sigue
// teniendo un límite real de unidades disponibles.
final List<Map<String, dynamic>> mockProductos = [
  {
    'id': 1,
    'codigo': 'BEB-001',
    'nombre': 'Cerveza Aguila 330ml',
    'precio': 3500,
    'lotes': [
      // A propósito, dentro del rango de "por vencer" (ver
      // diasSugerenciaVencimiento), para que la sugerencia sea visible
      // siempre sin depender de una fecha fija que quede vieja con el tiempo.
      {
        'id_lote': 1,
        'numero_lote': 'L-2026-01',
        'fecha_vencimiento': _fechaEnDias(10),
        'cantidad_disponible': 20,
      },
      {
        'id_lote': 2,
        'numero_lote': 'L-2026-02',
        'fecha_vencimiento': _fechaEnDias(60),
        'cantidad_disponible': 25,
      },
    ],
  },
  {
    'id': 2,
    'codigo': 'LIC-002',
    'nombre': 'Aguardiente Antioqueño',
    'precio': 45000,
    'lotes': [
      {
        'id_lote': 3,
        'numero_lote': 'L-2026-03',
        'fecha_vencimiento': '2028-05-20',
        'cantidad_disponible': 12,
      },
    ],
  },
  {
    'id': 3,
    'codigo': 'TIB-003',
    'nombre': 'Cigarrillos Marlboro',
    'precio': 8000,
    'lotes': [
      {
        'id_lote': 4,
        'numero_lote': 'L-2025-12',
        'fecha_vencimiento': null,
        'cantidad_disponible': 5,
      },
    ],
  },
  {
    'id': 4,
    'codigo': 'LIC-004',
    'nombre': 'Whisky Old Parr',
    'precio': 190000,
    'lotes': [
      {
        'id_lote': 5,
        'numero_lote': 'L-2026-04',
        'fecha_vencimiento': '2030-01-01',
        'cantidad_disponible': 8,
      },
    ],
  },
];

// Historial de ventas, compartido entre VentasScreen (donde se registran) y
// el Dashboard (que calcula sus KPIs sobre estos mismos datos reales, en vez
// de mostrar cifras fijas desconectadas de lo que realmente se vendió).
final List<Map<String, dynamic>> mockVentas = [
  {
    'id': 1,
    'cliente': 'Cliente General',
    'metodo': 'Nequi',
    'total': 45000,
    'estado': 'Pendiente',
  },
  {
    'id': 2,
    'cliente': 'Juan David Posso',
    'metodo': 'Efectivo',
    'total': 16000,
    'estado': 'Listo',
  },
  {
    'id': 3,
    'cliente': 'Cliente General',
    'metodo': 'Bancolombia',
    'total': 35000,
    'estado': 'Pendiente',
  },
];

// Un producto se sugiere como "por vencer" si su fecha está a 15 días o
// menos; es solo una sugerencia visual (igual que en la web), nunca bloquea
// ni prioriza nada automáticamente.
const diasSugerenciaVencimiento = 15;

int? diasParaVencer(String? vencimiento) {
  if (vencimiento == null) return null;
  final fecha = DateTime.tryParse(vencimiento);
  if (fecha == null) return null;
  return fecha.difference(DateTime.now()).inDays;
}

// Lotes con unidades disponibles, ordenados por fecha de vencimiento
// ascendente (el que vence primero, primero) — los sin vencimiento van al
// final. Es la base tanto del stock total como del descuento FEFO al vender.
List<Map<String, dynamic>> lotesDisponibles(Map<String, dynamic> producto) {
  final lotes = (producto['lotes'] as List).cast<Map<String, dynamic>>();

  final disponibles = lotes.where((lote) {
    final cantidad = lote['cantidad_disponible'] as int;
    if (cantidad <= 0) return false;
    final vencimiento = lote['fecha_vencimiento'] as String?;
    if (vencimiento == null) return true;
    final fecha = DateTime.tryParse(vencimiento);
    return fecha == null || fecha.isAfter(DateTime.now());
  }).toList();

  disponibles.sort((a, b) {
    final fa = a['fecha_vencimiento'] as String?;
    final fb = b['fecha_vencimiento'] as String?;
    if (fa == null && fb == null) return 0;
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fa.compareTo(fb);
  });

  return disponibles;
}

// Stock real disponible de un producto: la suma de sus lotes vigentes, no un
// número plano que pueda desincronizarse de lo que hay lote por lote.
int stockDisponible(Map<String, dynamic> producto) => lotesDisponibles(producto)
    .fold<int>(0, (sum, lote) => sum + (lote['cantidad_disponible'] as int));

// El lote que antes vence, si está dentro del rango de sugerencia. Solo es
// una sugerencia visual (badge "Por vencer"), nunca bloquea ni prioriza nada
// automáticamente en el carrito.
Map<String, dynamic>? sugerenciaVencimiento(Map<String, dynamic> producto) {
  final lotes = lotesDisponibles(producto);
  if (lotes.isEmpty) return null;

  final proximo = lotes.first;
  final dias = diasParaVencer(proximo['fecha_vencimiento'] as String?);
  if (dias == null || dias > diasSugerenciaVencimiento) return null;

  return {...proximo, 'dias': dias};
}

// Descuenta stock del producto en orden FEFO (primero el lote que vence
// antes). Devuelve false y no toca nada si no hay stock suficiente.
bool descontarStock(Map<String, dynamic> producto, int cantidad) {
  final disponibles = lotesDisponibles(producto);
  final totalDisponible = disponibles.fold<int>(
    0,
    (sum, lote) => sum + (lote['cantidad_disponible'] as int),
  );
  if (totalDisponible < cantidad) return false;

  var restante = cantidad;
  for (final lote in disponibles) {
    if (restante <= 0) break;
    final disponible = lote['cantidad_disponible'] as int;
    final tomar = restante < disponible ? restante : disponible;
    lote['cantidad_disponible'] = disponible - tomar;
    restante -= tomar;
  }
  return true;
}
