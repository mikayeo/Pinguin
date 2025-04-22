import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pinguin/providers/account_provider.dart';
import 'package:pinguin/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:pinguin/screens/home/qr_scanner_screen.dart';
import 'package:pinguin/screens/home/transaction_history_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Always fetch fresh account data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().fetchAccount();
    });

    // Set up periodic refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<AccountProvider>().fetchAccount();
      }
    });
  }

  void _showSendMoneyDialog({String? recipientPhone}) {
    final senderController = TextEditingController();
    final recipientController = TextEditingController(text: recipientPhone);
    final amountController = TextEditingController();
    final typeController = TextEditingController(text: 'transfer');

    // Get current user's phone number
    final currentPhone = context.read<AccountProvider>().account?.phoneNumber ?? '';
    senderController.text = currentPhone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: senderController,
              decoration: const InputDecoration(
                labelText: 'Sender Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: false, // Disable editing of sender's phone
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              enabled: false, // Disable editing of type
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('DEBUG: Raw amount text: ${amountController.text}');
              final amount = double.tryParse(amountController.text.trim());
              print('DEBUG: Parsed amount: $amount');
              // Validate amount
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              // Validate phone numbers
              final recipientNumber = recipientController.text.trim();
              if (recipientNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter recipient phone number')),
                );
                return;
              }

              try {
                final accountProvider = context.read<AccountProvider>();
                final currentBalance = accountProvider.balance;
                
                if (amount > currentBalance) {
                  throw Exception('Insufficient funds. Available balance: ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(currentBalance)} FCFA');
                }

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                // Calculate new balance
                final newBalance = currentBalance - amount;

                print('DEBUG: Sending money from ${senderController.text.trim()} to $recipientNumber');
                
                // Send money
                await accountProvider.sendMoney(
                  senderController.text.trim(),
                  recipientNumber,
                  amount,
                  typeController.text.trim(),
                );

                if (!mounted) return;

                // Close loading dialog
                Navigator.pop(context);

                // Show success dialog
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: const [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 30,
                        ),
                        SizedBox(width: 8),
                        Text('Success!'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Successfully sent ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount)} FCFA'),
                        Text('To: ${recipientController.text}'),
                        const SizedBox(height: 16),
                        Text(
                          'New balance: ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(newBalance)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Navigate to fresh home screen
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false, // Remove all previous routes
                          );
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                // Close loading dialog if it's showing
                Navigator.of(context).popUntil((route) => route.isFirst);

                // Show error dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRCodeScanned: (phoneNumber) {
            _showSendMoneyDialog(recipientPhone: phoneNumber);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, child) {
          if (accountProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (accountProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${accountProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => accountProvider.fetchAccount(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final account = accountProvider.account;
          if (account == null) {
            return const Center(child: Text('No account data available'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(account.balance)} FCFA',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // QR Code Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: account.phoneNumber ?? '',
                                  version: QrVersions.auto,
                                  size: 150.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan to send money',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Phone Number: ${account.phoneNumber}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showSendMoneyDialog,
                          icon: const Icon(Icons.send),
                          label: const Text('Send Money'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showQRScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View Transaction History'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 