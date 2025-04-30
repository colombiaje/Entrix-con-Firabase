import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Este es solo un placeholder. Eventualmente tendra tu UI de Login.
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: const Center(
        child: Text('Aquí irá la pantalla de Login'),
      ),
    );
  }
}