import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'accounts_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_sheet.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';

class AppShell extends StatefulWidget {
  const AppShell({Key? key}) : super(key: key);
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppStore>(),
        child: const AddTransactionSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onAddTransaction: _showAddTransaction),
      const AccountsScreen(),
      const SizedBox(), // placeholder for FAB tab
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index == 2 ? 0 : _index, children: screens),
      floatingActionButton: SizedBox(
        width: 56, height: 56,
        child: FloatingActionButton(
          onPressed: _showAddTransaction,
          backgroundColor: const Color(0xFF16a34a),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        notchMargin: 6,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home, label: 'Dashboard', active: _index == 0, onTap: () => setState(() => _index = 0)),
              _NavItem(icon: Icons.credit_card, label: 'Счета', active: _index == 1, onTap: () => setState(() => _index = 1)),
              const SizedBox(width: 48), // Space for FAB
              _NavItem(icon: Icons.bar_chart, label: 'Аналитика', active: _index == 3, onTap: () => setState(() => _index = 3)),
              _NavItem(icon: Icons.person_outline, label: 'Профиль', active: _index == 4, onTap: () => setState(() => _index = 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16a34a) : const Color(0xFF9ca3af);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}
