import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pinguin/providers/account_provider.dart';

class MyQRCodeScreen extends StatelessWidget {
  const MyQRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneNumber = context.select<AccountProvider, String?>(
      (provider) => provider.account?.phoneNumber
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
      ),
      body: Center(
        child: phoneNumber == null
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        QrImageView(
                          data: phoneNumber,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'My Phone Number',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          phoneNumber,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Scan this code to send money to me',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
