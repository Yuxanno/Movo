import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';

class AddTransactionSheet extends StatefulWidget {
  final String initialType;
  const AddTransactionSheet({Key? key, this.initialType = 'expense'}) : super(key: key);
  @override State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late String _type;
  String _amount = '';
  String _currency = 'UZS';
  String _category = '';
  String _description = '';
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final store = context.read<AppStore>();
    if (store.accounts.isNotEmpty) _accountId = store.accounts.first.id;
    if (store.categories.isEmpty) store.fetchCategories();
  }

  Future<void> _submit() async {
    if (_amount.isEmpty || _accountId == null) return;
    setState(() => _saving = true);
    await context.read<AppStore>().addTransaction({
      'accountId': _accountId,
      'type': _type,
      'amount': double.tryParse(_amount) ?? 0,
      'currency': _currency,
      'category': _category,
      'description': _description,
      'date': DateTime.now().toIso8601String(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final filteredCats = store.categories.where((c) => c.type == _type || c.type == 'both').toList();
    if (filteredCats.isNotEmpty && (_category.isEmpty || !filteredCats.any((c) => c.icon == _category))) {
      _category = filteredCats.first.icon;
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFd1d5db), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          // Title
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(store.t('new_op'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF9ca3af))),
          ]),
          const SizedBox(height: 16),

          // Type toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              for (final t in ['expense', 'income'])
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _type == t ? (t == 'expense' ? const Color(0xFFef4444) : const Color(0xFF16a34a)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t == 'expense' ? store.t('expense') : store.t('income'), textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _type == t ? Colors.white : const Color(0xFF6b7280))),
                  ),
                )),
            ]),
          ),
          const SizedBox(height: 16),

          // Amount + Currency
          Row(children: [
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) => _amount = v,
              decoration: InputDecoration(hintText: store.t('amount'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            )),
            const SizedBox(width: 8),
            ...['UZS', 'USD', 'RUB'].map((c) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(color: _currency == c ? const Color(0xFF16a34a) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                  child: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _currency == c ? Colors.white : const Color(0xFF4b5563))),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 16),

          // Account
          DropdownButtonFormField<String>(
            value: _accountId,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: store.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) => _accountId = v,
          ),
          const SizedBox(height: 16),

          // Category
          Text(store.t('category'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
          const SizedBox(height: 8),
          if (filteredCats.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Wrap(spacing: 8, runSpacing: 8, children: filteredCats.map((c) {
              final selected = _category == c.icon;
              final color = parseColor(c.color);
              final localizedName = store.translateCategory(c.name, c.name);
              return GestureDetector(
                onTap: () => setState(() => _category = c.icon),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: selected ? color : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                  child: Text(localizedName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF4b5563))),
                ),
              );
            }).toList()),
          const SizedBox(height: 16),

          // Description
          TextField(
            onChanged: (v) => _description = v,
            decoration: InputDecoration(hintText: store.t('description_hint'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || _amount.isEmpty || _accountId == null ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: const Color(0xFF16a34a).withAlpha(128)),
              child: Text(_saving ? store.t('saving') : store.t('add'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ]),
      ),
    );
  }

  Color parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); }
    catch (_) { return const Color(0xFF9ca3af); }
  }
}
