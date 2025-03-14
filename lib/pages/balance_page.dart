import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
import 'scan_qr_page.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final DatabaseService _dbService = DatabaseService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    if (currentUser != null && mounted) {
      final userData = await _dbService.getUserData(currentUser!.uid);
      if (userData == null) {
        final newUser = UserModel(
          uid: currentUser!.uid,
          email: currentUser!.email ?? '',
          balance: 0.0,
          transactions: [],
        );
        await _dbService.saveUserData(newUser);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your balance'));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PlayPay Logo and Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // PlayPay Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PlayPay',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<UserModel?>(
                    future: _dbService.getUserData(currentUser!.uid),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Your Piggy Bank',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${user?.balance.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.qr_code,
                        label: 'My QR Code',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Pay Friend',
                        color: AppTheme.secondaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanQRPage()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transaction History
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _dbService.getUserTransactions(currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final transactions = snapshot.data ?? [];

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: transaction.type == 'credit'
                                  ? AppTheme.secondaryColor.withOpacity(0.3)
                                  : AppTheme.errorColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: transaction.type == 'credit'
                                    ? AppTheme.secondaryColor.withOpacity(0.2)
                                    : AppTheme.errorColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                transaction.type == 'credit'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: transaction.type == 'credit'
                                    ? AppTheme.secondaryColor
                                    : AppTheme.errorColor,
                              ),
                            ),
                            title: Text(
                              '₹${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: transaction.type == 'credit'
                                    ? AppTheme.secondaryColor
                                    : AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm')
                                      .format(transaction.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 