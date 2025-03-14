class QRCodeData {
  final String userId;
  final String userEmail;
  final String type; // 'payment' or 'website'
  final String websiteUrl;

  QRCodeData({
    required this.userId,
    required this.userEmail,
    required this.type,
    this.websiteUrl = 'https://puter.com/app/playpay',
  });

  // Convert to JSON string for QR code
  String toQRString() {
    return 'PLAYPAY://$type/$userId/$userEmail';
  }

  // Parse QR string
  static QRCodeData? fromQRString(String qrString) {
    if (!qrString.startsWith('PLAYPAY://')) return null;
    
    try {
      final parts = qrString.replaceFirst('PLAYPAY://', '').split('/');
      return QRCodeData(
        type: parts[0],
        userId: parts[1],
        userEmail: parts[2],
      );
    } catch (e) {
      return null;
    }
  }
} 