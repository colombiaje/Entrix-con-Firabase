import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔹 Asegura que este import este presente
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Importa tus pantallas. Asegurate que las rutas y nombres son correctos.
import 'package:entrix/screens/login_page.dart'; // 🔹 Asegura que este import este presente
import 'package:entrix/screens/tabs_screen.dart'; // Asumiendo que EntrixTabsScreen está en este archivo


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
      // 🔹 Restauramos el StreamBuilder para escuchar cambios en el estado de autenticación
      home: StreamBuilder<User?>( // User? viene de firebase_auth
        stream: FirebaseAuth.instance.authStateChanges(), // Este stream emite eventos cuando el usuario inicia/cierra sesión
        builder: (context, snapshot) {
          // Verifica si la conexión al stream tiene datos (estado de auth)
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un indicador de carga mientras espera el estado de auth
            return const CircularProgressIndicator(); // 🔹 Añadimos const
          }

          // Si el stream tiene datos y hay un usuario (snapshot.hasData es true y snapshot.data no es null)
          if (snapshot.hasData && snapshot.data != null) {
            // El usuario está logueado, muestra la pantalla principal (ej. Tabs)
            return const EntrixTabsScreen(); // 🔹 Restauramos y aseguramos que apunta a tu Widget principal real
          } else {
            // El usuario NO está logueado, muestra la pantalla de inicio de sesión
            return const LoginPage(); // 🔹 Restauramos y aseguramos que apunta a tu Widget de login
          }
        },
      ),
      // La línea temporal home: EntrixTabsScreen(),; ha sido eliminada
    );
  }
}