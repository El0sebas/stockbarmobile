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
    'requiereEdad': true,
    'porcentajeIva': 19,
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
    'requiereEdad': true,
    'porcentajeIva': 5,
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
    'requiereEdad': true,
    'porcentajeIva': 19,
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
    'requiereEdad': true,
    'porcentajeIva': 5,
    'lotes': [
      {
        'id_lote': 5,
        'numero_lote': 'L-2026-04',
        'fecha_vencimiento': '2030-01-01',
        'cantidad_disponible': 8,
      },
    ],
  },
  {
    'id': 5,
    'codigo': 'SNK-005',
    'nombre': 'Papas Margarita',
    'precio': 3000,
    'requiereEdad': false,
    'porcentajeIva': 19,
    'lotes': [
      {
        'id_lote': 6,
        'numero_lote': 'L-2026-05',
        'fecha_vencimiento': _fechaEnDias(180),
        'cantidad_disponible': 40,
      },
    ],
  },
];

// Espejo de utils/impuestos.js (web): 'precio' ya incluye el IVA (igual que
// en el mostrador real), así que la base gravable se obtiene descontando la
// tasa por línea, nunca sumando el IVA aparte.
Map<String, num> calcularTotalesVenta(List<Map<String, dynamic>> items) {
  num base = 0, iva = 0, total = 0;
  for (final item in items) {
    final totalLinea = (item['precio'] as num) * (item['cantidad'] as num);
    final tasa = (item['porcentajeIva'] as num?) ?? 0;
    final baseLinea = totalLinea / (1 + tasa / 100);
    base += baseLinea;
    iva += totalLinea - baseLinea;
    total += totalLinea;
  }
  return {'baseGravable': base, 'iva': iva, 'total': total};
}

// Compara solo el día (ignora la hora), para el filtro por rango de fechas
// de VentasScreen y JornadaScreen.
bool estaEnRangoFecha(DateTime? fecha, DateTime? desde, DateTime? hasta) {
  if (fecha == null) return true;
  final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
  if (desde != null &&
      soloFecha.isBefore(DateTime(desde.year, desde.month, desde.day))) {
    return false;
  }
  if (hasta != null &&
      soloFecha.isAfter(DateTime(hasta.year, hasta.month, hasta.day))) {
    return false;
  }
  return true;
}

// Formato de fecha compartido (JornadaScreen, detalle de venta): sin
// intl, el proyecto no lo necesita para un solo formato fijo dd/mm/aaaa hh:mm.
String formatearFecha(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}';
}

// Métodos de pago activos, compartido con VentasScreen (una venta puede
// combinar más de uno — pago por partes — igual que en la web).
const List<String> mockMetodosPago = [
  'Efectivo',
  'Nequi',
  'Bancolombia',
  'Transferencia',
  'Tarjeta',
];

// Clientes, compartido con VentasScreen: la verificación de edad depende de
// 'fecha_nacimiento', no del nombre. 'Cliente General' (sin documento ni
// fecha de nacimiento) es el cliente de mostrador y nunca exige verificación
// de edad (se confía en la verificación visual del cajero), igual que en la
// web (ver utils/edad.js).
final List<Map<String, dynamic>> mockClientes = [
  {'id_cliente': 0, 'nombre': 'Cliente General', 'fecha_nacimiento': null},
  {'id_cliente': 1, 'nombre': 'Andrés Pérez', 'fecha_nacimiento': '1990-05-12'},
  {'id_cliente': 2, 'nombre': 'Laura Gómez', 'fecha_nacimiento': '2008-11-03'},
  {
    'id_cliente': 3,
    'nombre': 'Santiago Ríos',
    'fecha_nacimiento': '1985-02-20',
  },
];

// Espejo de utils/edad.js (web): edad por fecha exacta, no por año calendario.
int? edadCliente(String? fechaNacimiento) {
  if (fechaNacimiento == null) return null;
  final nacimiento = DateTime.tryParse(fechaNacimiento);
  if (nacimiento == null) return null;
  final hoy = DateTime.now();
  var edad = hoy.year - nacimiento.year;
  final aunNoCumpleEsteAno =
      hoy.month < nacimiento.month ||
      (hoy.month == nacimiento.month && hoy.day < nacimiento.day);
  if (aunNoCumpleEsteAno) edad -= 1;
  return edad;
}

const edadMinima = 18;

// Espejo de validarEdadCliente (web): 'Cliente General' (id 0) nunca exige
// verificación; un cliente registrado sí necesita fecha de nacimiento y ser
// mayor de edad para llevar productos +18.
String? validarEdadCliente(Map<String, dynamic>? cliente) {
  if (cliente == null || cliente['id_cliente'] == 0) return null;
  final fecha = cliente['fecha_nacimiento'] as String?;
  if (fecha == null) {
    return 'El cliente no tiene fecha de nacimiento válida para comprar productos con verificación de edad.';
  }
  final edad = edadCliente(fecha);
  if (edad == null || edad < edadMinima) {
    return 'El cliente no cumple la edad mínima de 18 años.';
  }
  return null;
}

// Historial de ventas, compartido entre VentasScreen (donde se registran) y
// el Dashboard (que calcula sus KPIs sobre estos mismos datos reales, en vez
// de mostrar cifras fijas desconectadas de lo que realmente se vendió).
final List<Map<String, dynamic>> mockVentas = [
  {
    'id': 1,
    'cliente': 'Cliente General',
    'fecha_hora_venta': DateTime.now().subtract(const Duration(hours: 2)),
    'productos': [
      {
        'nombre': 'Aguardiente Antioqueño',
        'cantidad': 1,
        'precio': 45000,
        'porcentajeIva': 5,
        'lote': 'L-2026-03',
      },
    ],
    'pagos': [
      {'metodo': 'Nequi', 'monto': 45000},
    ],
    'total': 45000,
    'estado': 'Pendiente',
  },
  {
    'id': 2,
    'cliente': 'Andrés Pérez',
    'fecha_hora_venta': DateTime.now().subtract(const Duration(hours: 5)),
    'productos': [
      {
        'nombre': 'Cerveza Aguila 330ml',
        'cantidad': 2,
        'precio': 3500,
        'porcentajeIva': 19,
        'lote': 'L-2026-01',
      },
      {
        'nombre': 'Papas Margarita',
        'cantidad': 3,
        'precio': 3000,
        'porcentajeIva': 19,
        'lote': 'L-2026-05',
      },
    ],
    // Ejemplo de pago por partes: dos métodos suman el total de la venta.
    'pagos': [
      {'metodo': 'Efectivo', 'monto': 10000},
      {'metodo': 'Nequi', 'monto': 6000},
    ],
    'total': 16000,
    'estado': 'Listo',
  },
  {
    'id': 3,
    'cliente': 'Cliente General',
    'fecha_hora_venta': DateTime.now().subtract(const Duration(days: 1)),
    'productos': [
      {
        'nombre': 'Cerveza Aguila 330ml',
        'cantidad': 10,
        'precio': 3500,
        'porcentajeIva': 19,
        'lote': 'L-2026-01',
      },
    ],
    'pagos': [
      {'metodo': 'Bancolombia', 'monto': 35000},
    ],
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

// Historial de jornadas (apertura/cierre de caja), igual que en la web
// (ver defaultJornadas.js): solo puede haber una jornada 'ABIERTA' a la vez.
final List<Map<String, dynamic>> mockJornadas = [];

Map<String, dynamic>? jornadaAbierta() {
  for (final j in mockJornadas) {
    if (j['estado'] == 'ABIERTA') return j;
  }
  return null;
}

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
