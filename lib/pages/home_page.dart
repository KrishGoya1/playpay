import 'package:flutter/material.dart';
import 'balance_page.dart';
import 'scan_qr_page.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _dbService = DatabaseService();
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const BalancePage(),
    const ScanQRPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserInitialization();
  }

  Future<void> _checkUserInitialization() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dbService.initializeUserIfNeeded(user.uid, user.email ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Balance',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 