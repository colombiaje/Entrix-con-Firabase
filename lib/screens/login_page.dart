import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth
import 'package:flutter/foundation.dart'; // Para kDebugMode y debugPrint

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // Para mostrar un indicador de carga

  // 🔹 Función para mostrar mensajes al usuario
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 🔹 Función para manejar el registro de nuevo usuario
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Si el registro es exitoso, el StreamBuilder en main.dart
      // detectará el cambio de estado de autenticación y navegará automáticamente.
      if (kDebugMode) {
        debugPrint('Usuario registrado: ${userCredential.user!.email}');
      }
      _showMessage('Usuario registrado con éxito.');
      // No necesitas navegar manualmente, main.dart lo hará.

    } on FirebaseAuthException catch (e) {
      if (kDebugMode) { debugPrint('Error de registro: ${e.code}'); }
      if (e.code == 'weak-password') {
        _showMessage('La contraseña es demasiado débil.');
      } else if (e.code == 'email-already-in-use') {
        _showMessage('La cuenta para ese email ya existe.');
      } else {
        _showMessage('Error al registrar: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) { debugPrint('Error inesperado al registrar: $e'); }
      _showMessage('Ocurrió un error: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 🔹 Función para manejar el inicio de sesión
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Si el login es exitoso, el StreamBuilder en main.dart
      // detectará el cambio de estado de autenticación y navegará automáticamente.
      if (kDebugMode) {
        debugPrint('Usuario logueado: ${userCredential.user!.email}');
      }
      _showMessage('Inicio de sesión exitoso.');
      // No necesitas navegar manualmente, main.dart lo hará.

    } on FirebaseAuthException catch (e) {
      if (kDebugMode) { debugPrint('Error de login: ${e.code}'); }
      if (e.code == 'user-not-found') {
        _showMessage('No se encontró usuario con ese email.');
      } else if (e.code == 'wrong-password') {
        _showMessage('Contraseña incorrecta.');
      } else {
        _showMessage('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) { debugPrint('Error inesperado al iniciar sesión: $e'); }
      _showMessage('Ocurrió un error: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    // Limpiar controladores al desechar el widget
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Center( // Centramos el contenido del formulario
        child: SingleChildScrollView( // Permite hacer scroll si el teclado cubre los campos
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centra la columna verticalmente
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los elementos horizontalmente
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    // Opcional: añadir validacion de formato de email
                    if (!value.contains('@')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // Oculta el texto para contraseñas
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                _isLoading // Muestra indicador de carga si está cargando
                    ? const Center(child: CircularProgressIndicator())
                    : Column( // Contenedor para los botones si no está cargando
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _login, // Llama a la función de login
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Iniciar Sesión'),
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton(
                      onPressed: _signup, // Llama a la función de registro
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Registrarse'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}