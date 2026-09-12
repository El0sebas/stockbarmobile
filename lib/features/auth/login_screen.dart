import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../main.dart';
import '../dashboard/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = true;
  bool _showPassword = false;

  final TextEditingController _emailController = TextEditingController(
    text: 'administrador@stockbar.com',
  );

  final TextEditingController _passController = TextEditingController(
    text: '123456',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIN
  // ==========================================

  void _iniciarSesion() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarMensaje('Completa el correo y la contraseña.', Colors.redAccent);
      return;
    }

    Map<String, dynamic>? usuario;

    for (final u in mockUsuarios) {
      if (u['correo'].toString().toLowerCase() == email &&
          u['password'].toString() == password) {
        usuario = u;
        break;
      }
    }

    if (usuario == null) {
      _mostrarMensaje('Credenciales inválidas.', Colors.redAccent);
      return;
    }

    if (usuario['estado'] != 'Activo') {
      _mostrarMensaje('Este usuario se encuentra inactivo.', Colors.redAccent);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainLayout(usuario: usuario!)),
    );
  }

  // ==========================================
  // RECUPERACIÓN
  // ==========================================

  void _mostrarRecuperacion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _RecoverySheet(),
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  children: [
                    // ==========================================
                    // BOTÓN DE TEMA
                    // ==========================================

                    Align(
                      alignment: Alignment.topRight,
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (_, mode, _) {
                          final dark = mode == ThemeMode.dark;

                          return Material(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                themeNotifier.value = dark
                                    ? ThemeMode.light
                                    : ThemeMode.dark;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      dark ? Icons.light_mode : Icons.dark_mode,
                                      size: 17,
                                      color: dark
                                          ? AppColors.actionAmber
                                          : AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      dark ? 'Claro' : 'Oscuro',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // LOGO
                    // ==========================================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _StockBarLogo(size: 34, isDark: isDark),
                          const SizedBox(width: 10),
                          const Text(
                            'StockBar',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 45),

                    // ==========================================
                    // TITULO
                    // ==========================================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '¡Bienvenido de vuelta!',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Inicia sesión para abrir tu turno en caja',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==========================================
                    // FORMULARIO
                    // ==========================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'usuario@stockbar.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _passController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              hintText: 'Introduce tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ==========================================
                          // RECORDAR + RECUPERAR
                          // ==========================================
                          LayoutBuilder(
                            builder: (context, box) {
                              if (box.maxWidth < 350) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _rememberWidget(),
                                    const SizedBox(height: 8),
                                    _recoveryButton(),
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _rememberWidget(),
                                  Flexible(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _recoveryButton(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _iniciarSesion,
                              child: const Text(
                                'Iniciar Turno',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // INFO
                    // ==========================================
                    Text(
                      'Gestión inteligente de inventario y punto de venta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _rememberWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 25,
          height: 25,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 5),
        const Text('Recordar usuario', style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _recoveryButton() {
    return TextButton(
      onPressed: _mostrarRecuperacion,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        '¿Olvidaste tu contraseña?',
        style: TextStyle(
          color: AppColors.actionAmber,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// LOGO
// ============================================================

class _StockBarLogo extends StatelessWidget {
  final double size;
  final bool isDark;

  const _StockBarLogo({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bar(
            width: size * .23,
            height: size * .55,
            color: AppColors.actionAmber,
          ),
          SizedBox(width: size * .08),
          _bar(
            width: size * .23,
            height: size * .75,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.primaryBlue,
          ),
          SizedBox(width: size * .08),
          _bar(width: size * .23, height: size, color: AppColors.logoBlue),
        ],
      ),
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ============================================================
// RECUPERACIÓN DE CONTRASEÑA
// ============================================================

class _RecoverySheet extends StatefulWidget {
  const _RecoverySheet();

  @override
  State<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<_RecoverySheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _tokenGenerated = false;
  String _token = '';
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _generarToken() {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        _message = 'Ingresa tu correo electrónico.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _message = 'Ingresa un correo válido.';
      });
      return;
    }

    _token =
        'SB-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    setState(() {
      _tokenGenerated = true;
      _tokenController.text = _token;
      _message = 'Se generó un token de recuperación para $email.';
    });
  }

  void _guardarNuevaPassword() {
    final token = _tokenController.text.trim();
    final password = _newPasswordController.text.trim();

    if (token.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Debes ingresar el token y la nueva contraseña.';
      });
      return;
    }

    if (token != _token) {
      setState(() {
        _message = 'El token no es válido.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _message = 'La contraseña debe tener mínimo 6 caracteres.';
      });
      return;
    }

    setState(() {
      _message =
          'Contraseña actualizada correctamente. Ya puedes iniciar sesión.';
      _tokenGenerated = false;
      _emailController.clear();
      _tokenController.clear();
      _newPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  const Icon(Icons.lock_reset, color: AppColors.actionAmber),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Recuperación de contraseña',
                      style: TextStyle(
                        fontSize: 19,
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

              const SizedBox(height: 8),

              Text(
                _tokenGenerated
                    ? 'Ingresa el token y establece una nueva contraseña.'
                    : 'Ingresa tu correo electrónico para recuperar el acceso.',
                style: TextStyle(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 22),

              if (!_tokenGenerated) ...[
                const Text(
                  'Correo electrónico',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'usuario@stockbar.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generarToken,
                    child: const Text(
                      'Generar token',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Token de recuperación',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Nueva contraseña',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardarNuevaPassword,
                    child: const Text(
                      'Guardar nueva contraseña',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              if (_message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: .25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
