import 'package:firebase_core/firebase_core.dart';
// Ya no necesitamos firebase_auth aquí temporalmente
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Importa tu pantalla principal real que contiene las pestañas
// Asegurate que la ruta y el nombre del archivo son correctos
import 'package:entrix/screens/tabs_screen.dart'; // Asumiendo que EntrixTabsScreen está en este archivo

// Ya no necesitamos importar la pantalla de login temporalmente
// import 'package:entrix/screens/login_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entrix', // Tu titulo
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tu tema
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 🔹 TEMPORALMENTE: Mostramos directamente tu pantalla principal con pestañas
      // para poder probar las funcionalidades de Prompts.
      // Volveremos a poner la lógica de autenticación del StreamBuilder después.
      home: EntrixTabsScreen(), // <-- Apunta directamente a tu Widget principal real
    );
  }
}

// Nota: Una vez que termines las pruebas, volveremos a modificar main.dart
// para usar la lógica de autenticación con StreamBuilder nuevamente.