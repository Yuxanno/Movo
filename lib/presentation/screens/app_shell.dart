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

  void _onTabTap(int idx) {
    if (idx == 4) {
      final store = context.read<AppStore>();
      store.loadPinStatus();
      store.loadBiometrics();
    }
    setState(() => _index = idx);
  }

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
      const SizedBox(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    final store = context.watch<AppStore>();

    return Scaffold(
      body: IndexedStack(index: _index == 2 ? 0 : _index, children: screens),
      floatingActionButton: _FabButton(onTap: _showAddTransaction),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: _onTabTap,
        store: store,
      ),
    );
  }
}

// ── FAB ──────────────────────────────────────────────────────────────────────
class _FabButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF16a34a).withAlpha(100), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final AppStore store;
  const _BottomNav({required this.index, required this.onTap, required this.store});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: store.t('dashboard'),
        idx: 0,
      ),
      _NavItemData(
        icon: Icons.credit_card_outlined,
        activeIcon: Icons.credit_card,
        label: store.t('accounts'),
        idx: 1,
      ),
      _NavItemData(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: store.t('analytics'),
        idx: 3,
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: store.t('step_profile'),
        idx: 4,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Left two items
              Expanded(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.take(2).map((item) => _NavTile(
                  data: item,
                  active: index == item.idx,
                  onTap: () => onTap(item.idx),
                )).toList(),
              )),
              // FAB space
              const SizedBox(width: 72),
              // Right two items
              Expanded(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.skip(2).map((item) => _NavTile(
                  data: item,
                  active: index == item.idx,
                  onTap: () => onTap(item.idx),
                )).toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav item data ─────────────────────────────────────────────────────────────
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int idx;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label, required this.idx});
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItemData data;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({required this.data, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF16a34a);
    const inactiveColor = Color(0xFFa0aec0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16a34a).withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? data.activeIcon : data.icon,
                key: ValueKey(active),
                color: active ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? activeColor : inactiveColor,
              ),
              child: Text(data.label),
            ),
          ],
        ),
      ),
    );
  }
}
