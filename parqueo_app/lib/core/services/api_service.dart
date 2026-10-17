import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URLs candidatas para desarrollo y pruebas físicas:
  // 1. IP LAN Wi-Fi de la PC (funciona directo por Wi-Fi sin necesidad de cable)
  // 2. Localhost 127.0.0.1 (funciona por cable USB con adb reverse)
  // 3. 10.0.2.2 (emulador Android)
  static const List<String> _fallbackUrls = [
    'http://192.168.0.150:8000/api/v1',
    'http://127.0.0.1:8000/api/v1',
    'http://10.0.2.2:8000/api/v1',
  ];

  String _baseUrl = 'http://192.168.0.150:8000/api/v1';
  String? _token;

  String get baseUrl => _baseUrl;

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', _baseUrl);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final savedUrl = prefs.getString('custom_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  // Ejecuta una petición con auto-fallback: si la URL actual falla por conexión,
  // prueba automáticamente las demás alternativas (Wi-Fi o USB) y adopta la funcional.
  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) requestBuilder,
  ) async {
    try {
      final res = await requestBuilder(_baseUrl).timeout(const Duration(seconds: 4));
      return res;
    } catch (e) {
      // Intentar alternativas en orden
      for (final altUrl in _fallbackUrls) {
        if (altUrl == _baseUrl) continue;
        try {
          final res = await requestBuilder(altUrl).timeout(const Duration(seconds: 3));
          // Servidor respondió exitosamente: guardar esta URL como la activa
          _baseUrl = altUrl;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('custom_base_url', _baseUrl);
          return res;
        } catch (_) {
          continue;
        }
      }
      rethrow;
    }
  }

  Future<bool> testConnection([String? testUrl]) async {
    final target = testUrl ?? _baseUrl;
    try {
      final res = await http
          .get(Uri.parse('$target/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      try {
        final res = await http
            .get(Uri.parse('$target/auth/login'))
            .timeout(const Duration(seconds: 3));
        return res.statusCode == 401 || res.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  bool get isAuthenticated => _token != null;

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<String> getUserName() async {
    final user = await getUserData();
    return user?['name'] ?? 'Daniel Luna';
  }

  // 1. Iniciar Sesión con auto-detección de red
  Future<Map<String, dynamic>> login({String? email, String? password, String? pinCode}) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            if (email != null) 'email': email,
            if (password != null) 'password': password,
            if (pinCode != null) 'pin_code': pinCode,
          }),
        ),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(data['data']['user']));
        await prefs.setString('parking_data', jsonEncode(data['data']['parking']));
        return data;
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'is_connection_error': true,
        'message': 'No se pudo conectar al servidor ($_baseUrl). Verifica que esté en la misma red Wi-Fi o conectado por cable USB.',
      };
    }
  }

  // 2. Obtener resumen de Dashboard
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _sendWithFallback(
        (url) => http.get(Uri.parse('$url/dashboard/summary'), headers: _headers),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar resumen'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 3. Obtener tipos de vehículos
  Future<Map<String, dynamic>> getVehicleTypes({bool all = false}) async {
    try {
      final response = await _sendWithFallback(
        (url) {
          final uri = Uri.parse('$url/vehicle-types').replace(queryParameters: {
            if (all) 'all': 'true',
          });
          return http.get(uri, headers: _headers);
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar tipos de vehículos'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 4. Registrar Entrada de Vehículo (con soporte opcional de foto evidencia)
  Future<Map<String, dynamic>> registerEntry({
    required String licensePlate,
    required int vehicleTypeId,
    String? notes,
    String? photoPath,
  }) async {
    try {
      if (photoPath != null && photoPath.isNotEmpty) {
        final response = await _sendWithFallback((url) async {
          final request = http.MultipartRequest('POST', Uri.parse('$url/entries'));
          request.headers.addAll({
            'Accept': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          });
          request.fields['license_plate'] = licensePlate;
          request.fields['vehicle_type_id'] = vehicleTypeId.toString();
          if (notes != null && notes.isNotEmpty) {
            request.fields['notes'] = notes;
          }
          request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
          final streamed = await request.send();
          return http.Response.fromStream(streamed);
        });
        return jsonDecode(response.body);
      }

      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/entries'),
          headers: _headers,
          body: jsonEncode({
            'license_plate': licensePlate,
            'vehicle_type_id': vehicleTypeId,
            'notes': notes,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 5. Listar vehículos (adentro / historial)
  Future<Map<String, dynamic>> getVehicles({String status = 'inside', String? search}) async {
    try {
      final response = await _sendWithFallback(
        (url) {
          final uri = Uri.parse('$url/entries').replace(queryParameters: {
            'status': status,
            if (search != null && search.isNotEmpty) 'search': search,
          });
          return http.get(uri, headers: _headers);
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar lista de vehículos'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 6. Calcular tarifa de salida
  Future<Map<String, dynamic>> calculateExit(String query) async {
    try {
      final response = await _sendWithFallback(
        (url) {
          final uri = Uri.parse('$url/exits/calculate').replace(queryParameters: {'query': query});
          return http.get(uri, headers: _headers);
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 7. Completar salida y cobro (con soporte de penalidad por ticket perdido)
  Future<Map<String, dynamic>> completeExit({
    required int entryId,
    required String paymentMethod,
    int? paymentMethodId,
    String? referenceNumber,
    double discount = 0.0,
    double penalty = 0.0,
    bool isLostTicket = false,
    String? notes,
  }) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/exits/complete'),
          headers: _headers,
          body: jsonEncode({
            'entry_id': entryId,
            'payment_method': paymentMethod,
            if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
            if (referenceNumber != null && referenceNumber.isNotEmpty) 'reference_number': referenceNumber,
            'discount_amount': discount,
            'penalty_amount': penalty,
            'is_lost_ticket': isLostTicket,
            'notes': notes,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 7b. Cobro directo por ticket extraviado
  Future<Map<String, dynamic>> completeLostTicket({
    required String licensePlate,
    required int vehicleTypeId,
    required double lostFee,
    required String paymentMethod,
    int? paymentMethodId,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/exits/lost-ticket'),
          headers: _headers,
          body: jsonEncode({
            'license_plate': licensePlate,
            'vehicle_type_id': vehicleTypeId,
            'lost_fee': lostFee,
            'payment_method': paymentMethod,
            if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
            if (referenceNumber != null && referenceNumber.isNotEmpty) 'reference_number': referenceNumber,
            'notes': notes,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 8. Historial de transacciones
  Future<Map<String, dynamic>> getTransactions({String period = 'today', String? search}) async {
    try {
      final response = await _sendWithFallback(
        (url) {
          final uri = Uri.parse('$url/transactions').replace(queryParameters: {
            'period': period,
            if (search != null && search.isNotEmpty) 'search': search,
          });
          return http.get(uri, headers: _headers);
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar transacciones'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 9. Reporte Diario
  Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    try {
      final response = await _sendWithFallback(
        (url) {
          final uri = Uri.parse('$url/reports/daily').replace(queryParameters: {
            if (date != null) 'date': date,
          });
          return http.get(uri, headers: _headers);
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar reporte'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 10. Cerrar Sesión
  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$_baseUrl/auth/logout'), headers: _headers);
    } catch (_) {}
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('parking_data');
  }

  // 11. Formas de Pago (Payment Methods CRUD)
  Future<Map<String, dynamic>> getPaymentMethods({bool all = false}) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.get(
          Uri.parse('$url/payment-methods${all ? '?all=1' : ''}'),
          headers: _headers,
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar métodos de pago'};
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createPaymentMethod({
    required String name,
    String? code,
    String? icon,
    String? instructions,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? phoneNumber,
    bool requiresReference = false,
    bool isActive = true,
    String? qrImagePath,
  }) async {
    try {
      if (qrImagePath != null && qrImagePath.isNotEmpty) {
        final response = await _sendWithFallback((url) async {
          final request = http.MultipartRequest('POST', Uri.parse('$url/payment-methods'));
          request.headers.addAll({
            'Accept': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          });
          request.fields['name'] = name;
          if (code != null) request.fields['code'] = code;
          if (icon != null) request.fields['icon'] = icon;
          if (instructions != null) request.fields['instructions'] = instructions;
          if (bankName != null) request.fields['bank_name'] = bankName;
          if (accountHolder != null) request.fields['account_holder'] = accountHolder;
          if (accountNumber != null) request.fields['account_number'] = accountNumber;
          if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
          request.fields['requires_reference'] = requiresReference ? '1' : '0';
          request.fields['is_active'] = isActive ? '1' : '0';
          request.files.add(await http.MultipartFile.fromPath('qr_image', qrImagePath));
          final streamed = await request.send();
          return http.Response.fromStream(streamed);
        });
        return jsonDecode(response.body);
      }

      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/payment-methods'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'code': code,
            'icon': icon,
            'instructions': instructions,
            'bank_name': bankName,
            'account_holder': accountHolder,
            'account_number': accountNumber,
            'phone_number': phoneNumber,
            'requires_reference': requiresReference,
            'is_active': isActive,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePaymentMethod(
    int id, {
    String? name,
    String? code,
    String? icon,
    String? instructions,
    String? bankName,
    String? accountHolder,
    String? accountNumber,
    String? phoneNumber,
    bool? requiresReference,
    bool? isActive,
    String? qrImagePath,
  }) async {
    try {
      if (qrImagePath != null && qrImagePath.isNotEmpty) {
        final response = await _sendWithFallback((url) async {
          final request = http.MultipartRequest('POST', Uri.parse('$url/payment-methods/$id'));
          request.headers.addAll({
            'Accept': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          });
          request.fields['_method'] = 'PUT';
          if (name != null) request.fields['name'] = name;
          if (code != null) request.fields['code'] = code;
          if (icon != null) request.fields['icon'] = icon;
          if (instructions != null) request.fields['instructions'] = instructions;
          if (bankName != null) request.fields['bank_name'] = bankName;
          if (accountHolder != null) request.fields['account_holder'] = accountHolder;
          if (accountNumber != null) request.fields['account_number'] = accountNumber;
          if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
          if (requiresReference != null) request.fields['requires_reference'] = requiresReference ? '1' : '0';
          if (isActive != null) request.fields['is_active'] = isActive ? '1' : '0';
          request.files.add(await http.MultipartFile.fromPath('qr_image', qrImagePath));
          final streamed = await request.send();
          return http.Response.fromStream(streamed);
        });
        return jsonDecode(response.body);
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (icon != null) body['icon'] = icon;
      if (instructions != null) body['instructions'] = instructions;
      if (bankName != null) body['bank_name'] = bankName;
      if (accountHolder != null) body['account_holder'] = accountHolder;
      if (accountNumber != null) body['account_number'] = accountNumber;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (requiresReference != null) body['requires_reference'] = requiresReference;
      if (isActive != null) body['is_active'] = isActive;

      final response = await _sendWithFallback(
        (url) => http.put(
          Uri.parse('$url/payment-methods/$id'),
          headers: _headers,
          body: jsonEncode(body),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadPaymentMethodQr(int id, String filePath) async {
    try {
      final response = await _sendWithFallback((url) async {
        final request = http.MultipartRequest('POST', Uri.parse('$url/payment-methods/$id/upload-qr'));
        request.headers.addAll({
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        });
        request.files.add(await http.MultipartFile.fromPath('qr_image', filePath));
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      });
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> togglePaymentMethod(int id) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.patch(
          Uri.parse('$url/payment-methods/$id/toggle'),
          headers: _headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePaymentMethod(int id) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.delete(
          Uri.parse('$url/payment-methods/$id'),
          headers: _headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  // 12. Gestión de Tipos de Vehículos y Tarifas
  Future<Map<String, dynamic>> createVehicleType(Map<String, dynamic> data) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.post(
          Uri.parse('$url/vehicle-types'),
          headers: _headers,
          body: jsonEncode(data),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateVehicleType(int id, Map<String, dynamic> data) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.put(
          Uri.parse('$url/vehicle-types/$id'),
          headers: _headers,
          body: jsonEncode(data),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteVehicleType(int id) async {
    try {
      final response = await _sendWithFallback(
        (url) => http.delete(
          Uri.parse('$url/vehicle-types/$id'),
          headers: _headers,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'is_connection_error': true, 'message': 'Error de conexión: $e'};
    }
  }
}
