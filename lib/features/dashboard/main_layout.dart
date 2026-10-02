import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../jornada/jornada_screen.dart';
import '../perfil/perfil_screen.dart';
import '../ventas/ventas_screen.dart';

class MainLayout extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const MainLayout({super.key, required this.usuario});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  bool get esAdministrador => widget.usuario['rol'] == 'Administrador';

  // El Administrador ve el negocio completo (Dashboard general); el Empleado
  // Auxiliar ve su propio resumen de ventas en la jornada actual, nunca las
  // cifras de todo el negocio (ver EmpleadoDashboardScreen).
  List<Widget> get _screens {
    return [
      esAdministrador
          ? const HomeScreen()
          : EmpleadoDashboardScreen(usuario: widget.usuario),
      VentasScreen(usuario: widget.usuario),
      JornadaScreen(usuario: widget.usuario),
      PerfilScreen(usuario: widget.usuario),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'Ventas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.door_front_door_outlined),
        activeIcon: Icon(Icons.door_front_door),
        label: 'Jornada',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mismo criterio que el Dashboard web: nada de cifras inventadas, todo
    // se calcula sobre los mismos datos que ya administran Ventas y Stock
    // (ver lib/data/mock_data.dart).
    final ingresos = mockVentas
        .where((v) => v['estado'] == 'Listo')
        .fold<int>(0, (sum, v) => sum + (v['total'] as int));

    final ventasPendientes = mockVentas
        .where((v) => v['estado'] == 'Pendiente')
        .length;

    final stockCritico = mockProductos
        .where((p) => stockDisponible(p) <= 5)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Resumen del Negocio',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          const Text(
            'Monitoreo de ingresos y stock en tiempo real',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),

          const SizedBox(height: 20),

          _dashboardStatCard(
            context,
            'Ingresos (ventas completadas)',
            '\$$ingresos COP',
            '${mockVentas.length} ventas',
            AppColors.success,
            Icons.trending_up,
          ),

          const SizedBox(height: 12),

          _dashboardStatCard(
            context,
            'Stock Crítico',
            '$stockCritico artículos',
            '≤ 5 un.',
            AppColors.danger,
            Icons.warning_amber,
          ),

          const SizedBox(height: 12),

          _dashboardStatCard(
            context,
            'Ventas Pendientes',
            '$ventasPendientes ventas',
            'Por completar',
            AppColors.actionAmber,
            Icons.point_of_sale,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD DEL EMPLEADO AUXILIAR
// ============================================================

// El Empleado Auxiliar nunca ve las cifras de todo el negocio (eso es
// exclusivo de Administrador, ver CLAUDE.md subproceso 10): solo un resumen
// de SUS PROPIAS ventas dentro de la jornada que está abierta ahora mismo.
class EmpleadoDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const EmpleadoDashboardScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final abierta = jornadaAbierta();

    final misVentas = abierta == null
        ? const <Map<String, dynamic>>[]
        : mockVentas
              .where(
                (v) =>
                    v['usuario'] == usuario['nombre'] &&
                    v['id_jornada'] == abierta['id_jornada'],
              )
              .toList();

    final totalVendido = misVentas
        .where((v) => v['estado'] == 'Listo')
        .fold<int>(0, (sum, v) => sum + (v['total'] as int));

    final pendientes = misVentas
        .where((v) => v['estado'] == 'Pendiente')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi resumen')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Hola, ${usuario['nombre']}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tus ventas en la jornada actual',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          if (abierta == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: .25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No hay jornada abierta. Ábrela desde la pestaña "Jornada" para empezar a vender.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _dashboardStatCard(
              context,
              'Vendido (completadas)',
              '\$$totalVendido COP',
              '${misVentas.length} ventas',
              AppColors.success,
              Icons.trending_up,
            ),
            const SizedBox(height: 12),
            _dashboardStatCard(
              context,
              'Ventas Pendientes',
              '$pendientes ventas',
              'Por completar',
              AppColors.actionAmber,
              Icons.point_of_sale,
            ),
          ],
        ],
      ),
    );
  }
}

// Tarjeta de KPI compartida por el Dashboard general y el del Empleado
// Auxiliar. Icono y badge quedan en una fila propia arriba, ancho fijo cada
// uno (44x44 / auto), así que las tarjetas alinean igual sin importar qué
// tan largo sea el valor o el título de cada una.
Widget _dashboardStatCard(
  BuildContext context,
  String title,
  String value,
  String badge,
  Color badgeColor,
  IconData icon,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryBlue),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}
