import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pinguin/models/account.dart';
import 'package:pinguin/providers/auth_provider.dart';

class ApiService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  static const String baseUrl = 'https://api.moneytransfer.com/v1'; // Replace with your actual API URL

  ApiService() : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
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

  void _handleUnauthorized() {
    // Clear stored credentials
    _storage.delete(key: 'token');
    _storage.delete(key: 'userId');
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Account endpoints
  Future<Account> getAccount() async {
    try {
      final response = await _dio.get('/account');
      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> sendMoney(String recipientAccountNumber, double amount) async {
    try {
      await _dio.post('/transactions/send', data: {
        'recipientAccountNumber': recipientAccountNumber,
        'amount': amount,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> receiveMoney(String senderAccountNumber, double amount) async {
    try {
      await _dio.post('/transactions/receive', data: {
        'senderAccountNumber': senderAccountNumber,
        'amount': amount,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data['message'] != null) {
      return Exception(error.response?.data['message']);
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        return Exception('Server error. Please try again later.');
      case DioExceptionType.cancel:
        return Exception('Request cancelled.');
      default:
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
} 