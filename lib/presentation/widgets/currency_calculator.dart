import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../core/utils/helpers.dart';

class CurrencyCalculatorWidget extends StatefulWidget {
  const CurrencyCalculatorWidget({Key? key}) : super(key: key);

  @override State<CurrencyCalculatorWidget> createState() => _CurrencyCalculatorWidgetState();
}

class _CurrencyCalculatorWidgetState extends State<CurrencyCalculatorWidget> {
  Map<String, double> _rates = {'USD': 12850, 'RUB': 142, 'EUR': 13600};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _loading = true);
    try {
      final store = context.read<AppStore>();
      await store.fetchRates();
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Currency fetch error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Container(
      // margin removed for flexibility in Settings screen
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                store.t('currency_calc'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
              ),
              if (_loading)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFF22c55e))))
              else
                const Text('nbu.uz', style: TextStyle(fontSize: 10, color: Color(0xFF9ca3af))),
            ],
          ),
          const SizedBox(height: 16),
          _CurrencyRow(rate: store.rates['USD'] ?? 12850, code: 'USD', icon: '🇺🇸'),
          const Divider(height: 24, color: Color(0xFFf3f4f6)),
          _CurrencyRow(rate: store.rates['EUR'] ?? 13600, code: 'EUR', icon: '🇪🇺'),
          const Divider(height: 24, color: Color(0xFFf3f4f6)),
          _CurrencyRow(rate: store.rates['RUB'] ?? 142, code: 'RUB', icon: '🇷🇺'),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatefulWidget {
  final double rate;
  final String code;
  final String icon;
  const _CurrencyRow({required this.rate, required this.code, required this.icon});

  @override State<_CurrencyRow> createState() => _CurrencyRowState();
}

class _CurrencyRowState extends State<_CurrencyRow> {
  final TextEditingController _foreignCtrl = TextEditingController();
  final TextEditingController _uzsCtrl = TextEditingController();
  final FocusNode _uzsNode = FocusNode();
  final FocusNode _foreignNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _foreignCtrl.text = "1";
    _updateUZS(1);
  }

  void _updateUZS(double foreign) {
    if (_uzsNode.hasFocus) return; // Prevent loop for user editing
    final val = foreign * widget.rate;
    _uzsCtrl.text = val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  void _updateForeign(double uzs) {
    if (_foreignNode.hasFocus) return; // Prevent loop
    final val = uzs / widget.rate;
    _foreignCtrl.text = val.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Foreign input
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(widget.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _foreignCtrl,
                  focusNode: _foreignNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: '0'),
                  onChanged: (v) {
                    final amount = double.tryParse(v.replaceAll(' ', '')) ?? 0;
                    _updateUZS(amount);
                  },
                ),
              ),
            ],
          ),
        ),
        
        const Icon(Icons.compare_arrows, size: 16, color: Color(0xFFd1d5db)),
        
        // UZS input
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _uzsCtrl,
                  focusNode: _uzsNode,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero, hintText: '0'),
                  onChanged: (v) {
                    final amount = double.tryParse(v.replaceAll(' ', '')) ?? 0;
                    _updateForeign(amount);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('UZS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9ca3af))),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _foreignCtrl.dispose();
    _uzsCtrl.dispose();
    _uzsNode.dispose();
    _foreignNode.dispose();
    super.dispose();
  }
}
