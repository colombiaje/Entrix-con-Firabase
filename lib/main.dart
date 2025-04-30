import 'package:flutter/material.dart';
import 'screens/tabs_screen.dart'; // asegúrate de que el import sea correcto

void main() {
  runApp(const EntrixApp());
}

class EntrixApp extends StatelessWidget {
  const EntrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entrix',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: EntrixTabsScreen(),
    );
  }
}
