import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pinguin/providers/account_provider.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAccount(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final transactions = provider.transactions;

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final currentPhone = provider.account?.phoneNumber;
              final isSender = currentPhone == transaction.sender_phone;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isSender ? Icons.call_made : Icons.call_received,
                    color: isSender ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    isSender
                        ? 'Sent ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(transaction.amount)} FCFA'
                        : 'Received ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(transaction.amount)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isSender
                          ? 'To: ${transaction.recipient_phone}'
                          : 'From: ${transaction.sender_phone}'),
                      Text(
                        DateFormat('MMM d, y HH:mm').format(transaction.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
