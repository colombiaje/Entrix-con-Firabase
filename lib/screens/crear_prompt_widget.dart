import 'package:flutter/material.dart';
import '../services/appscript_service.dart'; // Importa la versión Firestore del servicio
import 'package:flutter/foundation.dart'; // Importar para debugPrint si no está ya

class PromptFormScreen extends StatefulWidget {
  const PromptFormScreen({super.key});

  @override
  State<PromptFormScreen> createState() => _PromptFormScreenState();
}

class _PromptFormScreenState extends State<PromptFormScreen> {
  // 🔹 Crea una instancia de tu servicio
  final AppscriptService _appscriptService = AppscriptService();

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
  bool isSending = false; // Estado para mostrar carga al enviar

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() { isLoading = true; }); // Mostrar carga al inicio

    try {
      // 🔹 Llama al método a través de la instancia del servicio
      final opciones = await _appscriptService.obtenerOpcionesUnicasAgrupadas();
      setState(() {
        mapaContextoProposito = opciones;
        // Asegurarse de que las keys de opciones no son null antes de toList()
        contextos = ['CREAR_NUEVO', ...opciones.keys.where((k) => k != null).cast<String>().toList()..sort()];

        if (_contextoSeleccionado != null &&
            mapaContextoProposito.containsKey(_contextoSeleccionado!)) {
          actualizarPropositos(_contextoSeleccionado!);
        }
        isLoading = false; // Ocultar carga
      });
    } catch (e) {
      setState(() { isLoading = false; }); // Ocultar carga
      if (kDebugMode) { debugPrint('Error cargando datos para formulario: $e'); }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar opciones: $e')),
      );
    }
  }

  void actualizarPropositos(String contexto) {
    // Asegurarse de que contexto existe en el mapa y la lista no es null antes de acceder
    final lista = mapaContextoProposito.containsKey(contexto) ? (mapaContextoProposito[contexto] ?? []) : [];
    setState(() {
      // Asegurarse de que los elementos de la lista no son null antes de toList()
      propositosFiltrados = ['CREAR_NUEVO', ...lista.where((p) => p != null).cast<String>().toList()..sort()];
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

    // Validaciones adicionales para nuevos campos
    if ((_contextoSeleccionado == 'CREAR_NUEVO' && contextoFinal.isEmpty) ||
        (_propositoSeleccionado == 'CREAR_NUEVO' && propositoFinal.isEmpty) ||
        _promptTexto.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos.')),
      );
      return; // Detiene la ejecución si las validaciones fallan
    }


    setState(() { isSending = true; }); // Mostrar carga al enviar

    try {
      // 🔹 Llama al método a través de la instancia del servicio
      // Ahora devuelve Future<void>, no una String de respuesta directa
      await _appscriptService.enviarPrompt(
        contextoUso: contextoFinal,
        propositoUso: propositoFinal,
        promptTexto: _promptTexto.trim(),
      );

      setState(() { isSending = false; }); // Ocultar carga

      // Si llegamos aquí, significa que await completar sin lanzar excepción
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt guardado exitosamente en Firebase.')),
      );
//21
      // ... código antes de await ...

      await _appscriptService.enviarPrompt(
        contextoUso: contextoFinal,
        propositoUso: propositoFinal,
        promptTexto: _promptTexto.trim(),
      );

// 🔹 Añade este print
      if (kDebugMode) { debugPrint('DEBUG Form: Envio a servicio completado. Intentando mostrar SnackBar...'); }

      // 🔹 Añade este print
      if (kDebugMode) { debugPrint('DEBUG Form: SnackBar mostrado (o intentado). Intentando resetear formulario...'); }


      _formKey.currentState!.reset(); // <--- Linea 2 sospechosa


      // 🔹 Añade este print
      if (kDebugMode) { debugPrint('DEBUG Form: Formulario reseteado. Intentando actualizar estado local...'); }

      setState(() { // <--- Linea 3 sospechosa
        _contextoSeleccionado = null;
        _propositoSeleccionado = null;
        _nuevoContexto = null;
        _nuevoProposito = null;
        _promptTexto = '';
        propositosFiltrados = [];
      });

      // 🔹 Añade este print
      if (kDebugMode) { debugPrint('DEBUG Form: Estado local actualizado.'); }

      //22

      // await cargarDatos(); // Recargar opciones si el nuevo contexto/proposito debe aparecer en los dropdowns inmediatamente
      // Nota: Recargar puede ser lento si tienes muchos datos. Considera solo limpiar formulario.

    } catch (e) {
      setState(() { isSending = false; }); // Ocultar carga
      if (kDebugMode) { debugPrint('Error al enviar prompt a Firebase: $e'); }
      // Si el servicio lanza una excepción, la capturamos aquí
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar prompt: $e')),
      );
    }
  }

  // Mantén esta función de color si la usas
  Color _getColorByEstado(String? valor) {
    if (valor == null || valor.isEmpty) return Colors.red[100]!;
    if (valor.length > 2) return Colors.green[100]!; // Asumo que cualquier texto válido tiene más de 2 caracteres
    return Colors.yellow[100]!; // Este caso puede ser para valores intermedios o invalidos antes de validar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear nuevo Prompt')),
      body: isLoading || isSending // Mostrar carga si está cargando datos o enviando formulario
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... Resto de tus DropdownButtonFormField y TextFormField ...
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Contexto de uso',
                  filled: true,
                  fillColor: _getColorByEstado(_contextoSeleccionado),
                ),
                value: _contextoSeleccionado,
                items: contextos.map((c) {
                  // Asegurarse de que c no es null o vacío antes de split
                  final parts = c.split(' ');
                  final primeraPalabra = parts.isNotEmpty ? parts.first : c;
                  final resto = parts.length > 1 ? parts.sublist(1).join(' ') : '';
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
                            text: '$primeraPalabra ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          TextSpan(text: resto),
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
                //1
        TextFormField(
                decoration: const InputDecoration(labelText: 'Nuevo contexto'),
                onSaved: (value) => _nuevoContexto = value, // Puedes dejar onSaved si lo usas para algo más, pero onChanged es clave aquí
                onChanged: (value) { // 🔹 Añade esto
                setState(() {
                _nuevoContexto = value; // 🔹 Actualiza el estado en tiempo real
                });
                },
          // ... resto de propiedades ...

    //21
                  validator: (value) {
                    if (_contextoSeleccionado == 'CREAR_NUEVO' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa un nuevo contexto';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              //22
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Propósito de uso',
                  filled: true,
                  fillColor: _getColorByEstado(_propositoSeleccionado),
                ),
                value: _propositoSeleccionado,
                items: propositosFiltrados.map((p) {
                  // Asegurarse de que p no es null o vacío antes de split
                  final parts = p.split(' ');
                  final primeraPalabra = parts.isNotEmpty ? parts.first : p;
                  final resto = parts.length > 1 ? parts.sublist(1).join(' ') : '';

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
                            text: '$primeraPalabra ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          TextSpan(text: resto),
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
                //21
    TextFormField(
    decoration: const InputDecoration(labelText: 'Nuevo propósito'),
    onSaved: (value) => _nuevoProposito = value, // Puedes dejar onSaved
    onChanged: (value) { // 🔹 Añade esto
    setState(() {
    _nuevoProposito = value; // 🔹 Actualiza el estado en tiempo real
    });
    },
    // ... resto de propiedades ...


                  //22

                  validator: (value) {
                    if (_propositoSeleccionado == 'CREAR_NUEVO' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Ingresa un nuevo propósito';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),

              //31

              TextFormField(
                decoration: const InputDecoration(labelText: 'Texto del prompt'),
                maxLines: 3,
                onSaved: (value) => _promptTexto = value ?? '',
                onChanged: (value) { // 🔹 Este es el onChanged correcto
                  setState(() {
                    _promptTexto = value ?? ''; // 🔹 Actualiza el estado en tiempo real
                  });
                },
                validator: (value) => value == null || value.trim().isEmpty // 🔹 validator aparece una sola vez
                    ? 'Ingresa un prompt'
                    : null,
                style: const TextStyle( // 🔹 style aparece una sola vez
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ), // 🔹 Aquí termina el TextFormField
              const SizedBox(height: 30), // Este SizedBox viene DESPUÉS del TextFormField

// ... El resto del código (ElevatedButton, etc.) ...
              ElevatedButton(
                // ...
                // Deshabilitar el botón mientras se envía o no hay valores válidos

                //1
                onPressed: isSending || _contextoSeleccionado == null || _propositoSeleccionado == null
                    || (_contextoSeleccionado == 'CREAR_NUEVO' && (_nuevoContexto == null || _nuevoContexto!.trim().isEmpty))
                    || (_propositoSeleccionado == 'CREAR_NUEVO' && (_nuevoProposito == null || _nuevoProposito!.trim().isEmpty))
                    || _promptTexto.trim().isEmpty
                    ? () { // 🔹 Añadimos un callback temporal para debugPrint cuando está deshabilitado
                  if (kDebugMode) {
                    debugPrint('DEBUG: Botón Guardar deshabilitado.');
                    debugPrint('  isSending: $isSending');
                    debugPrint('  _contextoSeleccionado: $_contextoSeleccionado');
                    debugPrint('  _propositoSeleccionado: $_propositoSeleccionado');
                    debugPrint('  _nuevoContexto (si aplica): $_nuevoContexto');
                    debugPrint('  _nuevoProposito (si aplica): $_nuevoProposito');
                    debugPrint('  _promptTexto: $_promptTexto');
                    debugPrint('  _promptTexto.trim().isEmpty: ${_promptTexto.trim().isEmpty}');
                    // 🔹 Opcional: Imprimir el resultado de cada parte de la condición booleana
                    debugPrint('  Condicion 1 (isSending): $isSending');
                    debugPrint('  Condicion 2 (contexto null): ${_contextoSeleccionado == null}');
                    debugPrint('  Condicion 3 (proposito null): ${_propositoSeleccionado == null}');
                    debugPrint('  Condicion 4 (contexto nuevo vacio): ${(_contextoSeleccionado == 'CREAR_NUEVO' && (_nuevoContexto == null || _nuevoContexto!.trim().isEmpty))}');
                    debugPrint('  Condicion 5 (proposito nuevo vacio): ${(_propositoSeleccionado == 'CREAR_NUEVO' && (_nuevoProposito == null || _nuevoProposito!.trim().isEmpty))}');
                    debugPrint('  Condicion 6 (prompt texto vacio): ${_promptTexto.trim().isEmpty}');

                    // Para ver si se cumplen las condiciones individuales que causan el null
                    // Por ejemplo, si Condicion 2 es true, el boton estara deshabilitado.
                  }
                } // 🔹 Fin del callback temporal
                    : _enviarFormulario, // 🔹 Este se ejecuta si TODAS las condiciones de arriba son falsas
                //2

                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey; // Color gris si está deshabilitado
                      }
                      // Color basado en el estado del contexto seleccionado si está habilitado
                      return _getColorByEstado(_contextoSeleccionado);
                    },
                  ),
                ),
                child: Text(isSending ? 'Guardando...' : 'Guardar Prompt'), // Cambiar texto del botón
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