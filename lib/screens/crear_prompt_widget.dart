import 'package:flutter/material.dart';
import '../services/appscript_service.dart';

class PromptFormScreen extends StatefulWidget {
  const PromptFormScreen({super.key});

  @override
  State<PromptFormScreen> createState() => _PromptFormScreenState();
}

class _PromptFormScreenState extends State<PromptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _contextoSeleccionado;
  String? _propositoSeleccionado;
  String? _nuevoContexto;
  String? _nuevoProposito;
  String _promptTexto = '';
  Map<String, List<String>> mapaContextoProposito = {};
  List<String> contextos = [];
  List<String> propositosFiltrados = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final opciones = await obtenerOpcionesUnicasAgrupadas();
    setState(() {
      mapaContextoProposito = opciones;
      contextos = ['CREAR_NUEVO', ...opciones.keys.toList()..sort()];
      isLoading = false;

      if (_contextoSeleccionado != null &&
          mapaContextoProposito.containsKey(_contextoSeleccionado!)) {
        actualizarPropositos(_contextoSeleccionado!);
      }
    });
  }

  void actualizarPropositos(String contexto) {
    final lista = mapaContextoProposito[contexto] ?? [];
    setState(() {
      propositosFiltrados = ['CREAR_NUEVO', ...lista.toList()..sort()];
      _propositoSeleccionado = null;
    });
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final contextoFinal = _contextoSeleccionado == 'CREAR_NUEVO'
        ? _nuevoContexto?.trim() ?? ''
        : _contextoSeleccionado ?? '';

    final propositoFinal = _propositoSeleccionado == 'CREAR_NUEVO'
        ? _nuevoProposito?.trim() ?? ''
        : _propositoSeleccionado ?? '';

    final respuesta = await enviarPrompt(
      contextoUso: contextoFinal,
      propositoUso: propositoFinal,
      promptTexto: _promptTexto.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(respuesta)),
    );

    _formKey.currentState!.reset();
    setState(() {
      _contextoSeleccionado = null;
      _propositoSeleccionado = null;
      _nuevoContexto = null;
      _nuevoProposito = null;
      _promptTexto = '';
    });

    await cargarDatos();
  }

  Color _getColorByEstado(String? valor) {
    if (valor == null || valor.isEmpty) return Colors.red[100]!;
    if (valor.length > 2) return Colors.green[100]!;
    return Colors.yellow[100]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear nuevo Prompt')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Contexto de uso',
                  filled: true,
                  fillColor: _getColorByEstado(_contextoSeleccionado),
                ),
                value: _contextoSeleccionado,
                items: contextos.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: c == 'CREAR_NUEVO'
                        ? const Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text('➕ Crear nuevo contexto'),
                      ],
                    )
                        : RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: c.split(' ').first + ' ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          TextSpan(text: c.substring(c.split(' ').first.length)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _contextoSeleccionado = value;
                    _nuevoContexto = null;
                    if (value != null && value != 'CREAR_NUEVO') {
                      actualizarPropositos(value);
                    } else {
                      propositosFiltrados = ['CREAR_NUEVO'];
                    }
                    _propositoSeleccionado = null;
                    _nuevoProposito = null;
                  });
                },
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Selecciona un contexto' : null,
              ),
              if (_contextoSeleccionado == 'CREAR_NUEVO')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nuevo contexto'),
                  onSaved: (value) => _nuevoContexto = value,
                  validator: (value) {
                    if (_contextoSeleccionado == 'CREAR_NUEVO' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa un nuevo contexto';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Propósito de uso',
                  filled: true,
                  fillColor: _getColorByEstado(_propositoSeleccionado),
                ),
                value: _propositoSeleccionado,
                items: propositosFiltrados.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: p == 'CREAR_NUEVO'
                        ? const Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('➕ Crear nuevo propósito'),
                      ],
                    )
                        : RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: p.split(' ').first + ' ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          TextSpan(text: p.substring(p.split(' ').first.length)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _propositoSeleccionado = value;
                    _nuevoProposito = null;
                  });
                },
                validator: (value) =>
                value == null ? 'Selecciona un propósito' : null,
              ),
              if (_propositoSeleccionado == 'CREAR_NUEVO')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nuevo propósito'),
                  onSaved: (value) => _nuevoProposito = value,
                  validator: (value) {
                    if (_propositoSeleccionado == 'CREAR_NUEVO' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa un nuevo propósito';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Texto del prompt'),
                maxLines: 3,
                onSaved: (value) => _promptTexto = value ?? '',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa un prompt'
                    : null,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _contextoSeleccionado != null &&
                    _propositoSeleccionado != null &&
                    _contextoSeleccionado!.length > 2 &&
                    _propositoSeleccionado!.length > 2
                    ? _enviarFormulario
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _getColorByEstado(_contextoSeleccionado),
                  ),
                ),
                child: const Text('Guardar Prompt'),
              ),
              const SizedBox(height: 30),
              // PromptConsultaWidget() eliminado visualmente
            ],
          ),
        ),
      ),
    );
  }
}
