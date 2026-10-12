import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URL base dinámica: Por defecto 127.0.0.1:8000 (funciona con USB adb reverse en celular y en PC)
  String _baseUrl = 'http://127.0.0.1:8000/api/v1';

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

  Future<bool> testConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/vehicle-types'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
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

  // 1. Iniciar Sesión
  Future<Map<String, dynamic>> login({String? email, String? password, String? pinCode}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          if (email != null) 'email': email,
          if (password != null) 'password': password,
          if (pinCode != null) 'pin_code': pinCode,
        }),
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
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 2. Obtener resumen de Dashboard
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/summary'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar resumen'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 3. Obtener tipos de vehículos
  Future<Map<String, dynamic>> getVehicleTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicle-types'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar tipos de vehículos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 4. Registrar Entrada de Vehículo
  Future<Map<String, dynamic>> registerEntry({
    required String licensePlate,
    required int vehicleTypeId,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/entries'),
        headers: _headers,
        body: jsonEncode({
          'license_plate': licensePlate,
          'vehicle_type_id': vehicleTypeId,
          'notes': notes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 5. Listar vehículos (adentro / historial)
  Future<Map<String, dynamic>> getVehicles({String status = 'inside', String? search}) async {
    try {
      final uri = Uri.parse('$_baseUrl/entries').replace(queryParameters: {
        'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar lista de vehículos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 6. Calcular tarifa de salida
  Future<Map<String, dynamic>> calculateExit(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/exits/calculate').replace(queryParameters: {'query': query});
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 7. Completar salida y cobro
  Future<Map<String, dynamic>> completeExit({
    required int entryId,
    required String paymentMethod,
    double discount = 0.0,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/exits/complete'),
        headers: _headers,
        body: jsonEncode({
          'entry_id': entryId,
          'payment_method': paymentMethod,
          'discount_amount': discount,
          'notes': notes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 8. Historial de transacciones
  Future<Map<String, dynamic>> getTransactions({String period = 'today', String? search}) async {
    try {
      final uri = Uri.parse('$_baseUrl/transactions').replace(queryParameters: {
        'period': period,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar transacciones'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 9. Reporte Diario
  Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    try {
      final uri = Uri.parse('$_baseUrl/reports/daily').replace(queryParameters: {
        if (date != null) 'date': date,
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error al cargar reporte'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
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
}
