import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/appscript_service.dart'; // Importa la versión Firestore del servicio
import 'package:flutter/services.dart'; // Para Clipboard

class PromptConsultaWidget extends StatefulWidget {
  const PromptConsultaWidget({super.key});

  @override
  State<PromptConsultaWidget> createState() => _PromptConsultaWidgetState();
}

class _PromptConsultaWidgetState extends State<PromptConsultaWidget> {
  // 🔹 Crea una instancia de tu servicio
  final AppscriptService _appscriptService = AppscriptService();

  String? contextoSeleccionado;
  String? propositoSeleccionado;

  List<String> contextos = [];
  List<String> propositos = [];
  List<Map<String, dynamic>> promptsEncontrados = [];

  Map<String, List<String>> propositosPorContexto = {};

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    try {
      // 🔹 Llama a los métodos a través de la instancia del servicio
      final data = await _appscriptService.obtenerOpcionesUnicas();
      final agrupados = await _appscriptService.obtenerOpcionesUnicasAgrupadas();

      setState(() {
        contextos = data['contexto']!..sort();
        propositosPorContexto = agrupados;
      });
    } catch (e) {
      // Usa debugPrint para errores en modo depuración
      if (kDebugMode) { // Asegúrate de importar flutter/foundation.dart si kDebugMode da error
        debugPrint('Error cargando opciones: $e');
      }
      // Puedes mostrar un mensaje al usuario si la carga de opciones falla al inicio
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar opciones: $e')),
      );
    }
  }

  Future<void> buscarPrompts() async {
    if (contextoSeleccionado == null || propositoSeleccionado == null) return;

    setState(() => cargando = true);

    try {
      // 🔹 Llama al método a través de la instancia del servicio
      final data = await _appscriptService.consultarPromptsPorContextoYProposito(
        contextoSeleccionado!,
        propositoSeleccionado!,
      );

      setState(() {
        // No deberías necesitar from() si el servicio ya devuelve List<Map<String, dynamic>>
        promptsEncontrados = data; // Asigna directamente
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      // Usa debugPrint para errores en modo depuración
      if (kDebugMode) {
        debugPrint('Error al consultar prompts: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al consultar: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoEdicion(String id, String textoActual) async {
    TextEditingController controller = TextEditingController(text: textoActual);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Prompt'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final nuevoTexto = controller.text.trim();

      if (nuevoTexto == textoActual.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se detectaron cambios')),
        );
        return;
      }

      setState(() { cargando = true; }); // Opcional: mostrar carga durante la actualización

      try {
        // 🔹 Llama al método a través de la instancia del servicio
        final exito = await _appscriptService.actualizarPrompt(id: id, nuevoTexto: nuevoTexto);

        setState(() { cargando = false; }); // Ocultar carga

        if (exito) {
          // Si la actualización fue exitosa, volvemos a buscar los prompts para refrescar la lista
          await buscarPrompts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt actualizado correctamente')),
          );
        } else {
          // El servicio devolvió false, significa que la operación no fue exitosa (pero no lanzó excepción)
          if (kDebugMode) { debugPrint('Actualizar Prompt: Servicio devolvió false'); }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el prompt')),
          );
        }
      } catch (e) {
        setState(() { cargando = false; }); // Ocultar carga
        if (kDebugMode) { debugPrint('Excepción en _mostrarDialogoEdicion al actualizar: $e'); }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo técnico al actualizar: $e')),
        );
      }
    }
    controller.dispose(); // Limpiar el controller
  }

  Future<void> _confirmarEliminacion(String id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar prompt?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      setState(() { cargando = true; }); // Opcional: mostrar carga durante la eliminación
      try {
        // 🔹 Llama al método a través de la instancia del servicio
        final exito = await _appscriptService.eliminarPrompt(id: id);

        setState(() { cargando = false; }); // Ocultar carga

        if (exito) {
          // Si la eliminación fue exitosa, volvemos a buscar los prompts para refrescar la lista
          // Opcional: eliminar el item directamente de promptsEncontrados si ya está cargado
          // promptsEncontrados.removeWhere((prompt) => prompt['id'] == id);
          // setState(() {}); // Si eliminas de la lista local, necesitas llamar a setState
          await buscarPrompts(); // Buscar de nuevo es más seguro si la lista puede haber cambiado en otro lado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt eliminado')),
          );
        } else {
          if (kDebugMode) { debugPrint('Eliminar Prompt: Servicio devolvió false'); }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el prompt')),
          );
        }
      } catch (e) {
        setState(() { cargando = false; }); // Ocultar carga
        if (kDebugMode) { debugPrint('Excepción en _confirmarEliminacion al eliminar: $e'); }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo técnico al eliminar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpiar cualquier TextEditingController
    // controller.dispose(); // Si hubieras definido el controller fuera del método _mostrarDialogoEdicion
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // ... el resto del build method permanece igual en principio ...
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 40),
          const Text('🔍 Consultar Prompts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Dropdown para Contexto
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Contexto de uso',
              filled: true,
              fillColor: contextoSeleccionado == null ? Colors.red[100] : Colors.green[100],
            ),
            value: contextoSeleccionado,
            items: contextos.map((ctx) {
              // Asegurarse de que ctx no es null o vacío antes de split
              final parts = ctx.split(' ');
              final primeraPalabra = parts.isNotEmpty ? parts.first : ctx;
              final resto = parts.length > 1 ? parts.sublist(1).join(' ') : '';
              return DropdownMenuItem(
                value: ctx,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(text: '$primeraPalabra ', style: const TextStyle(color: Colors.blueAccent)),
                      TextSpan(text: resto),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                contextoSeleccionado = value;
                propositoSeleccionado = null;
                // Asegurarse de que value no es null antes de acceder al mapa
                propositos = value != null ? propositosPorContexto[value] ?? [] : [];
                propositos.sort();
                promptsEncontrados = [];
              });
            },
          ),
          const SizedBox(height: 16),
          // Dropdown para Proposito
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Propósito de uso',
              filled: true,
              fillColor: propositoSeleccionado == null ? Colors.red[100] : Colors.green[100],
            ),
            value: propositoSeleccionado,
            // Asegurarse de que la lista propositos no es null antes de mapear
            items: propositos.map((p) {
              // Asegurarse de que p no es null o vacío antes de split
              final parts = p.split(' ');
              final primeraPalabra = parts.isNotEmpty ? parts.first : p;
              final resto = parts.length > 1 ? parts.sublist(1).join(' ') : '';
              return DropdownMenuItem(
                value: p,
                child: Flexible( // <-- Este truco mágico
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 400, // Máximo 400, pero puede achicarse dinámico
                    ),
                    child: RichText(
                      softWrap: true,
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: '$primeraPalabra ',
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                          TextSpan(text: resto),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            onChanged: (value) {
              setState(() {
                propositoSeleccionado = value;
              });
              if (value != null) buscarPrompts();
            },
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : promptsEncontrados.isNotEmpty
                ? Column(
              key: const ValueKey('listado'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: promptsEncontrados.map((fila) {
                // Asegurarse de que las claves existen y tienen el tipo esperado
                final promptTexto = fila['prompt'] as String? ?? 'N/A'; // Manejar posible null o tipo incorrecto
                final id = fila['id'] as String? ?? 'N/A'; // ID ahora viene como string
                // Puedes acceder a otros campos si los necesitas, ej:
                // final fechaCreacion = fila['fechaCreacion'] as String? ?? 'N/A'; // Si lo convertiste a String en el servicio

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Opcional: Mostrar contexto y proposito
                          if (fila.containsKey('contextoUso') && fila['contextoUso'] is String)
                            Text('Contexto: ${fila['contextoUso']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          if (fila.containsKey('propositoUso') && fila['propositoUso'] is String)
                            Text('Propósito: ${fila['propositoUso']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          // Opcional: Mostrar fecha
                          if (fila.containsKey('fechaCreacion') && fila['fechaCreacion'] != null) // Puede ser String o Timestamp si no lo convertiste en el servicio
                            Text('Fecha: ${fila['fechaCreacion']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),

                          const SizedBox(height: 8), // Espacio después de los metadatos

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              promptTexto,
                              style: const TextStyle(color: Colors.black, fontSize: 17),
                            ),
                          ),
                          const SizedBox(height: 8),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    // Asegurarse de que promptTexto no sea null antes de copiar
                                    if(promptTexto != null && promptTexto.isNotEmpty){
                                      Clipboard.setData(ClipboardData(text: promptTexto));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Texto copiado al portapapeles')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copiar'),
                                ),
                                const SizedBox(width: 8),
                                // Asegurarse de que id y promptTexto no sean null antes de habilitar la edición
                                if (id != 'N/A' && promptTexto != 'N/A') // Habilitar solo si tenemos un ID y texto valido
                                  TextButton.icon(
                                    onPressed: () => _mostrarDialogoEdicion(id, promptTexto),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar'),
                                  ),
                                const SizedBox(width: 8),
                                // Asegurarse de que id no sea null antes de habilitar la eliminación
                                if (id != 'N/A') // Habilitar solo si tenemos un ID valido
                                  TextButton.icon(
                                    onPressed: () => _confirmarEliminacion(id),
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
                : contextoSeleccionado != null && propositoSeleccionado != null
                ? const Text('No se encontraron prompts con esos filtros.')
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}