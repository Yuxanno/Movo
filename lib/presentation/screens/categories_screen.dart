import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/category_model.dart';
import '../../core/utils/helpers.dart';

const _iconOptions = [
  {'id': 'shopping-cart', 'icon': Icons.shopping_cart_outlined},
  {'id': 'car', 'icon': Icons.directions_car_outlined},
  {'id': 'film', 'icon': Icons.movie_outlined},
  {'id': 'briefcase', 'icon': Icons.work_outline},
  {'id': 'zap', 'icon': Icons.bolt_outlined},
  {'id': 'utensils', 'icon': Icons.restaurant_outlined},
  {'id': 'plane', 'icon': Icons.flight_outlined},
  {'id': 'heart', 'icon': Icons.favorite_border},
  {'id': 'graduation', 'icon': Icons.school_outlined},
  {'id': 'home', 'icon': Icons.home_outlined},
  {'id': 'gift', 'icon': Icons.card_giftcard_outlined},
  {'id': 'shirt', 'icon': Icons.checkroom_outlined},
  {'id': 'dumbbell', 'icon': Icons.fitness_center_outlined},
  {'id': 'music', 'icon': Icons.music_note_outlined},
  {'id': 'coffee', 'icon': Icons.coffee_outlined},
  {'id': 'tag', 'icon': Icons.label_outline},
];

const _colors = ['#22c55e', '#6366f1', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316', '#64748b'];

IconData _iconById(String id) {
  final found = _iconOptions.where((o) => o['id'] == id).firstOrNull;
  return (found?['icon'] as IconData?) ?? Icons.label_outline;
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);
  @override State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _filter = 'expense';
  bool _showForm = false;
  String _formName = '';
  String _formIcon = 'tag';
  String _formColor = '#22c55e';
  String _formType = 'expense';
  bool _saving = false;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStore>().fetchCategories();
      context.read<AppStore>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_formName.trim().isEmpty) return;
    setState(() => _saving = true);
    await context.read<AppStore>().addCategory({
      'name': _formName.trim(),
      'icon': _formIcon,
      'color': _formColor,
      'type': _formType,
    });
    setState(() {
      _saving = false;
      _showForm = false;
      _formName = '';
      _formIcon = 'tag';
      _formColor = '#22c55e';
      _formType = 'expense';
      _nameCtrl.clear();
    });
  }

  double _totalByCategory(CategoryModel cat, AppStore store) =>
      store.transactions.where((t) => (t.category == cat.icon || t.category == cat.name) && t.type == 'expense').fold(0, (s, t) => s + t.amount);

  double _monthByCategory(CategoryModel cat, AppStore store) {
    final now = DateTime.now();
    return store.transactions.where((t) {
      return (t.category == cat.icon || t.category == cat.name) &&
          t.type == 'expense' &&
          t.date.month == now.month &&
          t.date.year == now.year;
    }).fold(0, (s, t) => s + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final now = DateTime.now();

    final totalExpenses = store.transactions.where((t) {
      return t.type == 'expense' && t.date.month == now.month && t.date.year == now.year;
    }).fold<double>(0, (s, t) => s + t.amount);

    final filtered = store.categories.where((c) => c.type == _filter && c.icon != '__receipt__').toList();
    final donutData = filtered.map((c) => {'value': _monthByCategory(c, store), 'color': c.color}).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: Stack(
        children: [
          Column(children: [
            // Header
            Container(
              color: const Color(0xFFF0F7F4),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(store.t('categories'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => _showForm = !_showForm),
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF16a34a), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.add, color: Colors.white, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF6b7280))),
                  ),
                ]),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('${store.t('expense')} за месяц: ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                        Text(formatAmount(totalExpenses), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16a34a))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        SizedBox(width: 88, height: 88, child: CustomPaint(painter: _DonutPainter(donutData))),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: filtered.take(4).map((c) {
                          final val = _monthByCategory(c, store);
                          final pct = totalExpenses > 0 ? (val / totalExpenses * 100).round() : 0;
                          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: parseColor(c.color), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(store.translateCategory(c.name, c.icon), style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                            Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                          ]));
                        }).toList())),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Filter
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                    child: Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _filter = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == 'expense' ? const Color(0xFF16a34a) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(store.t('expense'), textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                color: _filter == 'expense' ? Colors.white : const Color(0xFF6b7280))),
                          ),
                        )),
                        Expanded(child: GestureDetector(
                          onTap: () => setState(() => _filter = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == 'income' ? const Color(0xFF16a34a) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(store.t('income'), textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                color: _filter == 'income' ? Colors.white : const Color(0xFF6b7280))),
                          ),
                        )),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // List
                  Text(store.t('categories') + ' (список)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Column(children: [
                      Icon(Icons.label_outline, size: 40, color: Color(0xFFd1d5db)),
                      SizedBox(height: 8),
                      Text('Нет категорий', style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
                    ])))
                  else
                    ...filtered.map((cat) => _CategoryRow(
                      cat: cat,
                      name: store.translateCategory(cat.name, cat.icon),
                      total: _totalByCategory(cat, store),
                      monthTotal: _monthByCategory(cat, store),
                      onDelete: () => store.deleteCategory(cat.id),
                    )),
                ],
              ),
            ),
          ]),
          // Add form bottom sheet
          if (_showForm) _buildAddForm(),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return GestureDetector(
      onTap: () => setState(() => _showForm = false),
      child: Container(
        color: Colors.black.withAlpha(102),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Новая категория', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                  GestureDetector(
                    onTap: () => setState(() => _showForm = false),
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.close, size: 14, color: Color(0xFF6b7280))),
                  ),
                ]),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => _formName = v,
                  decoration: InputDecoration(
                    hintText: 'Название',
                    hintStyle: const TextStyle(color: Color(0xFF9ca3af)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  for (final t in [['expense', 'Расход'], ['income', 'Доход']])
                    Expanded(child: Padding(
                      padding: EdgeInsets.only(right: t[0] == 'expense' ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _formType = t[0]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _formType == t[0] ? const Color(0xFF16a34a) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(t[1], textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: _formType == t[0] ? Colors.white : const Color(0xFF4b5563))),
                        ),
                      ),
                    )),
                ]),
                const SizedBox(height: 12),
                const Text('Иконка', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: _iconOptions.map((ic) {
                  final selected = _formIcon == ic['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _formIcon = ic['id'] as String),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: selected ? parseColor(_formColor).withAlpha(34) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: selected ? Border.all(color: parseColor(_formColor), width: 1.5) : null,
                      ),
                      child: Icon(ic['icon'] as IconData, size: 16,
                        color: selected ? parseColor(_formColor) : const Color(0xFF6b7280)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 12),
                const Text('Цвет', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: _colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _formColor = c),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: parseColor(c),
                      shape: BoxShape.circle,
                      border: _formColor == c ? Border.all(color: Colors.white, width: 2) : null,
                      boxShadow: _formColor == c ? [BoxShadow(color: parseColor(c).withAlpha(102), blurRadius: 6)] : null,
                    ),
                  ),
                )).toList()),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_saving || _formName.trim().isEmpty) ? null : _addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_saving ? 'Сохранение...' : 'Добавить', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel cat;
  final String name;
  final double total;
  final double monthTotal;
  final VoidCallback onDelete;
  const _CategoryRow({required this.cat, required this.name, required this.total, required this.monthTotal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = parseColor(cat.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(34), borderRadius: BorderRadius.circular(14)),
          child: Icon(_iconById(cat.icon), size: 22, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
          const Text('Текущий месяц', style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatAmount(total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
          Text(monthTotal > 0 ? '−${formatAmount(monthTotal)}' : '—',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFf87171)),
        ),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _DonutPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (s, d) => s + ((d['value'] as double?) ?? 0));
    if (total == 0) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 7,
        Paint()..color = const Color(0xFFF3F4F6)..style = PaintingStyle.stroke..strokeWidth = 14);
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const strokeWidth = 14.0;
    double startAngle = -pi / 2;

    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF3F4F6)..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

    for (final d in data) {
      final val = (d['value'] as double?) ?? 0;
      if (val <= 0) continue;
      final sweep = (val / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, false,
        Paint()..color = parseColor(d['color'] as String)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
