import 'package:flutter/material.dart';
import 'package:pinguin/models/account.dart';
import 'package:pinguin/services/api_service.dart';

class AccountProvider with ChangeNotifier {
  final _apiService = ApiService();
  Account? _account;
  bool _isLoading = false;
  String? _error;

  Account? get account => _account;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _account = await _apiService.getAccount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMoney(String recipientAccountNumber, double amount) async {
    if (_account == null) return;
    if (amount <= 0) throw Exception('Amount must be greater than 0');
    if (amount > _account!.balance) throw Exception('Insufficient funds');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.sendMoney(recipientAccountNumber, amount);
      // Refresh account data after successful transaction
      await fetchAccount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> receiveMoney(String senderAccountNumber, double amount) async {
    if (_account == null) return;
    if (amount <= 0) throw Exception('Amount must be greater than 0');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.receiveMoney(senderAccountNumber, amount);
      // Refresh account data after successful transaction
      await fetchAccount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 