class UserModel {
  final String uid;
  final String email;
  double balance;
  List<String> transactions;
  String? pin;

  UserModel({
    required this.uid,
    required this.email,
    this.balance = 0.0,
    this.transactions = const [],
    this.pin,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'balance': balance,
      'transactions': transactions,
      'pin': pin,
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      transactions: List<String>.from(json['transactions'] ?? []),
      pin: json['pin'],
    );
  }
} 