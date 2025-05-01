import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

// Ya no necesitamos la URL base ni el paquete http
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// const String baseUrl = '...';

// Usaremos una clase para organizar los métodos del servicio
class AppscriptService { // Mantenemos el nombre de la clase por ahora

  // Instancia de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referencia a la colección 'prompts' (asegúrate de que este nombre coincide con tu plan 'prompts')
  final CollectionReference promptsCollection = FirebaseFirestore.instance.collection('prompts');


  /// 🔹 Enviar un nuevo prompt a Firestore (adaptado de 'addPrompt')
  // El retorno cambia de Future<String> a Future<void>
  Future<void> enviarPrompt({
    required String contextoUso,
    required String propositoUso,
    required String promptTexto,
  }) async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando enviarPrompt...'); } // 🔹 Añade esto
    try {
      // ... tu código actual de Firestore .add() ...
      await promptsCollection.add({
        'contextoUso': contextoUso,
        'propositoUso': propositoUso,
        'prompt': promptTexto,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('DEBUG Service: Prompt guardado exitosamente en Firestore.'); // 🔹 Esto ya estaba, verifica que esté
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al enviar prompt a Firestore: $e'); // 🔹 Esto ya estaba, verifica que esté
      }
      throw Exception('Fallo al guardar prompt en Firebase: $e');
    }
    if (kDebugMode) { debugPrint('DEBUG Service: Fin de enviarPrompt.'); } // 🔹 Añade esto al final del try (antes del catch si hubiera)
  }

  /// 🔹 Leer opciones únicas desde Firestore (adaptado de 'getOptions')
  // NOTA: Obtener opciones únicas directamente de Firestore requiere leer documentos
  // y procesarlos. Para grandes cantidades de datos, esto podría ser ineficiente.
  // Alternativas: guardar opciones en un documento/colección separada o usar Cloud Functions.
  // Aquí, leemos todos los prompts para extraer los valores únicos, similar a como tu script podría haberlo hecho.
  Future<Map<String, List<String>>> obtenerOpcionesUnicas() async {
    try {
      QuerySnapshot snapshot = await promptsCollection.get();

      Set<String> contextoUnico = {};
      Set<String> propositoUnico = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('contextoUso') && data['contextoUso'] is String) {
          contextoUnico.add(data['contextoUso']);
        }
        if (data.containsKey('propositoUso') && data['propositoUso'] is String) {
          propositoUnico.add(data['propositoUso']);
        }
      }

      return {
        'contexto': contextoUnico.toList(),
        'proposito': propositoUnico.toList(),
      };

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener opciones únicas de Firestore: $e');
      }
      throw Exception('Error al obtener opciones únicas: $e');
    }
  }

  /// 🔹 Agrupa los propósitos por contexto desde Firestore (adaptado del original)
  // NOTA: Igual que la anterior, puede ser ineficiente para muchos datos.
  Future<Map<String, List<String>>> obtenerOpcionesUnicasAgrupadas() async {
    try {
      QuerySnapshot snapshot = await promptsCollection.get();

      Map<String, Set<String>> propositoPorContexto = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String contexto = data.containsKey('contextoUso') && data['contextoUso'] is String
            ? data['contextoUso'] : 'Sin Contexto'; // Asigna un valor por defecto si falta
        String proposito = data.containsKey('propositoUso') && data['propositoUso'] is String
            ? data['propositoUso'] : 'Sin Propósito'; // Asigna un valor por defecto

        if (!propositoPorContexto.containsKey(contexto)) {
          propositoPorContexto[contexto] = {};
        }
        propositoPorContexto[contexto]!.add(proposito);
      }

      Map<String, List<String>> resultado = {};
      propositoPorContexto.forEach((contexto, propositos) {
        resultado[contexto] = propositos.toList();
      });

      return resultado;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al obtener opciones agrupadas de Firestore: $e');
      }
      throw Exception('Error al obtener opciones agrupadas: $e');
    }
  }


  /// 🔹 Consultar Prompts por Contexto y Proposito desde Firestore (adaptado de 'queryPrompts')
  // El retorno cambia de Future<List<Map<String, dynamic>>> a Future<List<Map<String, dynamic>>>
  // para mantener la compatibilidad con el llamador, aunque el patrón ideal de Firestore
  // para UI que escucha cambios sería Stream<List<Map<String, dynamic>>>
  Future<List<Map<String, dynamic>>> consultarPromptsPorContextoYProposito(
      String contexto, String proposito) async {
    try {
      Query query = promptsCollection; // Empieza con la colección

      // Aplica filtros WHERE si los parámetros no están vacíos
      if (contexto.isNotEmpty) {
        query = query.where('contextoUso', isEqualTo: contexto);
      }
      if (proposito.isNotEmpty) {
        // Para aplicar multiples filtros de igualdad, puedes encadenar .where()
        query = query.where('propositoUso', isEqualTo: proposito);
        // NOTA: Firestore requiere índices compuestos para ciertas combinaciones de filtros
        // Si tienes un error de Firestore sobre índices, la consola de Firebase te dará el enlace para crearlo.
      }

      // Ejecuta la consulta
      QuerySnapshot snapshot = await query.get();

      // Mapea los documentos de la consulta a List<Map<String, dynamic>>
      // Aseguramos que incluimos el ID del documento generado por Firestore
      List<Map<String, dynamic>> promptsList = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Añade el ID del documento al mapa
        // Firestore Timestamp a DateTime si es necesario
        if(data.containsKey('fechaCreacion') && data['fechaCreacion'] is Timestamp){
          data['fechaCreacion'] = (data['fechaCreacion'] as Timestamp).toDate().toString(); // O al formato que necesites
        }
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('Consulta de prompts exitosa. ${promptsList.length} resultados.');
      }

      return promptsList;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al consultar prompts en Firestore: $e');
      }
      throw Exception('Fallo al consultar prompts en Firebase: $e');
    }
  }

  /// 🔹 Actualizar Prompt en Firestore (adaptado de 'updatePrompt')
  // El retorno cambia de Future<bool> a Future<bool> (manejamos el éxito/fallo)
  Future<bool> actualizarPrompt({
    required String id,
    required String nuevoTexto,
  }) async {
    try {
      // Referencia al documento específico usando el ID
      DocumentReference promptDoc = promptsCollection.doc(id);

      // Actualiza el campo 'prompt'
      await promptDoc.update({
        'prompt': nuevoTexto,
        // Puedes añadir una marca de tiempo de última actualización si lo necesitas
        // 'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Prompt actualizado exitosamente en Firestore: ID $id');
      }

      return true; // Indica éxito

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al actualizar prompt en Firestore (ID: $id): $e');
      }
      // Devuelve false en caso de error
      // Puedes lanzar una excepción si prefieres que el llamador maneje errores específicos
      // throw Exception('Fallo al actualizar prompt en Firebase: $e');
      return false; // Indica fallo
    }
  }

  /// 🔹 Eliminar un prompt en Firestore (adaptado de 'deletePrompt')
  // El retorno cambia de Future<bool> a Future<bool> (manejamos el éxito/fallo)
  Future<bool> eliminarPrompt({required String id}) async {
    try {
      // Referencia al documento específico usando el ID
      DocumentReference promptDoc = promptsCollection.doc(id);

      // Elimina el documento
      await promptDoc.delete();

      if (kDebugMode) {
        debugPrint('Prompt eliminado exitosamente en Firestore: ID $id');
      }

      return true; // Indica éxito

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al eliminar prompt en Firestore (ID: $id): $e');
      }
      // Devuelve false en caso de error
      // Puedes lanzar una excepción si prefieres que el llamador maneje errores específicos
      // throw Exception('Fallo al eliminar prompt en Firebase: $e');
      return false; // Indica fallo
    }
  }

  // --- Métodos adicionales que podrías querer en el futuro ---

  /// Obtener un solo prompt por ID
  Future<Map<String, dynamic>?> getPromptById(String id) async {
    try {
      DocumentSnapshot doc = await promptsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Añade el ID del documento
        if(data.containsKey('fechaCreacion') && data['fechaCreacion'] is Timestamp){
          data['fechaCreacion'] = (data['fechaCreacion'] as Timestamp).toDate().toString();
        }
        return data;
      }
      return null; // Retorna null si el documento no existe
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting prompt by ID ($id) from Firestore: $e');
      }
      throw Exception('Failed to get prompt from Firebase: $e');
    }
  }

// Nota: Para pantallas que necesitan actualizarse en tiempo real
// (como una lista de prompts), la mejor práctica de Firestore es usar Streams.
// Por ejemplo:
/*
  Stream<List<Map<String, dynamic>>> streamPrompts({String? contexto, String? proposito}) {
      Query query = promptsCollection;
       if (contexto != null && contexto.isNotEmpty) {
        query = query.where('contextoUso', isEqualTo: contexto);
      }
      if (proposito != null && proposito.isNotEmpty) {
         query = query.where('propositoUso', isEqualTo: proposito);
      }
      // Puedes añadir ordenación si lo necesitas:
      // query = query.orderBy('fechaCreacion', descending: true);

      return query.snapshots().map((snapshot) {
          return snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              if(data.containsKey('fechaCreacion') && data['fechaCreacion'] is Timestamp){
                 data['fechaCreacion'] = (data['fechaCreacion'] as Timestamp).toDate().toString();
              }
              return data;
          }).toList();
      });
  }
  */


}