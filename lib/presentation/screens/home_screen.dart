import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/helpers.dart';
import '../widgets/currency_calculator.dart';
import 'receipt_scanner_sheet.dart';
import 'transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onAddTransaction;
  const DashboardScreen({Key? key, this.onAddTransaction}) : super(key: key);
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.82);
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(child: _buildHeader(store)),
          // ── Bank Cards Carousel ──
          SliverToBoxAdapter(child: _buildCarousel(store)),
          // ── Month Overview ──
          SliverToBoxAdapter(child: _buildMonthOverview(store)),
          // ── Quick Actions ──
          SliverToBoxAdapter(child: _buildQuickActions(store)),
          // ── Balance Chart ──
          SliverToBoxAdapter(child: _buildBalanceChart(store)),
          // ── Recent Transactions ──
          SliverToBoxAdapter(child: _buildRecentTransactions(store)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStore store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFd4ede3), Color(0xFFF0F7F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF22c55e), size: 22),
                const SizedBox(width: 4),
                const Text('Movo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
              ]),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8)]),
                child: const Icon(Icons.notifications_none, color: Color(0xFF4b5563), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.t('total_balance'), style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                    child: Text(formatCurrency(store.totalBalance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1f2937))),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF374151), elevation: 1, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text(store.t('accounts'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(AppStore store) {
    final accounts = store.accounts;
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: 158, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFd1d5db), width: 2, strokeAlign: BorderSide.strokeAlignInside), color: Colors.white.withAlpha(153)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_circle_outline, size: 48, color: Color(0xFF9ca3af)),
              const SizedBox(height: 8),
              Text(store.lang == 'ru' ? 'Добавить счёт' : 'Add Account', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9ca3af))),
            ]),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 190, // Увеличил со 170 до 190
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: accounts.length,
            onPageChanged: (i) => setState(() => _activePage = i),
            itemBuilder: (_, i) => _BankCard(account: accounts[i], transactions: store.transactions, store: store),
          ),
        ),
        if (accounts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(accounts.length, (i) {
              final active = i == _activePage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 20 : 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? parseColor(accounts[i].color) : const Color(0xFFd1d5db),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthOverview(AppStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.t('summary'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.t('income'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                const SizedBox(height: 4),
                Row(children: [
                  Text(formatAmount(store.monthlyIncome), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                  const SizedBox(width: 8),
                  _SparkLine(color: const Color(0xFF22c55e)),
                ]),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.t('expense'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                const SizedBox(height: 4),
                Row(children: [
                  Text(formatAmount(store.monthlyExpense), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                  const SizedBox(width: 8),
                  _SparkLine(color: const Color(0xFFf97316)),
                ]),
              ])),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppStore store) {
    final actions = [
      {'label': store.t('income'), 'icon': Icons.arrow_upward, 'color': const Color(0xFF16a34a)},
      {'label': store.t('expense'), 'icon': Icons.arrow_downward, 'color': const Color(0xFFef4444)},
      {'label': store.lang == 'ru' ? 'История' : 'History', 'icon': Icons.access_time, 'color': const Color(0xFF6366f1)},
      {'label': store.lang == 'ru' ? 'Чек' : 'Check', 'icon': Icons.receipt_long, 'color': const Color(0xFFf59e0b)},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.t('quick_actions'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((a) => Column(children: [
              GestureDetector(
                onTap: () {
                  final label = a['label'] as String;
                  if (label == 'Чек' || label == 'Check') {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ReceiptScannerSheet());
                  } else if (label == store.t('income') || label == store.t('expense')) {
                    if (widget.onAddTransaction != null) widget.onAddTransaction!();
                  } else if (label == 'История' || label == 'History') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<AppStore>(), child: const TransactionsScreen())));
                  }
                },
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: (a['color'] as Color).withAlpha(30), borderRadius: BorderRadius.circular(14)),
                  child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
                ),
              ),
              const SizedBox(height: 6),
              Text(a['label'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF6b7280))),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChart(AppStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(store.t('balance_dyn'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
              Text(store.lang == 'ru' ? '30 дней' : '30 days', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: CustomPaint(size: const Size(double.infinity, 80), painter: _BalanceChartPainter(store.transactions, store.totalBalance)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(AppStore store) {
    final txs = store.transactions.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.t('recent_ops'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
            const SizedBox(height: 8),
            if (txs.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(store.t('no_ops'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)))))
            else
              ...txs.map((t) => _TransactionRow(tx: t, categories: store.categories, store: store)),
          ],
        ),
      ),
    );
  }
}

// ── Bank Card ──
class _BankCard extends StatelessWidget {
  final AccountModel account;
  final List<TransactionModel> transactions;
  final AppStore store;
  const _BankCard({required this.account, required this.transactions, required this.store});

  @override
  Widget build(BuildContext context) {
    final color = parseColor(account.color);
    final accountTx = transactions.where((t) => t.accountId == account.id).toList();
    final income = accountTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = accountTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Уменьшил вертикальный отступ
      padding: const EdgeInsets.all(14), // Уменьшил внутренний паддинг с 16 до 14
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withAlpha(238), color.withAlpha(153)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha(68), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + name
          Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.credit_card, color: Colors.white, size: 16)),
            const SizedBox(width: 8),
            Text(account.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            if (account.isShared) ...[const Spacer(), Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
              child: Text(store.lang == 'ru' ? 'Совместный' : 'Shared', style: const TextStyle(fontSize: 10, color: Colors.white)),
            )],
          ]),
          // Balance
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.lang == 'ru' ? 'Баланс' : 'Balance', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(153))),
            const SizedBox(height: 2),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(formatAmount(account.balance), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 4),
              Text(account.currency, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(179))),
            ]),
          ]),
          // Income / Expense
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.trending_up, color: Colors.white.withAlpha(204), size: 14),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.t('income'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(153))),
                  Text(formatAmount(income), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ]),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.trending_down, color: Colors.white.withAlpha(204), size: 14),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.t('expense'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(153))),
                  Text(formatAmount(expense), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ]),
            )),
          ]),
        ],
      ),
    );
  }
}

// ── Transaction Row ──
class _TransactionRow extends StatelessWidget {
  final TransactionModel tx;
  final List categories;
  final AppStore store;
  const _TransactionRow({required this.tx, required this.categories, required this.store});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? const Color(0xFF22c55e) : const Color(0xFFef4444);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(34), borderRadius: BorderRadius.circular(10)),
            child: Icon(isIncome ? Icons.trending_up : Icons.trending_down, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.description.isNotEmpty ? tx.description : store.translateCategory(tx.category, tx.category), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1f2937)), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(formatDate(tx.date, store.lang), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
          ])),
          Text(
            '${isIncome ? "+" : "-"}${formatAmount(tx.amount)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isIncome ? const Color(0xFF16a34a) : const Color(0xFFef4444)),
          ),
        ],
      ),
    );
  }
}

// ── SparkLine ──
class _SparkLine extends StatelessWidget {
  final Color color;
  const _SparkLine({required this.color});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(60, 24), painter: _SparkPainter(color));
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final data = [40, 55, 45, 60, 70, 65, 80];
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i] / 100) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Balance Chart Painter ──
class _BalanceChartPainter extends CustomPainter {
  final List<TransactionModel> transactions;
  final double totalBalance;
  _BalanceChartPainter(this.transactions, this.totalBalance);

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.length < 2) {
      final tp = TextPainter(text: TextSpan(text: transactions.isEmpty ? 'Нет данных' : 'Мало данных', style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
      return;
    }
    final data = transactions.reversed.take(13).toList();
    double running = totalBalance - data.fold<double>(0, (s, t) => s + (t.type == 'income' ? t.amount : -t.amount));
    final points = <double>[];
    for (final t in data) {
      running += t.type == 'income' ? t.amount : -t.amount;
      points.add(running);
    }

    final mn = points.reduce((a, b) => a < b ? a : b) * 0.98;
    final mx = points.reduce((a, b) => a > b ? a : b) * 1.02;
    final range = (mx - mn).abs() < 0.1 ? 1.0 : mx - mn;

    final path = Path();
    final areaPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - mn) / range) * size.height;
      if (i == 0) { path.moveTo(x, y); areaPath.moveTo(x, y); } else { path.lineTo(x, y); areaPath.lineTo(x, y); }
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    // Fill
    final fillPaint = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x3322c55e), Color(0x0022c55e)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, fillPaint);

    // Stroke
    canvas.drawPath(path, Paint()..color = const Color(0xFF22c55e)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
