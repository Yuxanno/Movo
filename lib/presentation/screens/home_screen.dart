import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/helpers.dart';
import 'receipt_scanner_sheet.dart';
import 'transactions_screen.dart';

const _homeAccountIcons = <String, IconData>{
  'card':       Icons.credit_card,
  'wallet':     Icons.account_balance_wallet,
  'bank':       Icons.account_balance,
  'cash':       Icons.payments,
  'savings':    Icons.savings,
  'home':       Icons.home,
  'business':   Icons.business_center,
  'family':     Icons.family_restroom,
  'shopping':   Icons.shopping_bag,
  'travel':     Icons.flight,
  'car':        Icons.directions_car,
  'phone':      Icons.phone_android,
  'star':       Icons.star,
  'gift':       Icons.card_giftcard,
  'crypto':     Icons.currency_bitcoin,
  'investment': Icons.trending_up,
};

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onAddTransaction;
  const DashboardScreen({Key? key, this.onAddTransaction}) : super(key: key);
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _activePage = 0;

  List<double> _last7DaysAmounts(List<TransactionModel> txs, String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return txs
          .where((t) => t.type == type && !t.date.isBefore(day) && t.date.isBefore(day.add(const Duration(days: 1))))
          .fold(0.0, (s, t) => s + t.amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: RefreshIndicator(
        color: const Color(0xFF16a34a),
        onRefresh: () async {
          await Future.wait([store.fetchAccounts(), store.fetchTransactions()]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(store)),
            SliverToBoxAdapter(child: _buildCarousel(store)),
            SliverToBoxAdapter(child: _buildOverview(store)),
            SliverToBoxAdapter(child: _buildQuickActions(store)),
            SliverToBoxAdapter(child: _buildChart(store)),
            SliverToBoxAdapter(child: _buildRecentTxs(store)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(AppStore store) {
    final name = store.userName?.isNotEmpty == true ? store.userName! : 'Друг';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFd4ede3), Color(0xFFF0F7F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Топ строка ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(14), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset('public/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${store.t('hi')}, $name!',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af), fontWeight: FontWeight.w400)),
                  const Text('Movo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                ]),
              ]),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF374151), size: 20),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Баланс + кнопка счетов ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.t('total_balance'),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCurrency(store.totalBalance),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1f2937),
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF374151),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(store.t('accounts'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Карусель счетов ──────────────────────────────────────────────────────

  Widget _buildCarousel(AppStore store) {
    final accounts = store.accounts;
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFe5e7eb), width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF9ca3af)),
            const SizedBox(width: 8),
            Text(store.t('add_account'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
          ]),
        ),
      );
    }
    return Column(children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _pageCtrl,
          itemCount: accounts.length,
          onPageChanged: (i) => setState(() => _activePage = i),
          itemBuilder: (_, i) => _BankCard(
            account: accounts[i],
            transactions: store.transactions,
            store: store,
          ),
        ),
      ),
      if (accounts.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(accounts.length, (i) {
            final active = i == _activePage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: active ? 18 : 5, height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active ? parseColor(accounts[i].color) : const Color(0xFFd1d5db),
              ),
            );
          }),
        ),
      ],
      const SizedBox(height: 16),
    ]);
  }

  // ─── Обзор месяца ─────────────────────────────────────────────────────────

  Widget _buildOverview(AppStore store) {
    final incomeData  = _last7DaysAmounts(store.transactions, 'income');
    final expenseData = _last7DaysAmounts(store.transactions, 'expense');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(store.t('summary'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store.t('income'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
              const SizedBox(height: 4),
              Row(children: [
                Text(formatAmount(store.monthlyIncome),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60, height: 24,
                  child: CustomPaint(
                    painter: _SparkPainter(const Color(0xFF22c55e), incomeData),
                  ),
                ),
              ]),
            ])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store.t('expense'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
              const SizedBox(height: 4),
              Row(children: [
                Text(formatAmount(store.monthlyExpense),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60, height: 24,
                  child: CustomPaint(
                    painter: _SparkPainter(const Color(0xFFf97316), expenseData),
                  ),
                ),
              ]),
            ])),
          ]),
        ]),
      ),
    );
  }

  // ─── Быстрые действия ─────────────────────────────────────────────────────

  Widget _buildQuickActions(AppStore store) {
    final actions = [
      {'label': store.t('income'),      'icon': Icons.arrow_upward_rounded,   'bg': const Color(0xFFdcfce7), 'fg': const Color(0xFF16a34a)},
      {'label': store.t('expense'),     'icon': Icons.arrow_downward_rounded,  'bg': const Color(0xFFffe4e6), 'fg': const Color(0xFFef4444)},
      {'label': store.t('history_tab'), 'icon': Icons.access_time_rounded,     'bg': const Color(0xFFede9fe), 'fg': const Color(0xFF6366f1)},
      {'label': store.t('receipt_tab'), 'icon': Icons.receipt_long_rounded,    'bg': const Color(0xFFfef3c7), 'fg': const Color(0xFFf59e0b)},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.t('quick_actions'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1f2937))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((a) {
              return Expanded(child: GestureDetector(
                onTap: () {
                  final label = a['label'] as String;
                  if (label == store.t('receipt_tab')) {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                        builder: (_) => const ReceiptScannerSheet());
                  } else if (label == store.t('income') || label == store.t('expense')) {
                    widget.onAddTransaction?.call();
                  } else if (label == store.t('history_tab')) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        ChangeNotifierProvider.value(value: context.read<AppStore>(), child: const TransactionsScreen())));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: (a['bg'] as Color),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Icon(a['icon'] as IconData, color: a['fg'] as Color, size: 20),
                    const SizedBox(height: 5),
                    Text(a['label'] as String,
                        style: TextStyle(fontSize: 10, color: a['fg'] as Color),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── График ───────────────────────────────────────────────────────────────

  Widget _buildChart(AppStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(store.t('balance_dyn'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            Text(store.t('30_days'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9ca3af))),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: const Size(double.infinity, 90),
              painter: _BalanceChartPainter(store.transactions, store.totalBalance, store),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Последние операции ───────────────────────────────────────────────────

  Widget _buildRecentTxs(AppStore store) {
    final txs = store.transactions.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(store.t('recent_ops'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(value: context.read<AppStore>(), child: const TransactionsScreen()))),
              child: Text(store.t('history_tab'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16a34a), fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          if (txs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text(store.t('no_ops'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9ca3af)))),
            )
          else
            ...txs.asMap().entries.map((e) => Column(children: [
              _TxRow(tx: e.value, store: store),
              if (e.key < txs.length - 1)
                const Divider(height: 1, color: Color(0xFFf3f4f6)),
            ])),
        ]),
      ),
    );
  }
}

// ─── Bank Card ────────────────────────────────────────────────────────────────

class _BankCard extends StatelessWidget {
  final AccountModel account;
  final List<TransactionModel> transactions;
  final AppStore store;
  const _BankCard({required this.account, required this.transactions, required this.store});

  @override
  Widget build(BuildContext context) {
    final color = parseColor(account.color);
    final iconData = _homeAccountIcons[account.icon] ?? Icons.credit_card;
    final colorDark = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness - 0.13).clamp(0.0, 1.0))
        .toColor();
    final accountTx = transactions.where((t) => t.accountId == account.id).toList();
    final income = accountTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = accountTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, colorDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned(right: -25, top: -25,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(15)))),
          Positioned(right: -8, bottom: -8,
            child: Icon(iconData, size: 100, color: Colors.white.withAlpha(25))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Заголовок
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(11)),
                    child: Icon(iconData, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(account.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                      child: Text(account.currency,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(210))),
                    ),
                  ])),
                ]),
                // Баланс
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.t('balance'),
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(155))),
                  const SizedBox(height: 3),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Flexible(child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(formatAmount(account.balance),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                          maxLines: 1),
                    )),
                    const SizedBox(width: 6),
                    Text(account.currency,
                        style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500)),
                  ]),
                ]),
                // Доходы / расходы
                Row(children: [
                  Expanded(child: _CardStat(icon: Icons.trending_up, label: store.t('income'), value: formatAmount(income))),
                  const SizedBox(width: 8),
                  Expanded(child: _CardStat(icon: Icons.trending_down, label: store.t('expense'), value: formatAmount(expense))),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CardStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withAlpha(35), borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        Icon(icon, size: 12, color: Colors.white.withAlpha(190)),
        const SizedBox(width: 5),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withAlpha(155))),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
        ])),
      ]),
    );
  }
}

// ─── Transaction Row ──────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final TransactionModel tx;
  final AppStore store;
  const _TxRow({required this.tx, required this.store});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? const Color(0xFF16a34a) : const Color(0xFFef4444);
    final bg = isIncome ? const Color(0xFFdcfce7) : const Color(0xFFffe4e6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            tx.description.isNotEmpty ? tx.description : store.translateCategory(tx.category, tx.category),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(formatDate(tx.date, store.lang),
              style: const TextStyle(fontSize: 11, color: Color(0xFF9ca3af))),
        ])),
        const SizedBox(width: 8),
        Text(
          '${isIncome ? "+" : "−"}${formatAmount(tx.amount)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ]),
    );
  }
}

// ─── SparkLine (используется в _OverviewTile через _SparkPainter напрямую) ────

class _SparkPainter extends CustomPainter {
  final Color color;
  final List<double> data;
  const _SparkPainter(this.color, this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.every((v) => v == 0)) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal > 0 ? maxVal : 1.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = (size.height - 2) - (data[i] / effectiveMax) * (size.height - 4) + 1;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.data != data || old.color != color;
}

// ─── Balance Chart Painter ────────────────────────────────────────────────────

class _BalanceChartPainter extends CustomPainter {
  final List<TransactionModel> transactions;
  final double totalBalance;
  final AppStore store;
  _BalanceChartPainter(this.transactions, this.totalBalance, this.store);

  @override
  void paint(Canvas canvas, Size size) {
    if (transactions.length < 2) {
      final tp = TextPainter(
        text: TextSpan(
          text: transactions.isEmpty ? store.t('no_data') : store.t('not_enough_data'),
          style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
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
      if (i == 0) { path.moveTo(x, y); areaPath.moveTo(x, y); }
      else { path.lineTo(x, y); areaPath.lineTo(x, y); }
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();
    canvas.drawPath(areaPath, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x4016a34a), Color(0x0016a34a)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF16a34a)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
