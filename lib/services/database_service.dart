import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Existing methods
  Future<void> saveUserData(UserModel user) async {
    try {
      // Verify user is saving their own data
      if (_auth.currentUser?.uid != user.uid) {
        throw Exception('Unauthorized operation');
      }

      await _db.collection('users').doc(user.uid).set(
        user.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      // Check if requesting user is authenticated
      if (_auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(String uid, double newBalance) async {
    await _db.collection('users').doc(uid).update({'balance': newBalance});
  }

  // New methods for transactions
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Start a batch write
      WriteBatch batch = _db.batch();

      // Add the transaction document
      DocumentReference transactionRef = _db.collection('transactions').doc();
      batch.set(transactionRef, {
        ...transaction.toJson(),
        'amount': transaction.amount.toDouble(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get user document
      DocumentReference userRef = _db.collection('users').doc(transaction.userId);
      DocumentSnapshot userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Update user's balance
      double currentBalance = (userDoc.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
      double newBalance = transaction.type == 'credit' 
          ? currentBalance + transaction.amount 
          : currentBalance - transaction.amount;
      
      if (newBalance < 0) {
        throw Exception('Insufficient balance');
      }

      // Update user document
      batch.update(userRef, {
        'balance': newBalance,
        'transactions': FieldValue.arrayUnion([transactionRef.id])
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Get user's transactions
  Stream<List<TransactionModel>> getUserTransactions(String uid) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _db
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data()))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  // Add this method to check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Add this method to initialize user if needed
  Future<void> initializeUserIfNeeded(String uid, String email) async {
    try {
      bool exists = await userExists(uid);
      if (!exists) {
        final newUser = UserModel(
          uid: uid,
          email: email,
          balance: 0.0,
          transactions: [],
        );
        await saveUserData(newUser);
      }
    } catch (e) {
      print('Error initializing user: $e');
      rethrow;
    }
  }

  Future<void> processPayment({
    required String senderId,
    required String recipientId,
    required double amount,
    required String senderEmail,
    required String recipientEmail,
  }) async {
    try {
      // Security checks
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != senderId) {
        throw Exception('Unauthorized transaction');
      }

      if (senderId == recipientId) {
        throw Exception('Cannot send money to yourself');
      }

      // Get sender and recipient references
      final senderRef = _db.collection('users').doc(senderId);
      final recipientRef = _db.collection('users').doc(recipientId);

      // Use a transaction for atomic operation
      await _db.runTransaction((transaction) async {
        // Get real-time documents
        final senderDoc = await transaction.get(senderRef);
        final recipientDoc = await transaction.get(recipientRef);

        if (!senderDoc.exists || !recipientDoc.exists) {
          throw Exception('Invalid sender or recipient');
        }

        // Get current balances
        final currentSenderBalance = (senderDoc.data()?['balance'] ?? 0.0) as num;
        final currentRecipientBalance = (recipientDoc.data()?['balance'] ?? 0.0) as num;

        // Validate sender's balance
        if (currentSenderBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Calculate new balances
        final newSenderBalance = currentSenderBalance - amount;
        final newRecipientBalance = currentRecipientBalance + amount;

        // Create transaction IDs
        final debitId = _db.collection('transactions').doc().id;
        final creditId = _db.collection('transactions').doc().id;

        final now = Timestamp.now();

        // Update sender
        transaction.update(senderRef, {
          'balance': newSenderBalance,
          'lastTransactionTime': now,
        });

        // Update recipient
        transaction.update(recipientRef, {
          'balance': newRecipientBalance,
          'lastTransactionTime': now,
        });

        // Create debit transaction
        transaction.set(_db.collection('transactions').doc(debitId), {
          'userId': senderId,
          'amount': amount,
          'type': 'debit',
          'description': 'Payment to $recipientEmail',
          'timestamp': now,
          'pairedTransactionId': creditId,
          'status': 'completed',
        });

        // Create credit transaction
        transaction.set(_db.collection('transactions').doc(creditId), {
          'userId': recipientId,
          'amount': amount,
          'type': 'credit',
          'description': 'Payment from $senderEmail',
          'timestamp': now,
          'pairedTransactionId': debitId,
          'status': 'completed',
        });
      });
    } catch (e) {
      print('Payment processing error: $e');
      rethrow;
    }
  }

  // Add this method to validate transaction
  Future<bool> validateTransaction(String transactionId) async {
    try {
      final transactionDoc = await _db.collection('transactions').doc(transactionId).get();
      if (!transactionDoc.exists) return false;

      final data = transactionDoc.data();
      if (data == null) return false;

      // Check if related transaction exists
      final relatedTransactionId = data['relatedTransactionId'];
      if (relatedTransactionId == null) return false;

      final relatedDoc = await _db.collection('transactions').doc(relatedTransactionId).get();
      return relatedDoc.exists;
    } catch (e) {
      print('Error validating transaction: $e');
      return false;
    }
  }

  Future<void> updateUserPin(String uid, String pin) async {
    await _db.collection('users').doc(uid).update({'pin': pin});
  }

  Future<bool> verifyPin(String uid, String pin) async {
    final doc = await _db.collection('users').doc(uid).get();
    final userData = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    return userData.pin == pin;
  }

  // Add this method to check if PIN exists
  Future<bool> hasPin(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['pin'] != null;
    } catch (e) {
      print('Error checking PIN: $e');
      return false;
    }
  }
} 