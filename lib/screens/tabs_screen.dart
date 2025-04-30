import 'package:flutter/material.dart';
import 'package:entrix/screens/crear_prompt_widget.dart';
import 'package:entrix/screens/consulta_prompt_widget.dart';

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
