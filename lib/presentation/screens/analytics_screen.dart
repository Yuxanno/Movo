import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../core/utils/helpers.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  @override State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'month';

  /// Возвращает начало периода для фильтрации транзакций.
  /// Использует конструктор DateTime с «переполнением» месяца — Dart сам
  /// нормализует значения (например, month=0 → декабрь прошлого года).
  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case 'month':
        // Начало текущего месяца: 1-е число, 00:00:00
        return DateTime(now.year, now.month, 1);
      case '3m':
        // Ровно 3 месяца назад, начало того месяца
        return DateTime(now.year, now.month - 2, 1);
      case 'year':
        // Начало текущего года
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  /// Возвращает точный диапазон (start, end) для конкретного месяца
  /// по смещению [monthOffset] от [base] (0 = текущий, -1 = прошлый и т.д.).
  /// DateTime с month=0 → декабрь прошлого года — Dart обрабатывает автоматически.
  ({DateTime start, DateTime end}) _monthRange(DateTime base, int monthOffset) {
    final year = base.year;
    final month = base.month + monthOffset; // может быть 0 или отрицательным — ОК
    final start = DateTime(year, month, 1);
    // month+1, день 0 = последний день месяца; устанавливаем 23:59:59
    final end = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));
    return (start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final now = DateTime.now();

    final periodStart = _periodStart(now);
    final filtered = store.transactions.where((t) => !t.date.isBefore(periodStart)).toList();
    final expenses = filtered.where((t) => t.type == 'expense').toList();
    final incomes = filtered.where((t) => t.type == 'income').toList();
    final totalIncome = incomes.fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = expenses.fold<double>(0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    // Monthly bars (last 6 months) — смещения: -5, -4, -3, -2, -1, 0
    final monthlyIncome = List.generate(6, (i) {
      final range = _monthRange(now, i - 5);
      return store.transactions
          .where((t) => t.type == 'income' &&
              !t.date.isBefore(range.start) &&
              !t.date.isAfter(range.end))
          .fold<double>(0, (s, t) => s + t.amount);
    });
    final monthlyExpense = List.generate(6, (i) {
      final range = _monthRange(now, i - 5);
      return store.transactions
          .where((t) => t.type == 'expense' &&
              !t.date.isBefore(range.start) &&
              !t.date.isAfter(range.end))
          .fold<double>(0, (s, t) => s + t.amount);
    });

    // Category breakdown
    final Map<String, double> byCategory = {};
    for (final t in expenses) { byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount; }
    final pieData = byCategory.entries.map((e) {
      final cat = store.categories.where((c) => c.icon == e.key || c.name == e.key).firstOrNull;
      final name = store.translateCategory(cat?.name ?? e.key, cat?.name ?? e.key);
      return {'name': name, 'color': cat?.color ?? '#9ca3af', 'value': e.value};
    }).toList()..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
    final top5 = pieData.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header + period picker
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(store.t('analytics'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                child: Row(children: [
                  for (final p in [['month', store.t('month_short')], ['3m', store.t('3m_short')], ['year', store.t('year_short')]])
                    GestureDetector(
                      onTap: () => setState(() => _period = p[0]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _period == p[0] ? const Color(0xFF16a34a) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                        child: Text(p[1], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _period == p[0] ? Colors.white : const Color(0xFF6b7280))),
                      ),
                    ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            // Balance card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF16a34a)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF22c55e).withAlpha(51), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.t('balance_period'), style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(204))),
                const SizedBox(height: 4),
                Text('${balance >= 0 ? "+" : ""}${formatAmount(balance)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.t('income'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                        Text(formatAmount(totalIncome), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ]),
                    ]),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.t('expense'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                        Text(formatAmount(totalExpense), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ]),
                    ]),
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // Bar chart
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(store.t('by_months'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF22c55e), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4), Text(store.t('income'), style: const TextStyle(fontSize: 10, color: Color(0xFF9ca3af))),
                    const SizedBox(width: 10),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFef4444), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4), Text(store.t('expense'), style: const TextStyle(fontSize: 10, color: Color(0xFF9ca3af))),
                  ]),
                ]),
                const SizedBox(height: 10),
                SizedBox(height: 112, child: CustomPaint(size: const Size(double.infinity, 112), painter: _BarChartPainter(
                  monthlyIncome,
                  monthlyExpense,
                  // Реальные номера месяцев (1–12) для 6 столбцов через DateTime-нормализацию
                  List.generate(6, (i) => DateTime(now.year, now.month + (i - 5)).month),
                  store,
                ))),
              ]),
            ),
            const SizedBox(height: 14),

            // Category breakdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.t('by_categories'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                const SizedBox(height: 12),
                if (top5.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(store.t('no_expenses'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)))))
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 88, height: 88, child: CustomPaint(painter: _DonutPainter(top5.map((d) => {'value': d['value'] as double, 'color': d['color'] as String}).toList()))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(children: top5.map((d) {
                      final pct = totalExpense > 0 ? ((d['value'] as double) / totalExpense * 100).round() : 0;
                      final color = parseColor(d['color'] as String);
                      return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(d['name'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis),
                          ]),
                          Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: const Color(0xFFF3F4F6), valueColor: AlwaysStoppedAnimation(color), minHeight: 4)),
                      ]));
                    }).toList())),
                  ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> income, expense;
  /// Реальные номера месяцев (1–12) для каждого из 6 столбцов,
  /// вычисленные через DateTime чтобы корректно пересекать год.
  final List<int> monthNumbers;
  final AppStore store;
  _BarChartPainter(this.income, this.expense, this.monthNumbers, this.store);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [...income, ...expense, 1.0].reduce((a, b) => a > b ? a : b);
    final barAreaH = size.height - 16;
    final barW = size.width / 6;

    for (int i = 0; i < 6; i++) {
      final isNow = i == 5;
      final x = i * barW;
      final gapW = barW * 0.1;
      final halfW = (barW - gapW * 3) / 2;

      // Income bar
      final incH = income[i] > 0 ? max(3.0, (income[i] / maxVal) * barAreaH) : 0.0;
      final incPaint = Paint()..color = isNow ? const Color(0xFF22c55e) : const Color(0xFF22c55e).withAlpha(68);
      canvas.drawRRect(RRect.fromLTRBR(x + gapW, barAreaH - incH, x + gapW + halfW, barAreaH, const Radius.circular(2)), incPaint);

      // Expense bar
      final expH = expense[i] > 0 ? max(3.0, (expense[i] / maxVal) * barAreaH) : 0.0;
      final expPaint = Paint()..color = isNow ? const Color(0xFFef4444) : const Color(0xFFef4444).withAlpha(68);
      canvas.drawRRect(RRect.fromLTRBR(x + gapW * 2 + halfW, barAreaH - expH, x + gapW * 2 + halfW * 2, barAreaH, const Radius.circular(2)), expPaint);

      // Month label — используем реальный номер месяца (1-based)
      final label = store.t('ms${monthNumbers[i]}');
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 9, color: isNow ? const Color(0xFF374151) : const Color(0xFF9ca3af), fontWeight: isNow ? FontWeight.w600 : FontWeight.normal)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, size.height - 14));
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _DonutPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (s, d) => s + (d['value'] as double));
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 14.0;
    double startAngle = -pi / 2;

    // Background ring
    canvas.drawCircle(center, radius - strokeWidth / 2, Paint()..color = const Color(0xFFF3F4F6)..style = PaintingStyle.stroke..strokeWidth = strokeWidth);

    for (final d in data) {
      final sweep = ((d['value'] as double) / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle, sweep,
        false,
        Paint()..color = parseColor(d['color'] as String)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
