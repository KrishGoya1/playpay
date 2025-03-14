import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/qr_code_model.dart';
import '../services/database_service.dart';
import 'payment_page.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> {
  final DatabaseService _dbService = DatabaseService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _handleQRCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (code.startsWith('PLAYPAY://')) {
        final qrData = QRCodeData.fromQRString(code);
        if (qrData == null) throw Exception('Invalid QR code');

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw Exception('Not logged in');

        // Prevent self-payment
        if (qrData.userId == currentUser.uid) {
          throw Exception('Cannot send money to yourself');
        }

        if (qrData.type == 'payment') {
          // Verify user exists
          final userData = await _dbService.getUserData(qrData.userId);
          if (userData == null) throw Exception('Recipient not found');

          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  recipientId: qrData.userId,
                  recipientEmail: qrData.userEmail,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleQRCode(barcode.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Align QR code within the frame',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 