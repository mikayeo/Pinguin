import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinguin/providers/account_provider.dart';
import 'package:pinguin/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:pinguin/screens/home/qr_scanner_screen.dart';
import 'package:pinguin/screens/home/transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh account data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().fetchAccount();
    });
  }

  void _showSendMoneyDialog({String? recipientPhone}) {
    final recipientController = TextEditingController(text: recipientPhone);
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
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

                // Send money
                await accountProvider.sendMoney(
                  recipientController.text,
                  amount,
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
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(account.balance)} FCFA',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
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