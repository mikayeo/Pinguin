import 'package:flutter/material.dart';
import 'package:pinguin/models/account.dart';
import 'package:pinguin/models/transaction.dart';
import 'package:pinguin/services/api_service.dart';

class AccountProvider with ChangeNotifier {
  final _apiService = ApiService();
  Account? _account;
  bool _isLoading = false;
  String? _error;

  // Use shared preferences to persist balance and transactions
  static const String _balanceKey = 'account_balance';
  static double? _cachedBalance;
  static List<Transaction> _transactions = [];

  Account? get account => _account == null ? null : _account!.copyWith(balance: balance);
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  // Get balance from cache or default to 100000
  double get balance => _cachedBalance ?? 100000;

  // Update balance and persist it
  Future<void> _updateBalance(double newBalance) async {
    _cachedBalance = newBalance;
    notifyListeners();
  }

  // Add a new transaction to history
  void _addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction); // Add to start of list
    notifyListeners();
  }

  Future<void> fetchAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _account = await _apiService.getAccount();
      if (_account != null) {
        _account = _account!.copyWith(balance: balance);
      }
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
    
    final currentBalance = balance;
    if (amount > currentBalance) {
      throw Exception('Insufficient funds. Available balance: $currentBalance FCFA');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Send money first
      await _apiService.sendMoney(recipientAccountNumber, amount);
      
      // Update balance after successful send
      final newBalance = currentBalance - amount;
      await _updateBalance(newBalance);
      
      // Add transaction to history
      _addTransaction(Transaction(
        recipientPhone: recipientAccountNumber,
        amount: amount,
        date: DateTime.now(),
      ));

      // Update account with new balance
      if (_account != null) {
        _account = _account!.copyWith(balance: newBalance);
      }
      
      _error = null;
      notifyListeners();
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