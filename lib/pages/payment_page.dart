import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../widgets/pin_verification_dialog.dart';

class PaymentPage extends StatefulWidget {
  final String recipientId;
  final String recipientEmail;

  const PaymentPage({
    super.key,
    required this.recipientId,
    required this.recipientEmail,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isProcessing = false;
  UserModel? _senderData;

  @override
  void initState() {
    super.initState();
    _loadSenderData();
  }

  Future<void> _loadSenderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _senderData = await _dbService.getUserData(user.uid);
      setState(() {});
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Get user data to check if PIN is set
    final userData = await _dbService.getUserData(currentUser.uid);
    if (userData?.pin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set up your transaction PIN first')),
        );
      }
      return;
    }

    // Show PIN verification dialog
    final enteredPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinVerificationDialog(),
    );

    if (enteredPin == null) return;

    // Verify PIN
    final isCorrect = await _dbService.verifyPin(currentUser.uid, enteredPin);
    if (!isCorrect) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
      return;
    }

    // Continue with existing payment processing logic
    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      if (currentUser.uid == widget.recipientId) {
        throw Exception('Cannot send money to yourself');
      }

      if (_senderData!.balance < amount) {
        throw Exception('Insufficient balance');
      }

      await _dbService.processPayment(
        senderId: currentUser.uid,
        recipientId: widget.recipientId,
        amount: amount,
        senderEmail: currentUser.email ?? 'Unknown',
        recipientEmail: widget.recipientEmail,
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text('Successfully sent ₹${amount.toStringAsFixed(2)} to ${widget.recipientEmail}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Return to home page
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showConfirmationDialog() async {
    final amount = double.parse(_amountController.text);
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('To: ${widget.recipientEmail}'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Send Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top curved container with recipient info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.recipientEmail[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.recipientEmail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Card
                    if (_senderData != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
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
                              '₹${_senderData!.balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Amount Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          if (_senderData != null && amount > _senderData!.balance) {
                            return 'Insufficient balance';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Payment Button
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _showConfirmationDialog();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Send Payment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 