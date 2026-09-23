import 'package:flutter/foundation.dart';
import '../api_service.dart';
import '../models/account_model.dart';
import '../../core/app_snackbar.dart';

/// Отвечает только за: список счетов, их создание/удаление, пересчёт баланса.
/// Получает обновления баланса от TransactionStore через RootStore-координацию.
class AccountStore extends ChangeNotifier {
  final ApiService api;

  AccountStore(this.api);

  // ── Состояние ─────────────────────────────────────────────────────────
  List<AccountModel> accounts = [];
  bool loading = false;

  // ── Геттеры ───────────────────────────────────────────────────────────

  double get totalBalance => accounts.fold(0, (s, a) => s + a.balance);

  // ── Fetch ─────────────────────────────────────────────────────────────

  Future<void> fetchAccounts() async {
    loading = true;
    notifyListeners();
    try {
      accounts = await api.fetchAccounts();
    } catch (e) {
      debugPrint('fetchAccounts error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
    loading = false;
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  Future<void> addAccount(Map<String, dynamic> data) async {
    try {
      final account = await api.addAccount(data);
      accounts.insert(0, account);
      notifyListeners();
    } catch (e) {
      debugPrint('addAccount error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await api.deleteAccount(id);
      accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
  }

  /// Обновляет баланс конкретного счёта локально после добавления/удаления транзакции.
  /// Вызывается из TransactionStore через RootStore — прямой межсторовой координации нет.
  void applyBalanceDelta(String accountId, double delta) {
    final idx = accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return;
    final a = accounts[idx];
    accounts[idx] = AccountModel(
      id: a.id, name: a.name, icon: a.icon, color: a.color,
      balance: a.balance + delta, currency: a.currency, isShared: a.isShared,
    );
    notifyListeners();
  }

  void clear() {
    accounts = [];
    notifyListeners();
  }
}
