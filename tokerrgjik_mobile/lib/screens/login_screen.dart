import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // true = login, false = signup
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = _isLoginMode
        ? await AuthService.login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          )
        : await AuthService.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      if (_isLoginMode) {
        // Login successful - navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Registration successful - show message and switch to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isLoginMode = true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Operation failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    await AuthService.loginAsGuest();
    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)], // Dark blue-grey to bright blue
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Title
                        const Icon(
                          Icons.grid_3x3,
                          size: 64,
                          color: Color(0xFF2C3E50), // Dark blue-grey
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tokerrgjik',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50), // Dark blue-grey
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode ? 'Mirë se vini!' : 'Krijo llogari',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Emri i përdoruesit',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ju lutem vendosni emrin e përdoruesit';
                            }
                            if (value.length < 3) {
                              return 'Emri duhet të jetë së paku 3 karaktere';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Full name field (signup only)
                        if (!_isLoginMode) ...[
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Emri i plotë',
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (!_isLoginMode && (value == null || value.isEmpty)) {
                                return 'Ju lutem vendosni emrin e plotë';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email field (signup only)
                        if (!_isLoginMode) ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (!_isLoginMode && (value == null || value.isEmpty)) {
                                return 'Ju lutem vendosni email';
                              }
                              if (!_isLoginMode && !value!.contains('@')) {
                                return 'Email i pavlefshëm';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Fjalëkalimi',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ju lutem vendosni fjalëkalimin';
                            }
                            if (!_isLoginMode && value.length < 6) {
                              return 'Fjalëkalimi duhet të jetë së paku 6 karaktere';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login/Signup button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF2C3E50), // Dark blue-grey
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Hyr' : 'Regjistrohu',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Toggle login/signup
                        TextButton(
                          onPressed: () {
                            setState(() => _isLoginMode = !_isLoginMode);
                          },
                          child: Text(
                            _isLoginMode
                                ? 'Nuk keni llogari? Regjistrohu këtu'
                                : 'Keni llogari? Hyr këtu',
                            style: const TextStyle(color: Color(0xFF2C3E50)), // Dark blue-grey
                          ),
                        ),

                        // Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OSE'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        // Guest login button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGuestLogin,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Vazhdo si vizitor'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}
