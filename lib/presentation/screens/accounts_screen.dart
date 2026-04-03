import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/account_model.dart';
import '../../core/utils/helpers.dart';

const _colors = ['#22c55e', '#6366f1', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6'];
const _currencies = ['UZS', 'USD', 'RUB'];

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);
  @override State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  AccountModel? _selected;
  bool _showForm = false;
  String _name = '';
  String _icon = 'card';
  String _currency = 'UZS';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addAccount() async {
    if (_name.trim().isEmpty) return;
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    final color = _colors[store.accounts.length % _colors.length];
    await store.addAccount({'name': _name, 'icon': _icon, 'color': color, 'balance': 0, 'currency': _currency, 'isShared': false});
    await store.fetchAccounts();
    setState(() { _name = ''; _icon = 'card'; _currency = 'UZS'; _showForm = false; _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _AccountDetail(account: _selected!, onBack: () => setState(() => _selected = null));

    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Мои счета', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF16a34a), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.add, color: Colors.white, size: 20)),
              ),
            ]),
            const SizedBox(height: 16),

            // Add form
            if (_showForm) _buildForm(),

            // Account list
            if (store.accounts.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(children: [
                  const Icon(Icons.credit_card, size: 48, color: Color(0xFFd1d5db)),
                  const SizedBox(height: 12),
                  const Text('Нет счетов. Создайте первый!', style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
                ]),
              ))
            else
              ...store.accounts.map((a) => _AccountCard(
                account: a,
                onTap: () => setState(() => _selected = a),
                onDelete: () => store.deleteAccount(a.id),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Новый счёт', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => _name = v,
          decoration: InputDecoration(hintText: 'Название (Дом, Семья, Бизнес...)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
        ),
        const SizedBox(height: 12),
        const Text('Валюта', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
        const SizedBox(height: 6),
        Row(children: _currencies.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _currency = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: _currency == c ? const Color(0xFF16a34a) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
              child: Text(c, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _currency == c ? Colors.white : const Color(0xFF4b5563))),
            ),
          ),
        )).toList()),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _addAccount,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(_saving ? 'Сохранение...' : 'Создать счёт', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _AccountCard({required this.account, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = parseColor(account.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(account.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                Text(account.currency, style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
              ]),
            ]),
            GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFd1d5db))),
          ]),
          const SizedBox(height: 12),
          RichText(text: TextSpan(children: [
            TextSpan(text: formatAmount(account.balance), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            TextSpan(text: ' ${account.currency}', style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
          ])),
        ]),
      ),
    );
  }
}

class _AccountDetail extends StatefulWidget {
  final AccountModel account;
  final VoidCallback onBack;
  const _AccountDetail({required this.account, required this.onBack});
  @override State<_AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<_AccountDetail> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AppStore>().fetchTransactions(accountId: widget.account.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final color = parseColor(widget.account.color);
    final txs = store.transactions
        .where((t) => t.accountId == widget.account.id)
        .where((t) => _filter == 'all' || t.type == _filter)
        .toList();
    final income = store.transactions.where((t) => t.accountId == widget.account.id && t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = store.transactions.where((t) => t.accountId == widget.account.id && t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Row(children: [
                const Icon(Icons.arrow_back, size: 18, color: Color(0xFF6b7280)),
                const SizedBox(width: 8),
                const Text('Назад', style: TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
              ]),
            ),
            const SizedBox(height: 16),
            // Account card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withAlpha(238), color.withAlpha(153)]), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.credit_card, color: Colors.white, size: 16)),
                  const SizedBox(width: 8),
                  Text(widget.account.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
                const SizedBox(height: 12),
                RichText(text: TextSpan(children: [
                  TextSpan(text: formatAmount(widget.account.balance), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: ' ${widget.account.currency}', style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(179))),
                ])),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Доходы', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                      Text('+${formatAmount(income)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Расходы', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                      Text('−${formatAmount(expense)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            // Filter tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
              child: Row(children: [
                for (final f in [['all', 'Все'], ['income', 'Доходы'], ['expense', 'Расходы']])
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _filter = f[0]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: _filter == f[0] ? const Color(0xFF16a34a) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text(f[1], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _filter == f[0] ? Colors.white : const Color(0xFF6b7280))),
                    ),
                  )),
              ]),
            ),
            const SizedBox(height: 16),
            if (txs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Text('Нет транзакций', style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)))))
            else
              ...txs.map((t) {
                final isIncome = t.type == 'income';
                final txColor = isIncome ? const Color(0xFF22c55e) : const Color(0xFFef4444);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: txColor.withAlpha(34), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: txColor, size: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.description.isNotEmpty ? t.description : t.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1f2937))),
                      Text('${formatDate(t.date)} · ${t.category}', style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                    ])),
                    Text('${isIncome ? "+" : "−"}${formatAmount(t.amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txColor)),
                  ]),
                );
              }),
          ]),
        ),
      ),
    );
  }
}
