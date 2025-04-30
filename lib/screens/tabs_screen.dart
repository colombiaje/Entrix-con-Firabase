import 'package:flutter/material.dart';
import 'package:entrix/screens/crear_prompt_widget.dart';
import 'package:entrix/screens/consulta_prompt_widget.dart';

import 'package:flutter/material.dart';

// Si tu pantalla principal ya existe y tiene otro nombre de clase,
// puedes usar ese nombre en lugar de TabsScreen, pero asegúrate
// de que el import en main.dart coincida.
class TabsScreen extends StatelessWidget {
  const TabsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Este es un placeholder para tu pantalla principal (ej. con BottomNavigationBar, Tabs, etc.)
    // En tu proyecto actual, esta pantalla probablemente ya contiene o
    // muestra los widgets consulta_prompt_widget.dart y crear_prompt_widget.dart
    return Scaffold(
      appBar: AppBar(title: const Text('App Principal')),
      body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Aquí irá el contenido principal de tu app.'),
              Text('(Como tus widgets de Consulta y Crear Prompt)')
            ],
          )
      ),
      // Aquí iría tu BottomNavigationBar u otra estructura de navegación si la tienes
    );
  }
}

class EntrixTabsScreen extends StatelessWidget {
  const EntrixTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrix'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Crear Prompt'),
              Tab(text: 'Consultar Prompts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PromptFormScreen(),
            PromptConsultaWidget(),
          ],
        ),
      ),
    );
  }
}
