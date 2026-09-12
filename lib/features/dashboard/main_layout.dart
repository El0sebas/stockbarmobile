import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
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

  List<Widget> get _screens {
    if (esAdministrador) {
      return const [HomeScreen(), VentasScreen()];
    }

    return const [VentasScreen()];
  }

  void _mostrarMenuPerfil() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                // ==========================================
                // PERFIL
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.actionAmber,
                        child: Text(
                          _iniciales(widget.usuario['nombre'].toString()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.usuario['nombre'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.usuario['correo'].toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.actionAmber.withValues(
                                  alpha: .12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.usuario['rol'].toString(),
                                style: const TextStyle(
                                  color: AppColors.actionAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(),

                // ==========================================
                // TEMA
                // ==========================================
                ListTile(
                  leading: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.actionAmber,
                  ),
                  title: Text(
                    isDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
                  ),
                  subtitle: const Text(
                    'Personalizar apariencia',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    themeNotifier.value = isDark
                        ? ThemeMode.light
                        : ThemeMode.dark;

                    Navigator.pop(sheetContext);
                  },
                ),

                // ==========================================
                // CERRAR SESIÓN
                // ==========================================
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');

    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }

    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StockBar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _mostrarMenuPerfil,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.actionAmber,
                child: Text(
                  _iniciales(widget.usuario['nombre'].toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: _screens[_currentIndex],

      // El Empleado Auxiliar solo tiene Ventas (ver CLAUDE.md, alcance
      // móvil); con una sola pantalla no tiene sentido mostrar navegación.
      bottomNavigationBar: _screens.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  activeIcon: Icon(Icons.shopping_cart),
                  label: 'Ventas',
                ),
              ],
            )
          : null,
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

    return ListView(
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

        _buildStatCard(
          context,
          'Ingresos (ventas completadas)',
          '\$$ingresos COP',
          '${mockVentas.length} ventas',
          AppColors.success,
          Icons.trending_up,
        ),

        const SizedBox(height: 12),

        _buildStatCard(
          context,
          'Stock Crítico',
          '$stockCritico artículos',
          '≤ 5 un.',
          AppColors.danger,
          Icons.warning_amber,
        ),

        const SizedBox(height: 12),

        _buildStatCard(
          context,
          'Ventas Pendientes',
          '$ventasPendientes ventas',
          'Por completar',
          AppColors.actionAmber,
          Icons.point_of_sale,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String badge,
    Color badgeColor,
    IconData icon,
  ) {
    return Container(
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
      child: Row(
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

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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
    );
  }
}
