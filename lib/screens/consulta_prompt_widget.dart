import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/appscript_service.dart'; // Importa la versión Firestore del servicio
import 'package:flutter/services.dart'; // Para Clipboard
import 'dart:collection'; // Importa para usar LinkedHashSet

// 🔹 PRIMERA PARTE: La definición del StatefulWidget
class PromptConsultaWidget extends StatefulWidget {
  const PromptConsultaWidget({super.key});

  @override
  State<PromptConsultaWidget> createState() => _PromptConsultaWidgetState();
}

// 🔹 SEGUNDA PARTE: La clase State asociada
class _PromptConsultaWidgetState extends State<PromptConsultaWidget> {
  // 🔹 Crea una instancia de tu servicio
  final AppscriptService _appscriptService = AppscriptService();

  String? contextoSeleccionado;
  String? propositoSeleccionado;

  List<String> contextos = [];
  List<String> propositos = []; // Esta lista se llenará al seleccionar un contexto
  List<Map<String, dynamic>> promptsEncontrados = [];

  Map<String, List<String>> propositosPorContexto = {}; // Mapa para guardar la relación contexto -> propositos

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarOpciones(); // Cargar opciones de dropdown al iniciar el widget
  }

  // Carga las opciones de contexto y el mapa agrupado
  Future<void> _cargarOpciones() async {
    try {
      // 🔹 Llama a los métodos a través de la instancia del servicio
      final data = await _appscriptService.obtenerOpcionesUnicas(); // Devuelve listas planas de contexto/proposito
      final agrupados = await _appscriptService.obtenerOpcionesUnicasAgrupadas(); // Devuelve mapa contexto -> [propositos]

      setState(() {
        // 🔹 MODIFICADO: Usamos LinkedHashSet para garantizar la unicidad de contextos y ordenar
        final Set<String> contextosSet = LinkedHashSet.from(data['contexto']?.whereType<String>() ?? []);
        contextos = contextosSet.toList()..sort(); // Convertir Set a lista y ordenar

        propositosPorContexto = agrupados; // Guardamos el mapa agrupado
        // No poblamos propositos aquí, se hace en el onChanged del primer dropdown
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cargando opciones: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar opciones: $e')),
      );
    }
  }

  // Actualiza la lista 'propositos' para el segundo dropdown basado en el contexto seleccionado
  void _actualizarPropositosDropdown(String? selectedContexto) {
    propositos = []; // Limpiar la lista de propositos actual
    if (selectedContexto != null && propositosPorContexto.containsKey(selectedContexto)) {
      // 🔹 MODIFICADO: Usamos LinkedHashSet para garantizar la unicidad de propositos para el contexto seleccionado
      final Set<String> propositosSet = LinkedHashSet.from(propositosPorContexto[selectedContexto]?.whereType<String>() ?? []);
      propositos = propositosSet.toList()..sort(); // Convertir Set a lista y ordenar
    }
  }


  // Busca prompts en Firestore basado en los filtros seleccionados
  Future<void> buscarPrompts() async {
    // No buscar si no se han seleccionado contexto y proposito
    if (contextoSeleccionado == null || propositoSeleccionado == null) {
      if (kDebugMode) { debugPrint('DEBUG Consulta: Filtros no seleccionados, no se realiza busqueda.'); }
      setState(() { promptsEncontrados = []; }); // Limpiar resultados si los filtros son invalidos
      return;
    }

    setState(() => cargando = true); // Mostrar indicador de carga

    try {
      // 🔹 Llama al método a través de la instancia del servicio
      final data = await _appscriptService.consultarPromptsPorContextoYProposito(
        contextoSeleccionado!, // ! es seguro porque validamos arriba
        propositoSeleccionado!, // ! es seguro porque validamos arriba
      );

      setState(() {
        promptsEncontrados = List<Map<String, dynamic>>.from(data); // Asignar y asegurar tipo
        cargando = false; // Ocultar indicador de carga
      });
      if (kDebugMode) { debugPrint('DEBUG Consulta: Consulta de prompts exitosa. ${promptsEncontrados.length} resultados.'); }
    } catch (e) {
      setState(() => cargando = false); // Ocultar indicador de carga
      if (kDebugMode) {
        debugPrint('DEBUG Consulta: Error al consultar prompts: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al consultar: $e')),
      );
    }
  }

  // Muestra un dialogo para editar el texto de un prompt
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
        // No necesitas llamar a buscarPrompts si no hubo cambios
        return;
      }

      setState(() { cargando = true; }); // Mostrar carga durante la actualización

      try {
        // 🔹 Llama al método a través de la instancia del servicio para actualizar en Firestore
        final exito = await _appscriptService.actualizarPrompt(id: id, nuevoTexto: nuevoTexto);

        setState(() { cargando = false; }); // Ocultar carga

        if (exito) {
          // Si la actualización fue exitosa en Firestore, volvemos a buscar para refrescar la UI
          await buscarPrompts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt actualizado correctamente')),
          );
        } else {
          // El servicio devolvió false, significa que la operación no fue exitosa (pero no lanzó excepción)
          if (kDebugMode) { debugPrint('DEBUG Consulta: Actualizar Prompt: Servicio devolvió false'); }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el prompt')),
          );
        }
      } catch (e) {
        setState(() { cargando = false; }); // Ocultar carga
        if (kDebugMode) { debugPrint('DEBUG Consulta: Excepción en _mostrarDialogoEdicion al actualizar: $e'); }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo técnico al actualizar: $e')),
        );
      }
    }
    controller.dispose(); // Limpiar el controller del dialogo al cerrar
  }

  // Muestra un dialogo de confirmacion antes de eliminar un prompt
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
      setState(() { cargando = true; }); // Mostrar carga durante la eliminación
      try {
        // 🔹 Llama al método a través de la instancia del servicio para eliminar en Firestore
        final exito = await _appscriptService.eliminarPrompt(id: id);

        setState(() { cargando = false; }); // Ocultar carga

        if (exito) {
          // Si la eliminación fue exitosa en Firestore, volvemos a buscar para refrescar la UI
          // Opcional: eliminar el item directamente de promptsEncontrados si ya está cargado
          // promptsEncontrados.removeWhere((prompt) => prompt['id'] == id);
          // setState(() {}); // Si eliminas de la lista local, necesitas llamar a setState
          await buscarPrompts(); // Buscar de nuevo es más seguro si la lista puede haber cambiado en otro lado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt eliminado')),
          );
        } else {
          if (kDebugMode) { debugPrint('DEBUG Consulta: Eliminar Prompt: Servicio devolvió false'); }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el prompt')),
          );
        }
      } catch (e) {
        setState(() { cargando = false; }); // Ocultar carga
        if (kDebugMode) { debugPrint('DEBUG Consulta: Excepción en _confirmarEliminacion al eliminar: $e'); }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fallo técnico al eliminar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpiar cualquier TextEditingController que esté definido a nivel de clase
    // En este código, el controller está definido dentro del método _mostrarDialogoEdicion
    // y se le llama dispose ahí mismo. Si tuvieras controllers a nivel de clase, dispónlos aquí.
    // _emailController.dispose(); // Ejemplo si tuvieras uno
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
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
                // No necesitas Flexible aquí. RichText o Text simple es suficiente.
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
                propositoSeleccionado = null; // Limpiar proposito seleccionado cuando cambia el contexto
                _actualizarPropositosDropdown(value); // 🔹 Llamar a la nueva función para actualizar propositos
                promptsEncontrados = []; // Limpiar resultados cuando cambia el contexto
              });
            },
            // 🔹 Añadimos validator para contexto
            validator: (value) =>
            value == null ? 'Selecciona un contexto' : null,
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
            items: propositos.map((p) { // Usamos la lista 'propositos' que se actualiza al seleccionar contexto
              // Asegurarse de que p no es null o vacío antes de split
              final parts = p.split(' ');
              final primeraPalabra = parts.isNotEmpty ? parts.first : p;
              final resto = parts.length > 1 ? parts.sublist(1).join(' ') : '';
              return DropdownMenuItem(
                value: p,
                // 🔹 MODIFICADO: ELIMINAMOS Flexible y Container que causaban el error de layout
                child: RichText( // Mantenemos solo el RichText o el widget que desees mostrar
                  softWrap: true, // Permite que el texto se ajuste si es muy largo
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '$primeraPalabra ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, // Opcional: negrita en primera palabra
                            color: Colors.blueAccent
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
                propositoSeleccionado = value;
              });
              // Buscar prompts automáticamente cuando se selecciona un propósito válido
              if (value != null) buscarPrompts();
            },
            // 🔹 MODIFICADO: Añadimos validator para propósito también
            validator: (value) =>
            value == null ? 'Selecciona un propósito' : null,
          ),
          const SizedBox(height: 20),

          // Sección de resultados (AnimatedSwitcher)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: cargando // Si está cargando, mostrar indicador
                ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator()) // Key necesaria para AnimatedSwitcher
                : promptsEncontrados.isNotEmpty // Si hay resultados, mostrar la lista
                ? Column(
              key: const ValueKey('listado'), // Key necesaria para AnimatedSwitcher
              crossAxisAlignment: CrossAxisAlignment.start,
              children: promptsEncontrados.map((fila) {
                // Asegurarse de que las claves existen y tienen el tipo esperado
                final promptTexto = fila['prompt'] as String? ?? 'N/A'; // Manejar posible null o tipo incorrecto
                final id = fila['id'] as String? ?? 'N/A'; // ID ahora viene como string
                // Puedes acceder a otros campos si los necesitas, ej:
                // final fechaCreacion = fila['fechaCreacion'] as Timestamp?; // Si es Timestamp de Firestore
                // String fechaStr = fechaCreacion != null ? DateFormat('yyyy-MM-dd HH:mm').format(fechaCreacion.toDate()) : 'N/A'; // Requiere import 'package:intl/intl.dart'; si quieres formatear

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
                          // Opcional: Mostrar contexto y proposito (verificando existencia y tipo)
                          if (fila.containsKey('contextoUso') && fila['contextoUso'] is String)
                            Text('Contexto: ${fila['contextoUso']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          if (fila.containsKey('propositoUso') && fila['propositoUso'] is String)
                            Text('Propósito: ${fila['propositoUso']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          // Opcional: Mostrar fecha (manejar Timestamp o String segun como lo guardes/leas)
                          if (fila.containsKey('fechaCreacion') && fila['fechaCreacion'] != null)
                            Text('Fecha: ${fila['fechaCreacion'].toString()}', style: TextStyle(fontSize: 12, color: Colors.grey[700])), // Mostrar directamente o formatear

                          const SizedBox(height: 8), // Espacio después de los metadatos

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100], // Color de fondo del texto del prompt
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText( // Permite seleccionar el texto para copiar
                              promptTexto,
                              style: const TextStyle(color: Colors.black, fontSize: 17),
                            ),
                          ),
                          const SizedBox(height: 8),

                          SingleChildScrollView( // Permite hacer scroll horizontal si los botones son muchos
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end, // Alinea botones al final
                              children: [
                                // Boton Copiar
                                TextButton.icon(
                                  onPressed: () {
                                    // Asegurarse de que promptTexto sea valido antes de copiar
                                    if(promptTexto != 'N/A' && promptTexto.isNotEmpty){
                                      Clipboard.setData(ClipboardData(text: promptTexto));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Texto copiado al portapapeles')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No hay texto para copiar')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copiar'),
                                ),
                                const SizedBox(width: 8),
                                // Boton Editar
                                // Asegurarse de que id y promptTexto no sean 'N/A' antes de habilitar la edición
                                if (id != 'N/A' && promptTexto != 'N/A')
                                  TextButton.icon(
                                    onPressed: () => _mostrarDialogoEdicion(id, promptTexto),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar'),
                                  ),
                                const SizedBox(width: 8),
                                // Boton Eliminar
                                // Asegurarse de que id no sea 'N/A' antes de habilitar la eliminación
                                if (id != 'N/A')
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
            // Mensaje si no hay resultados
                : contextoSeleccionado != null && propositoSeleccionado != null && !cargando && promptsEncontrados.isEmpty
                ? const Center(key: ValueKey('noresults'), child: Text('No se encontraron prompts con esos filtros.')) // Key necesaria para AnimatedSwitcher
            // Espacio vacío si aún no se han seleccionado filtros o está cargando inicialmente
                : const SizedBox.shrink(key: ValueKey('empty')), // Key necesaria para AnimatedSwitcher
          ),
        ],
      ),
    );
  }
}