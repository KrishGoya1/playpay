import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../models/qr_code_model.dart';
import '../theme/app_theme.dart';
import '../pages/auth_page.dart';
import '../widgets/pin_setup_dialog.dart';
import '../services/database_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final qrData = user != null
        ? QRCodeData(
            userId: user.uid,
            userEmail: user.email ?? '',
            type: 'payment',
          ).toQRString()
        : '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              user.email?.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                fontSize: 32,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.email ?? 'No email',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Code
                    if (qrData.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _shareQRCode(
                                  context,
                                  qrData,
                                  user.email ?? '',
                                ),
                                icon: const Icon(Icons.share),
                                label: const Text('Share QR Code'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Updated PIN Setup Card
                    FutureBuilder<bool>(
                      future: DatabaseService().hasPin(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            child: ListTile(
                              leading: Icon(Icons.pin),
                              title: Text('Checking PIN status...'),
                            ),
                          );
                        }

                        final hasPin = snapshot.data ?? false;

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              hasPin ? Icons.check_circle : Icons.pin,
                              color: hasPin ? Colors.green : null,
                            ),
                            title: Text(hasPin ? 'PIN Setup Complete' : 'Setup Payment PIN'),
                            subtitle: Text(
                              hasPin 
                                ? 'Your payment PIN is set' 
                                : 'Secure your transactions'
                            ),
                            trailing: hasPin 
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.arrow_forward_ios),
                            onTap: hasPin 
                                ? null 
                                : () => _setupPin(context),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _shareQRCode(BuildContext context, String qrData, String email) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );

        final imageSize = Size(200, 200);
        final image = await painter.toImage(imageSize.width);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData == null) throw Exception('Failed to generate QR code image');

        final bytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_code.png');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Pay to $email using PlayPay',
          subject: 'PlayPay Payment QR Code',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing QR code: $e')),
        );
      }
    }
  }

  Future<void> _setupPin(BuildContext context) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinSetupDialog(),
    );

    if (pin != null && context.mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await DatabaseService().updateUserPin(user.uid, pin);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN setup successful'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting up PIN: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 