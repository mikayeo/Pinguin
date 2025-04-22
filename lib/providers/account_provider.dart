import 'package:flutter/material.dart';
import 'package:pinguin/models/account.dart';
import 'package:pinguin/models/transaction.dart';
import 'package:pinguin/services/api_service.dart';

class AccountProvider with ChangeNotifier {
  final _apiService = ApiService();
  Account? _account;
  bool _isLoading = false;
  String? _error;

  List<Transaction> _transactions = [];

  Account? get account => _account;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  // Get balance from account or default to 0
  double get balance => _account?.balance ?? 0;

  // Load transactions from API
  Future<void> _loadTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      _transactions = transactions;
      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  // Update account data from API
  Future<void> _updateAccount() async {
    await fetchAccount();
    await _loadTransactions();
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

  Future<void> sendMoney(String sender_phone, String recipient_phone, double amount, String type) async {
    if (_account == null) return;
    if (amount <= 0) throw Exception('Amount must be greater than 0');
    
    final currentBalance = balance;
    if (amount > currentBalance) {
      throw Exception('Insufficient funds. Available balance: $currentBalance FCFA');
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Send money via API
      final transaction = await _apiService.sendMoney(
        sender_phone,
        recipient_phone,
        amount,
        type
      );

      // Add the new transaction to the list
      _transactions = [transaction, ..._transactions];

      // Update account data
      await _updateAccount();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> receiveMoney(String senderAccountNumber, double amount) async {
    if (_account == null) return;
    if (amount <= 0) throw Exception('Amount must be greater than 0');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Receive money and get transaction record
      final transaction = await _apiService.receiveMoney(senderAccountNumber, amount);
      
      // Fetch updated account data
      await fetchAccount();
      
      // Add transaction to history
      _addTransaction(transaction);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 