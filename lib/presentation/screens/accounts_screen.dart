import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../data/app_store.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/helpers.dart';

// Валюта счёта всегда берётся из store.systemCurrency

// Максимально допустимая сумма — 10 триллионов
const double _kMaxAmount = 10000000000000;

/// Formatter: разрешает только цифры и одну точку, блокирует ввод если
/// значение превышает [_kMaxAmount].
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (!RegExp(r'^[\d.]*$').hasMatch(text)) return oldValue;
    if (text.split('.').length > 2) return oldValue;
    final val = double.tryParse(text);
    if (val != null && val > _kMaxAmount) return oldValue;
    return newValue;
  }
}

const _presetColors = [
  Color(0xFF22c55e), Color(0xFF16a34a), Color(0xFF14b8a6), Color(0xFF3b82f6),
  Color(0xFF6366f1), Color(0xFF8b5cf6), Color(0xFFec4899), Color(0xFFef4444),
  Color(0xFFf59e0b), Color(0xFFf97316), Color(0xFF84cc16), Color(0xFF06b6d4),
  Color(0xFF1d4ed8), Color(0xFF7c3aed), Color(0xFFdb2777), Color(0xFFdc2626),
];

const _accountIcons = <String, IconData>{
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

String _colorToHex(Color c) =>
    '#${(c.r * 255).round().toRadixString(16).padLeft(2, '0')}'
    '${(c.g * 255).round().toRadixString(16).padLeft(2, '0')}'
    '${(c.b * 255).round().toRadixString(16).padLeft(2, '0')}';

// ─── Главный экран счетов ────────────────────────────────────────────────────

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);
  @override State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  AccountModel? _selected;

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(
        onSave: (data) => context.read<AppStore>().addAccount(data),
      ),
    );
  }

  void _openEditSheet(AccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(
        existing: account,
        onSave: (data) => context.read<AppStore>().updateAccount(account.id, data),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AccountModel account) {
    final store = ctx.read<AppStore>();
    final lang = store.lang;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang == 'ru' ? 'Удалить счёт?' : lang == 'uz' ? 'Hisobni o\'chirish?' : 'Delete account?',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          lang == 'ru' ? 'Счёт "${account.name}" и все его транзакции будут удалены.'
              : lang == 'uz' ? '"${account.name}" hisobi o\'chiriladi.'
              : 'Account "${account.name}" will be deleted.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(store.t('cancel'), style: const TextStyle(color: Color(0xFF6b7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              store.deleteAccount(account.id);
            },
            child: Text(store.t('delete'),
                style: const TextStyle(color: Color(0xFFef4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(store.t('my_accounts'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
              GestureDetector(
                onTap: _openAddSheet,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16a34a),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [BoxShadow(color: const Color(0xFF16a34a).withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            if (store.accounts.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: const Color(0xFFe5e7eb), borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.credit_card_outlined, size: 40, color: Color(0xFF9ca3af)),
                  ),
                  const SizedBox(height: 16),
                  Text(store.t('no_accounts_yet'),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF9ca3af), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF16a34a), borderRadius: BorderRadius.circular(20)),
                      child: Text(store.lang == 'ru' ? '+ Создать счёт' : store.lang == 'uz' ? '+ Hisob yaratish' : '+ Create account',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ]),
              ))
            else
              ...store.accounts.map((a) => _AccountCard(
                account: a,
                onTap: () => setState(() => _selected = a),
                onEdit: () => _openEditSheet(a),
                onDelete: () => _confirmDelete(context, a),
              )),
          ]),
        ),
      ),
    );
  }
}

// ─── Карточка счёта ──────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AccountCard({required this.account, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final color = parseColor(account.color);
    final iconData = _accountIcons[account.icon] ?? Icons.credit_card;
    // Светлый или тёмный акцент для второго градиента
    final colorDark = HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - 0.12).clamp(0.0, 1.0)
    ).toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, colorDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: color.withAlpha(40), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Декоративный круг фона
              Positioned(
                right: -30, top: -30,
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(18),
                  ),
                ),
              ),
              // Фоновая иконка
              Positioned(
                right: -12, bottom: -12,
                child: Icon(iconData, size: 110, color: Colors.white.withAlpha(30)),
              ),
              // Контент
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок: иконка + имя + кнопки
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Иконка счёта
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(iconData, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Название + валюта
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
                            const SizedBox(height: 2),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(store.systemCurrency,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(220))),
                              ),
                            ]),
                          ],
                        )),
                        // Кнопка редактировать
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            width: 34, height: 34,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.edit_outlined, size: 16, color: Colors.white.withAlpha(230)),
                          ),
                        ),
                        // Кнопка удалить
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.white.withAlpha(230)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Разделитель
                    Container(height: 1, color: Colors.white.withAlpha(30)),
                    const SizedBox(height: 14),
                    // Баланс
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Баланс',
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160), letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatAmount(account.balance),
                                  style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold,
                                    color: Colors.white, letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              store.systemCurrency,
                              style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet: создание и редактирование счёта ───────────────────────────

class _AccountSheet extends StatefulWidget {
  final AccountModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AccountSheet({this.existing, required this.onSave});
  @override State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late String _currency;
  late String _icon;
  late Color _color;
  bool _saving = false;
  bool _showColorPicker = false;
  bool _balanceOverLimit = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _balanceCtrl = TextEditingController(text: e == null ? '' : (e.balance == 0 ? '' : e.balance.toStringAsFixed(0)));
    _currency = e?.currency ?? 'UZS'; // будет перезаписан в build из systemCurrency
    _icon = e?.icon ?? 'card';
    _color = e != null ? parseColor(e.color) : const Color(0xFF22c55e);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _balanceOverLimit) return;
    setState(() => _saving = true);
    final balance = double.tryParse(_balanceCtrl.text.replaceAll(' ', '')) ?? 0;
    final currency = context.read<AppStore>().systemCurrency;
    await widget.onSave({
      'name': _nameCtrl.text.trim(),
      'icon': _icon,
      'color': _colorToHex(_color),
      'balance': balance,
      'currency': currency,
      'isShared': false,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final lang = store.lang;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFe5e7eb), borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 18),

          // Заголовок
          Text(
            _isEdit
                ? (lang == 'ru' ? 'Редактировать счёт' : lang == 'uz' ? 'Hisobni tahrirlash' : 'Edit account')
                : store.t('new_account'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
          ),
          const SizedBox(height: 16),

          // Превью карточки
          _CardPreview(name: _nameCtrl.text, icon: _icon, color: _color, currency: store.systemCurrency,
              balance: double.tryParse(_balanceCtrl.text.replaceAll(' ', '')) ?? 0),
          const SizedBox(height: 22),

          // Название
          _buildTextField(
            controller: _nameCtrl,
            hint: lang == 'ru' ? 'Название (Дом, Семья, Бизнес...)'
                : lang == 'uz' ? 'Nomi (Uy, Oila...)' : 'Name (Home, Family...)',
            icon: Icons.edit_outlined,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Начальный баланс
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTextField(
              controller: _balanceCtrl,
              hint: lang == 'ru' ? 'Начальный баланс (необязательно)'
                  : lang == 'uz' ? 'Boshlang\'ich balans (ixtiyoriy)' : 'Initial balance (optional)',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_AmountInputFormatter()],
              isError: _balanceOverLimit,
              onChanged: (v) {
                final val = double.tryParse(v.replaceAll(' ', ''));
                setState(() {
                  _balanceOverLimit = val != null && val > _kMaxAmount;
                });
              },
            ),
            if (_balanceOverLimit) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFef4444)),
                const SizedBox(width: 4),
                Text(
                  lang == 'ru' ? 'Максимум 10 триллионов'
                      : lang == 'uz' ? 'Maksimum 10 trillion'
                      : 'Maximum 10 trillion',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFef4444)),
                ),
              ]),
            ],
          ]),
          const SizedBox(height: 20),

          // Валюта (информационный чип)
          _SectionLabel(label: store.t('currency_label')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _color.withAlpha(60)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: _color),
              const SizedBox(width: 8),
              Text(
                store.systemCurrency,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lang == 'ru' ? '— системная валюта (изменяется в Настройках)'
                      : lang == 'uz' ? "— tizim valyutasi (Sozlamalarda o'zgartiriladi)"
                      : '— system currency (change in Settings)',
                  style: TextStyle(fontSize: 11, color: _color.withAlpha(180)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Иконка
          _SectionLabel(label: lang == 'ru' ? 'Иконка' : lang == 'uz' ? 'Ikonka' : 'Icon'),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _accountIcons.entries.map((e) {
                final sel = _icon == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50, height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: sel ? _color : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: sel ? [BoxShadow(color: _color.withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Icon(e.value, size: 22, color: sel ? Colors.white : const Color(0xFF9ca3af)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Цвет
          _SectionLabel(label: lang == 'ru' ? 'Цвет' : lang == 'uz' ? 'Rang' : 'Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._presetColors.map((c) => GestureDetector(
                onTap: () => setState(() { _color = c; _showColorPicker = false; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _color.toARGB32() == c.toARGB32() ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: _color.toARGB32() == c.toARGB32()
                        ? [BoxShadow(color: c.withAlpha(150), blurRadius: 8, spreadRadius: 1)]
                        : [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 4)],
                  ),
                  child: _color.toARGB32() == c.toARGB32()
                      ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              )),
              // Своя палитра
              GestureDetector(
                onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFe5e7eb), width: 2),
                    gradient: const SweepGradient(colors: [
                      Color(0xFFef4444), Color(0xFFf59e0b), Color(0xFF22c55e),
                      Color(0xFF3b82f6), Color(0xFF8b5cf6), Color(0xFFef4444),
                    ]),
                  ),
                  child: const Icon(Icons.colorize, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _showColorPicker
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ColorPicker(
                      pickerColor: _color,
                      onColorChanged: (c) => setState(() => _color = c),
                      enableAlpha: false,
                      labelTypes: const [],
                      pickerAreaHeightPercent: 0.45,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          // Кнопка сохранить
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (_saving || _balanceOverLimit) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: _color.withAlpha(120),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEdit
                          ? (lang == 'ru' ? 'Сохранить' : lang == 'uz' ? 'Saqlash' : 'Save')
                          : store.t('add_account'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isError = false,
    void Function(String)? onChanged,
  }) {
    final borderColor = isError ? const Color(0xFFef4444) : const Color(0xFFe5e7eb);
    final focusColor = isError ? const Color(0xFFef4444) : _color;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFb0b7c3), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9ca3af)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: focusColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

// ─── Превью карточки в шите ──────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final String currency;
  final double balance;
  const _CardPreview({required this.name, required this.icon, required this.color, required this.currency, required this.balance});

  @override
  Widget build(BuildContext context) {
    final iconData = _accountIcons[icon] ?? Icons.credit_card;
    final colorDark = HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - 0.12).clamp(0.0, 1.0)
    ).toColor();

    return Container(
      height: 118,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, colorDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: color.withAlpha(110), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          Positioned(right: -12, bottom: -12, child: Icon(iconData, size: 105, color: Colors.white.withAlpha(30))),
          Positioned(right: -20, top: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(15)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(10)),
                  child: Icon(iconData, color: Colors.white, size: 18)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(name.isEmpty ? '···' : name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        balance == 0 ? '0' : formatAmount(balance),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(currency, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(180))),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) =>
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6b7280)));
}

class _AccountDetail extends StatefulWidget {
  final AccountModel account;
  final VoidCallback onBack;
  const _AccountDetail({required this.account, required this.onBack});
  @override State<_AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<_AccountDetail> {
  String _filter = 'all';
  List<TransactionModel> _localTxs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final store = context.read<AppStore>();
    final txs = await store.fetchTransactionsForAccount(widget.account.id);
    if (!mounted) return;
    setState(() { _localTxs = txs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final color = parseColor(widget.account.color);
    final txs = _localTxs.where((t) => _filter == 'all' || t.type == _filter).toList();
    final income  = _localTxs.where((t) => t.type == 'income') .fold<double>(0, (s, t) => s + t.amount);
    final expense = _localTxs.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF16a34a),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Row(children: [
                  const Icon(Icons.arrow_back, size: 18, color: Color(0xFF6b7280)),
                  const SizedBox(width: 8),
                  Text(store.t('back_btn'), style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withAlpha(238), color.withAlpha(153)]), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(8)),
                      child: Icon(_accountIcons[widget.account.icon] ?? Icons.credit_card, color: Colors.white, size: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(widget.account.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatAmount(widget.account.balance),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(' ${store.systemCurrency}',
                          style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(179))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.t('income'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                        Text('+${formatAmountWithCurrency(income, store.systemCurrency)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.t('expense'), style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                        Text('−${formatAmountWithCurrency(expense, store.systemCurrency)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                child: Row(children: [
                  for (final f in [['all', store.t('all')], ['income', store.t('income')], ['expense', store.t('expense')]])
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
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16a34a))))
              else if (txs.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Text(store.t('no_txs'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)))))
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
                      Text('${isIncome ? "+" : "−"}${formatAmountWithCurrency(t.amount, store.systemCurrency)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txColor)),
                    ]),
                  );
                }),
            ]),
          ),
        ),
      ),
    );
  }
}
