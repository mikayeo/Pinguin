import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinguin/models/account.dart';

class ApiService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  // Use Android emulator's special localhost address
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  )) {
    // Initialize interceptors after base URL is set
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests if available
        final token = await _getStoredToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Handle unauthorized access
          _handleUnauthorized();
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> _getStoredToken() async {
    return await _storage.read(key: 'token');
  }

  void _handleUnauthorized() async {
    // Clear stored credentials
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'userId');
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Track the last registration attempt time
  DateTime? _lastRegistrationAttempt;

  Future<Map<String, dynamic>> register(String username, String password, String phoneNumber) async {
    // Prevent rapid successive registration attempts
    final now = DateTime.now();
    if (_lastRegistrationAttempt != null) {
      final difference = now.difference(_lastRegistrationAttempt!);
      if (difference.inSeconds < 3) {
        throw Exception('Please wait a moment before trying again');
      }
    }
    _lastRegistrationAttempt = now;

    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'phoneNumber': phoneNumber,
        },
        options: Options(
          // Prevent retries on failure
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 409) {
        throw Exception('Username or phone number already exists');
      }
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Registration failed. Please try again.');
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Account endpoints
  Future<Account> getAccount() async {
    try {
      final response = await _dio.get('/accounts');
      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> sendMoney(String recipientPhone, double amount) async {
    try {
      await _dio.post('/transactions/send', data: {
        'recipientPhone': recipientPhone,
        'amount': amount,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> receiveMoney(String senderPhone, double amount) async {
    try {
      await _dio.post('/transactions/receive', data: {
        'senderPhone': senderPhone,
        'amount': amount,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    // Clear the last registration attempt on error
    _lastRegistrationAttempt = null;

    if (error.response?.data != null && error.response?.data['message'] != null) {
      return Exception(error.response?.data['message']);
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Unable to connect to server. Please check if:\n'
          '1. Your internet connection is working\n'
          '2. The backend server is running\n'
          '3. You are using the correct server address'
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 409) {
          return Exception('Username or phone number already exists');
        } else if (statusCode == 400) {
          return Exception('Invalid input. Please check your details.');
        }
        return Exception('Server error (${statusCode ?? 'unknown'}). Please try again later.');
      case DioExceptionType.cancel:
        return Exception('Request cancelled.');
      default:
        if (error.message?.contains('SocketException') ?? false) {
          return Exception(
            'Network error: Could not connect to server.\n'
            'Please ensure the backend server is running.'
          );
        }
        return Exception('Network error. Please check your connection and try again.');
    }
  }
}