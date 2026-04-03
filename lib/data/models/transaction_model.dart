class TransactionModel {
  final String id;
  final String accountId;
  final String type; // "income" | "expense"
  final double amount;
  final String currency;
  final String category;
  final String description;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      accountId: json['accountId'] ?? '',
      type: json['type'] ?? 'expense',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'UZS',
      category: json['category'] ?? 'other',
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'type': type,
    'amount': amount,
    'currency': currency,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
  };
}
