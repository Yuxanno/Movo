import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/helpers.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);
  @override State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all';
  String _search = '';
  String? _confirmId;
  bool _deleting = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<AppStore>();
      store.fetchTransactions();
      store.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _getCatInfo(String key, AppStore store) {
    if (key == '__receipt__') return {'name': store.t('receipt_scanner'), 'color': '#f59e0b'};
    final c = store.categories.where((c) => c.icon == key || c.name == key).firstOrNull;
    final name = store.translateCategory(c?.name ?? key, c?.name ?? key);
    return {'name': name, 'color': c?.color ?? '#9ca3af'};
  }

  String _getAccountName(String id, AppStore store) =>
      store.accounts.where((a) => a.id == id).firstOrNull?.name ?? '—';

  Future<void> _delete(String id) async {
    setState(() => _deleting = true);
    try {
      await context.read<AppStore>().deleteTransaction(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: const Color(0xFFef4444)),
        );
      }
    } finally {
      if (mounted) setState(() { _deleting = false; _confirmId = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    final filtered = store.transactions
        .where((t) => _filter == 'all' || t.type == _filter)
        .where((t) {
          if (_search.isEmpty) return true;
          final s = _search.toLowerCase();
          final cat = _getCatInfo(t.category, store);
          return (t.description.toLowerCase().contains(s)) ||
              (cat['name']!.toLowerCase().contains(s)) ||
              (_getAccountName(t.accountId, store).toLowerCase().contains(s));
        })
        .toList();

    // Group by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filtered) {
      final key = _formatGroupDate(tx.date, store);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(store.t('history'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.close, size: 16, color: Color(0xFF6b7280))),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Search
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.search, size: 16, color: Color(0xFF9ca3af)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: store.t('search_hint'),
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
                          border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      )),
                      if (_search.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _search = ''); },
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF9ca3af)),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // Filter tabs
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      for (final f in [['all', store.t('all')], ['income', store.t('income')], ['expense', store.t('expense')]])
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _filter = f[0]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _filter == f[0] ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _filter == f[0] ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)] : null,
                            ),
                            child: Text(f[1], textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                color: _filter == f[0] ? const Color(0xFF1f2937) : const Color(0xFF6b7280))),
                          ),
                        )),
                    ]),
                  ),
                ]),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.filter_list, size: 40, color: Color(0xFFe5e7eb)),
                        const SizedBox(height: 8),
                        Text(store.t('no_txs'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
                      ]))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: grouped.entries.map((entry) => _buildGroup(entry.key, entry.value, store)).toList(),
                      ),
              ),
            ],
          ),
          // Delete confirm bottom sheet
          if (_confirmId != null) _buildDeleteConfirm(store),
        ],
      ),
    );
  }

  Widget _buildGroup(String date, List<TransactionModel> txs, AppStore store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af), fontWeight: FontWeight.w500)),
        ),
        ...txs.asMap().entries.map((e) {
          final tx = e.value;
          final isLast = e.key == txs.length - 1;
          final cat = _getCatInfo(tx.category, store);
          final color = parseColor(cat['color']!);
          final isIncome = tx.type == 'income';
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withAlpha(34), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: color, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tx.description.isNotEmpty ? tx.description : cat['name']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1f2937)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${cat['name']} · ${_getAccountName(tx.accountId, store)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                ])),
                const SizedBox(width: 8),
                Text('${isIncome ? "+" : "−"}${formatAmount(tx.amount)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isIncome ? const Color(0xFF16a34a) : const Color(0xFFef4444))),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _confirmId = tx.id),
                  child: Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF9ca3af))),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: Color(0xFFF9FAFB), indent: 16, endIndent: 16),
          ]);
        }),
      ]),
    );
  }

  Widget _buildDeleteConfirm(AppStore store) {
    return GestureDetector(
      onTap: () => setState(() => _confirmId = null),
      child: Container(
        color: Colors.black.withAlpha(102),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.t('delete_tx_q'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                const SizedBox(height: 6),
                Text(store.t('delete_tx_desc'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _confirmId = null),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                      child: Text(store.t('cancel'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)))),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: _deleting ? null : () => _delete(_confirmId!),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFFef4444), borderRadius: BorderRadius.circular(12)),
                      child: Text(_deleting ? store.t('deleting') : store.t('delete'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white))),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _formatGroupDate(DateTime d, AppStore store) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return store.t('today');
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) return store.t('yesterday');
    return '${d.day} ${store.t('m${d.month}')} ${d.year}';
  }
}
