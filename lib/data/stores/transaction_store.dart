import 'package:flutter/foundation.dart';
import '../api_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../../core/app_snackbar.dart';

/// Отвечает только за: транзакции, категории, вычисляемые финансовые показатели.
/// Не трогает список счетов — передаёт дельты баланса наружу через callback,
/// который устанавливает RootStore при инициализации.
class TransactionStore extends ChangeNotifier {
  final ApiService api;

  /// Callback для обновления баланса счёта.
  /// Устанавливается в RootStore: `txStore.onBalanceDelta = accountStore.applyBalanceDelta`
  /// Слабая связь — TransactionStore ничего не знает о AccountStore.
  void Function(String accountId, double delta)? onBalanceDelta;

  TransactionStore(this.api);

  // ── Состояние ─────────────────────────────────────────────────────────
  List<TransactionModel> transactions = [];
  List<CategoryModel>    categories   = [];

  // ── Геттеры ───────────────────────────────────────────────────────────

  double get monthlyIncome {
    final now = DateTime.now();
    return transactions
        .where((t) => t.type == 'income' && t.date.month == now.month && t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    return transactions
        .where((t) => t.type == 'expense' && t.date.month == now.month && t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  // ── Fetch ─────────────────────────────────────────────────────────────

  Future<void> fetchTransactions({String? accountId}) async {
    try {
      transactions = await api.fetchTransactions(accountId: accountId);
    } catch (e) {
      debugPrint('fetchTransactions error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
    notifyListeners();
  }

  /// Изолированный fetch для детального экрана счёта.
  /// Не перезаписывает глобальный список [transactions].
  Future<List<TransactionModel>> fetchTransactionsForAccount(String accountId) async {
    try {
      return await api.fetchTransactions(accountId: accountId);
    } catch (e) {
      debugPrint('fetchTransactionsForAccount error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
      return [];
    }
  }

  Future<void> fetchCategories() async {
    try {
      categories = await api.fetchCategories();
    } catch (e) {
      debugPrint('fetchCategories error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      final tx = await api.addTransaction(data);
      transactions.insert(0, tx);
      // Уведомляем AccountStore через callback — без прямой зависимости
      final delta = data['type'] == 'income'
          ? data['amount'] as double
          : -(data['amount'] as double);
      onBalanceDelta?.call(data['accountId'] as String, delta);
      notifyListeners();
    } catch (e) {
      debugPrint('addTransaction error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
  }

  /// Бросает исключение наружу — UI-слой поймает и покажет SnackBar с контекстом.
  Future<void> deleteTransaction(String id) async {
    try {
      final tx = transactions.firstWhere((t) => t.id == id);
      await api.deleteTransaction(id);
      transactions.removeWhere((t) => t.id == id);
      // Обратная дельта: income удаляется → баланс уменьшается
      final delta = tx.type == 'income' ? -tx.amount : tx.amount;
      onBalanceDelta?.call(tx.accountId, delta);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
      rethrow;
    }
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final cat = await api.addCategory(data);
      categories.add(cat);
      notifyListeners();
    } catch (e) {
      debugPrint('addCategory error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await api.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteCategory error: $e');
      AppSnackBar.error(message: AppSnackBar.messageFromError(e));
    }
  }

  void clear() {
    transactions = [];
    categories   = [];
    notifyListeners();
  }
}
