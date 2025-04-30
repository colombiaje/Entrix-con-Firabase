import 'dart:convert'; // Asegúrate de tener esta importación
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Importar para debugPrint y kDebugMode

// ✅ URL final confirmada como funcional
const String baseUrl = 'https://script.google.com/macros/s/AKfycbyH06ggywIMV_mjf0Aa8ajwXU3YNnf_ULwfeXkuB5FuMVFOKVwteWRjqPxAVDbmO8_Y/exec';

/// 🔹 Enviar un nuevo prompt (acción: 'addPrompt') usando POST
Future<String> enviarPrompt({
  required String contextoUso,
  required String propositoUso,
  required String promptTexto,
}) async {
  final url = Uri.parse(baseUrl);

  try {
    final response = await http.post(
      url,
      body: {
        'action': 'addPrompt',
        'contextoUso': contextoUso,
        'propositoUso': propositoUso,
        'promptTexto': promptTexto,
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      // Los debugPrint solo se ejecutarán en modo depuración
      if (kDebugMode) {
        debugPrint('Error sending prompt: Status ${response.statusCode}, Body: ${response.body}');
      }
      return 'Error: ${response.statusCode}';
    }
  } catch (e) {
    // Los debugPrint solo se ejecutarán en modo depuración
    if (kDebugMode) {
      debugPrint('Exception sending prompt: $e');
    }
    return 'Excepción: $e';
  }
}

/// 🔹 Leer opciones únicas desde Google Sheets (acción: 'getOptions')
Future<Map<String, List<String>>> obtenerOpcionesUnicas() async {
  final url = Uri.parse('$baseUrl?action=getOptions');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Asegurarse de que las claves existen y son del tipo correcto antes de convertir a List<String>
      return {
        'contexto': (data != null && data is Map && data.containsKey('contexto') && data['contexto'] is List)
            ? List<String>.from(data['contexto']) : [],
        'proposito': (data != null && data is Map && data.containsKey('proposito') && data['proposito'] is List)
            ? List<String>.from(data['proposito']) : [],
      };
    } else {
      // Los debugPrint solo se ejecutarán en modo depuración
      if (kDebugMode) {
        debugPrint('Error getting unique options: Status ${response.statusCode}, Body: ${response.body}');
      }
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e) {
    // Los debugPrint solo se ejecutarán en modo depuración
    if (kDebugMode) {
      debugPrint('Exception getting unique options: $e');
    }
    throw Exception('Error al obtener opciones únicas: $e');
  }
}

/// 🔹 Agrupa los propósitos por contexto (de forma eficiente con el JSON)
Future<Map<String, List<String>>> obtenerOpcionesUnicasAgrupadas() async {
  final url = Uri.parse('$baseUrl?action=getOptions');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Asegurarse de que la clave existe y es un mapa
      final Map<String, dynamic> rawMap = (data != null && data is Map && data.containsKey('propositoPorContexto') && data['propositoPorContexto'] is Map)
          ? data['propositoPorContexto'] : {}; // Retorna un mapa vacío si no es válido

      Map<String, List<String>> mapa = {};
      rawMap.forEach((key, value) {
        // Asegurarse de que el valor asociado a la clave es una lista antes de convertir
        if (value is List) {
          mapa[key] = List<String>.from(value);
        } else {
          mapa[key] = []; // Retorna lista vacía si el valor no es una lista
        }
      });

      return mapa;
    } else {
      // Los debugPrint solo se ejecutarán en modo depuración
      if (kDebugMode) {
        debugPrint('Error getting grouped options: Status ${response.statusCode}, Body: ${response.body}');
      }
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e) {
    // Los debugPrint solo se ejecutarán en modo depuración
    if (kDebugMode) {
      debugPrint('Exception getting grouped options: $e');
    }
    throw Exception('Error al obtener opciones: $e');
  }
}

Future<List<Map<String, dynamic>>> consultarPromptsPorContextoYProposito(
    String contexto, String proposito) async {
  final uri = Uri.parse(
      '$baseUrl?action=queryPrompts&contextoUso=$contexto&propositoUso=$proposito');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      // Asegurarse de que la respuesta decodificada es una lista antes de mapear
      if (jsonData is List) {
        return jsonData.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        // Los debugPrint solo se ejecutarán en modo depuración
        if (kDebugMode) {
          debugPrint('Query Prompts: Response body is not a List. Body: ${response.body}');
        }
        return []; // Retorna lista vacía si no es una lista
      }
    } else {
      // Los debugPrint solo se ejecutarán en modo depuración
      if (kDebugMode) {
        debugPrint('Error consulting prompts: Status ${response.statusCode}, Body: ${response.body}');
      }
      throw Exception('Error al consultar prompts');
    }
  } catch (e) {
    // Los debugPrint solo se ejecutarán en modo depuración
    if (kDebugMode) {
      debugPrint('Exception consulting prompts: $e');
    }
    throw Exception('Error al consultar prompts: $e');
  }
}

//Agregado por cambio del Script para estas dos funciones.
Future<bool> actualizarPrompt({
  required String id,
  required String nuevoTexto,
}) async {
  try {
    // Primera solicitud
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'updatePrompt',
        'idPrompt': id,
        'nuevoTexto': nuevoTexto,
      },
    ).timeout(const Duration(seconds: 15));

    if (kDebugMode) {
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
    }

    // Manejar redirección (código 302)
    if (response.statusCode == 302) {
      // Obtener la URL de redirección del encabezado Location
      String? redirectUrl = response.headers['location'];

      // Si no está en los encabezados, intentar extraerla del cuerpo HTML
      if (redirectUrl == null && response.body.contains('HREF="')) {
        final hrefMatch = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
        if (hrefMatch != null && hrefMatch.groupCount >= 1) {
          redirectUrl = hrefMatch.group(1);
        }
      }

      if (redirectUrl != null) {
        if (kDebugMode) {
          debugPrint('Siguiendo redirección a: $redirectUrl');
        }

        // Hacer la segunda solicitud a la URL de redirección
        final redirectResponse = await http.get(
          Uri.parse(redirectUrl),
        ).timeout(const Duration(seconds: 15));

        if (kDebugMode) {
          debugPrint('Redirect Response Status: ${redirectResponse.statusCode}');
          debugPrint('Redirect Response Body: ${redirectResponse.body}');
        }

        // Procesar la respuesta de la redirección
        if (redirectResponse.statusCode == 200) {
          try {
            final responseData = jsonDecode(redirectResponse.body);
            return responseData != null &&
                responseData is Map &&
                responseData.containsKey('success') &&
                responseData['success'] == true;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error decodificando JSON después de redirección: $e');
            }
            return false;
          }
        }
      }
    } else if (response.statusCode == 200) {
      // Procesar respuesta normal (sin redirección)
      final responseData = jsonDecode(response.body);
      return responseData != null &&
          responseData is Map &&
          responseData.containsKey('success') &&
          responseData['success'] == true;
    }

    return false;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error en actualizarPrompt: $e');
    }
    return false;
  }
}
/// ✅ NUEVO: Eliminar un prompt por ID
Future<bool> eliminarPrompt({required String id}) async {
  try {
    // Primera solicitud
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'deletePrompt',
        'id': id,
      },
    ).timeout(const Duration(seconds: 15));

    // Los debugPrint solo se ejecutarán en modo depuración
    if (kDebugMode) {
      debugPrint('--- Appscript Delete Response Debug ---');
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('--- End Appscript Delete Response Debug ---');
    }

    // Manejar redirección (código 302)
    if (response.statusCode == 302) {
      // Obtener la URL de redirección del encabezado Location
      String? redirectUrl = response.headers['location'];

      // Si no está en los encabezados, intentar extraerla del cuerpo HTML
      if (redirectUrl == null && response.body.contains('HREF="')) {
        final hrefMatch = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
        if (hrefMatch != null && hrefMatch.groupCount >= 1) {
          redirectUrl = hrefMatch.group(1);
        }
      }

      if (redirectUrl != null) {
        if (kDebugMode) {
          debugPrint('Siguiendo redirección a: $redirectUrl');
        }

        // Hacer la segunda solicitud a la URL de redirección
        final redirectResponse = await http.get(
          Uri.parse(redirectUrl),
        ).timeout(const Duration(seconds: 15));

        if (kDebugMode) {
          debugPrint('Redirect Response Status: ${redirectResponse.statusCode}');
          debugPrint('Redirect Response Body: ${redirectResponse.body}');
        }

        // Procesar la respuesta de la redirección
        if (redirectResponse.statusCode == 200) {
          try {
            final responseData = jsonDecode(redirectResponse.body);
            if (responseData != null &&
                responseData is Map &&
                responseData.containsKey('success') &&
                responseData['success'] == true) {

              if (kDebugMode) {
                debugPrint('Backend reported delete success = true.');
                if(responseData.containsKey('message') && responseData['message'] != null) {
                  debugPrint('Backend message: ${responseData['message']}');
                }
              }
              return true;
            } else {
              if (kDebugMode) {
                debugPrint('Backend reported delete success = false after redirect.');
                if(responseData != null && responseData is Map && responseData.containsKey('message') && responseData['message'] != null) {
                  debugPrint('Backend error message: ${responseData['message']}');
                }
                if(responseData != null && responseData is Map && responseData.containsKey('logs') && responseData['logs'] != null) {
                  debugPrint('Backend logs: ${responseData['logs']}');
                }
              }
              return false;
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error decodificando JSON después de redirección: $e');
              debugPrint('Raw response body was: ${redirectResponse.body}');
            }
            return false;
          }
        }
      }
    } else if (response.statusCode == 200) {
      // Procesamiento normal (sin redirección)
      try {
        final responseData = jsonDecode(response.body);
        if (responseData != null &&
            responseData is Map &&
            responseData.containsKey('success') &&
            responseData['success'] == true) {

          if (kDebugMode) {
            debugPrint('Backend reported delete success = true.');
            if(responseData.containsKey('message') && responseData['message'] != null) {
              debugPrint('Backend message: ${responseData['message']}');
            }
          }
          return true;
        } else {
          if (kDebugMode) {
            debugPrint('Backend reported delete success = false.');
            if(responseData != null && responseData is Map && responseData.containsKey('message') && responseData['message'] != null) {
              debugPrint('Backend error message: ${responseData['message']}');
            }
            if(responseData != null && responseData is Map && responseData.containsKey('logs') && responseData['logs'] != null) {
              debugPrint('Backend logs: ${responseData['logs']}');
            } else {
              debugPrint('Backend delete response structure unexpected. Raw body: ${response.body}');
            }
          }
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing backend delete response JSON: $e');
          debugPrint('Raw response body was: ${response.body}');
        }
        return false;
      }
    }

    // Si llegamos aquí, es porque no se procesó correctamente ni la respuesta directa ni la redirección
    if (kDebugMode) {
      debugPrint('No se pudo procesar la respuesta ni la redirección');
    }
    return false;
  } catch (e) {
    // Captura cualquier excepción durante todo el proceso
    if (kDebugMode) {
      debugPrint('Error en eliminarPrompt: $e');
    }
    return false;
  }
}