import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required String accountId,
    required String userId,
    required double amount,
    required String currency,
    String? originalCurrency,
    double? convertedAmount,
    double? exchangeRate,
    required String categoryId,
    required String description,
    required String type, // income, expense, transfer
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? receiptUrl,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  // Mock factories for demo
  factory TransactionModel.demo1() {
    return TransactionModel(
      id: 'tx_1',
      accountId: '1',
      userId: 'user_1',
      amount: -50000,
      currency: 'UZS',
      categoryId: 'cat_food',
      description: 'Продукты на базаре',
      type: 'expense',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  factory TransactionModel.demo2() {
    return TransactionModel(
      id: 'tx_2',
      accountId: '1',
      userId: 'user_1',
      amount: 150000,
      currency: 'UZS',
      categoryId: 'cat_salary',
      description: 'Зарплата',
      type: 'income',
      date: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  factory TransactionModel.demo3() {
    return TransactionModel(
      id: 'tx_3',
      accountId: '1',
      userId: 'user_1',
      amount: -25000,
      currency: 'UZS',
      categoryId: 'cat_transport',
      description: 'Такси домой',
      type: 'expense',
      date: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }
}
