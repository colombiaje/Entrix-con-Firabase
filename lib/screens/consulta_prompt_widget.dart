// ... imports
import 'package:flutter/material.dart';
import '../services/appscript_service.dart';
import 'package:flutter/services.dart';

class PromptConsultaWidget extends StatefulWidget {
  const PromptConsultaWidget({super.key});

  @override
  State<PromptConsultaWidget> createState() => _PromptConsultaWidgetState();
}

class _PromptConsultaWidgetState extends State<PromptConsultaWidget> {
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
      final data = await obtenerOpcionesUnicas();
      final agrupados = await obtenerOpcionesUnicasAgrupadas();

      setState(() {
        contextos = data['contexto']!..sort();
        propositosPorContexto = agrupados;
      });
    } catch (e) {
      debugPrint('Error cargando opciones: $e');
    }
  }

  Future<void> buscarPrompts() async {
    if (contextoSeleccionado == null || propositoSeleccionado == null) return;

    setState(() => cargando = true);

    try {
      final data = await consultarPromptsPorContextoYProposito(
        contextoSeleccionado!,
        propositoSeleccionado!,
      );

      setState(() {
        promptsEncontrados = List<Map<String, dynamic>>.from(data);
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
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

      final exito = await actualizarPrompt(id: id, nuevoTexto: nuevoTexto);
      if (exito) {
        await buscarPrompts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt actualizado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el prompt')),
        );
      }
    }
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
      final exito = await eliminarPrompt(id: id);
      if (exito) {
        buscarPrompts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt eliminado')),
        );
      }
    }
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
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Contexto de uso',
              filled: true,
              fillColor: contextoSeleccionado == null ? Colors.red[100] : Colors.green[100],
            ),
            value: contextoSeleccionado,
            items: contextos.map((ctx) {
              final primeraPalabra = ctx.split(' ').first;
              final resto = ctx.split(' ').skip(1).join(' ');
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
                propositos = propositosPorContexto[value] ?? [];
                propositos.sort();
                promptsEncontrados = [];
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Propósito de uso',
              filled: true,
              fillColor: propositoSeleccionado == null ? Colors.red[100] : Colors.green[100],
            ),
            value: propositoSeleccionado,

            //...12
            items: propositos.map((p) {
              final primeraPalabra = p.split(' ').first;
              final resto = p.split(' ').skip(1).join(' ');

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

            //...12

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
                final promptTexto = fila['prompt'];
                final id = fila['id'].toString();
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
                          //...11

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: promptTexto));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Texto copiado al portapapeles')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copiar'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _mostrarDialogoEdicion(id, promptTexto),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Editar'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmarEliminacion(id),
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),


                          //...11
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
