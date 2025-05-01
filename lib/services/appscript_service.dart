import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Importa FirebaseAuth para posible uso de userId
// Puedes importar dart:collection si usas Set o LinkedHashSet
// import 'dart:collection';

// Ya no necesitamos la URL base ni el paquete http
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// const String baseUrl = '...';

// Usaremos una clase para organizar los métodos del servicio
class AppscriptService {

  // Instancia de Firestore (usar solo una convención, por ejemplo _firestore)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Puedes usar una referencia a la colección si lo prefieres, pero a menudo
  // es más directo llamando a _firestore.collection() donde la necesitas.
  // final CollectionReference promptsCollection = FirebaseFirestore.instance.collection('prompts');


  /// 🔹 Enviar un nuevo prompt a Firestore
  Future<void> enviarPrompt({
    required String contextoUso,
    required String propositoUso,
    required String promptTexto,
  }) async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando enviarPrompt...'); }
    try {
      // 🔹 Añade un nuevo documento a la colección 'prompts'
      await _firestore.collection('prompts').add({
        'contextoUso': contextoUso,
        'propositoUso': propositoUso,
        'prompt': promptTexto,
        'fechaCreacion': FieldValue.serverTimestamp(), // Usa Timestamp del servidor
        // Opcional: añadir userId del usuario logueado
        // 'userId': FirebaseAuth.instance.currentUser?.uid, // Descomentar si quieres guardar el ID del usuario
      });

      if (kDebugMode) {
        debugPrint('DEBUG Service: Prompt guardado exitosamente en Firestore.');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al enviar prompt a Firestore: $e');
      }
      // Es mejor relanzar el error original
      throw e; // Mantén el stack trace
    }
    if (kDebugMode) { debugPrint('DEBUG Service: Fin de enviarPrompt.'); }
  }

  /// 🔹 Leer opciones únicas desde Firestore (lista plana)
  Future<Map<String, List<String>>> obtenerOpcionesUnicas() async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando obtenerOpcionesUnicas...'); }
    try {
      QuerySnapshot snapshot = await _firestore.collection('prompts').get();

      Set<String> contextoUnico = {};
      Set<String> propositoUnico = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Verificaciones de tipo y si no están vacíos
        if (data.containsKey('contextoUso') && data['contextoUso'] is String && (data['contextoUso'] as String).isNotEmpty) {
          contextoUnico.add(data['contextoUso']);
        }
        if (data.containsKey('propositoUso') && data['propositoUso'] is String && (data['propositoUso'] as String).isNotEmpty) {
          propositoUnico.add(data['propositoUso']);
        }
      }

      // Convertir Sets a listas y ordenar
      List<String> contextosList = contextoUnico.toList()..sort();
      List<String> propositosList = propositoUnico.toList()..sort();


      if (kDebugMode) {
        debugPrint('DEBUG Service: Opciones únicas obtenidas. Contextos: ${contextosList.length}, Propositos: ${propositosList.length}');
      }

      return {
        'contexto': contextosList,
        'proposito': propositosList,
      };

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al obtener opciones únicas de Firestore: $e');
      }
      // Es mejor relanzar el error original
      throw e;
    }
  }

  /// 🔹 Agrupa los propósitos por contexto desde Firestore (mapa)
  Future<Map<String, List<String>>> obtenerOpcionesUnicasAgrupadas() async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando obtenerOpcionesUnicasAgrupadas...'); }
    try {
      QuerySnapshot snapshot = await _firestore.collection('prompts').get();

      Map<String, Set<String>> propositoPorContexto = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? contexto = data.containsKey('contextoUso') && data['contextoUso'] is String
            ? data['contextoUso'] as String? : null;
        String? proposito = data.containsKey('propositoUso') && data['propositoUso'] is String
            ? data['propositoUso'] as String? : null;

        // Solo procesar si ambos campos existen y no son nulos/vacios
        if (contexto != null && contexto.isNotEmpty && proposito != null && proposito.isNotEmpty) {
          if (!propositoPorContexto.containsKey(contexto)) {
            propositoPorContexto[contexto] = {};
          }
          propositoPorContexto[contexto]!.add(proposito);
        }
      }

      Map<String, List<String>> resultado = {};
      propositoPorContexto.forEach((contexto, propositos) {
        List<String> propositosList = propositos.toList()..sort(); // Ordenar los propósitos dentro de cada contexto
        resultado[contexto] = propositosList;
      });

      if (kDebugMode) { debugPrint('DEBUG Service: Opciones agrupadas obtenidas. ${resultado.length} contextos.'); }
      return resultado;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al obtener opciones agrupadas de Firestore: $e');
      }
      // Es mejor relanzar el error original
      throw e;
    }
  }


  /// 🔹 Consultar Prompts por Contexto y Proposito desde Firestore
  // Ahora devuelve Future<List<Map<String, dynamic>>> y los ordena por fecha
  Future<List<Map<String, dynamic>>> consultarPromptsPorContextoYProposito(
      String contexto, String proposito) async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando consultarPromptsPorContextoYProposito con Contexto: $contexto, Proposito: $proposito'); }
    try {
      Query query = _firestore.collection('prompts'); // Empieza con la colección

      // Aplica filtros WHERE si los parámetros no están vacíos
      if (contexto.isNotEmpty) {
        query = query.where('contextoUso', isEqualTo: contexto);
      }
      if (proposito.isNotEmpty) {
        query = query.where('propositoUso', isEqualTo: proposito);
      }

      // 🔹 AÑADIMOS ESTA LÍNEA para ordenar por fecha (más reciente primero)
      // ESTA LÍNEA COMBINADA CON LOS FILTROS WHERE REQUIERE UN ÍNDICE COMPUESTO EN FIRESTORE.
      query = query.orderBy('fechaCreacion', descending: true);

      // Ejecuta la consulta
      QuerySnapshot snapshot = await query.get();

      // Mapea los documentos de la consulta a List<Map<String, dynamic>>
      List<Map<String, dynamic>> promptsList = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Añade el ID del documento al mapa
        // Convierte el Timestamp a String legible si es necesario
        if(data.containsKey('fechaCreacion') && data['fechaCreacion'] is Timestamp){
          data['fechaCreacion'] = (data['fechaCreacion'] as Timestamp).toDate().toString(); // Convertir a String legible
        } else if (!data.containsKey('fechaCreacion') || data['fechaCreacion'] == null) {
          data['fechaCreacion'] = 'Fecha no disponible'; // Manejar si el campo no existe o es null
        }
        // Asegurarse de que contextoUso y propositoUso son Strings para consistencia en UI
        if (!data.containsKey('contextoUso') || !(data['contextoUso'] is String)) {
          data['contextoUso'] = 'Sin Contexto';
        }
        if (!data.containsKey('propositoUso') || !(data['propositoUso'] is String)) {
          data['propositoUso'] = 'Sin Propósito';
        }

        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('DEBUG Service: Consulta de prompts exitosa. ${promptsList.length} resultados.');
      }

      return promptsList;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al consultar prompts en Firestore: $e');
      }
      // Es mejor relanzar el error original para que el widget lo maneje
      throw e;
    }
  }

  /// 🔹 Actualizar Prompt en Firestore
  Future<bool> actualizarPrompt({
    required String id,
    required String nuevoTexto,
  }) async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando actualizarPrompt para ID: $id'); }
    try {
      DocumentReference promptDoc = _firestore.collection('prompts').doc(id);

      await promptDoc.update({
        'prompt': nuevoTexto,
        // Opcional: añadir una marca de tiempo de última actualización
        // 'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('DEBUG Service: Prompt actualizado exitosamente en Firestore: ID $id');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al actualizar prompt en Firestore (ID: $id): $e');
      }
      throw e; // Re-lanzar para que el widget lo maneje
    }
  }

  /// 🔹 Eliminar un prompt en Firestore
  Future<bool> eliminarPrompt({required String id}) async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando eliminarPrompt para ID: $id'); }
    try {
      DocumentReference promptDoc = _firestore.collection('prompts').doc(id);

      await promptDoc.delete();

      if (kDebugMode) {
        debugPrint('DEBUG Service: Prompt eliminado exitosamente en Firestore: ID $id');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG Service: Error al eliminar prompt en Firestore (ID: $id): $e');
      }
      throw e; // Re-lanzar para que el widget lo maneje
    }
  }
//contextoUso Ascendente propositoUso Ascendente fechaCreacion Ascendente __name__ Ascendente
  // Opcional: Método para cerrar sesión
  Future<void> signOut() async {
    if (kDebugMode) { debugPrint('DEBUG Service: Iniciando cierre de sesión.'); }
    try {
      await FirebaseAuth.instance.signOut();
      if (kDebugMode) { debugPrint('DEBUG Service: Sesión cerrada exitosamente.'); }
    } catch (e) {
      if (kDebugMode) { debugPrint('DEBUG Service: Error al cerrar sesión: $e'); }
      throw e; // Re-lanzar
    }
  }
}