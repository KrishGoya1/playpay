import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String userId;
  final double amount;
  final DateTime timestamp;
  final String type;
  final String description;
  final String? pairedTransactionId;
  final String status;

  TransactionModel({
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.pairedTransactionId,
    this.status = 'pending',
  }) {
    if (amount <= 0) throw Exception('Invalid amount');
    if (type != 'credit' && type != 'debit') throw Exception('Invalid type');
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'description': description,
      'pairedTransactionId': pairedTransactionId,
      'status': status,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : (json['timestamp'] as Timestamp).toDate(),
      type: json['type'] as String,
      description: json['description'] as String,
      pairedTransactionId: json['pairedTransactionId'] as String?,
      status: json['status'] as String? ?? 'completed',
    );
  }
} 