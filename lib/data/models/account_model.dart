class AccountModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final double balance;
  final String currency;
  final bool isShared;

  AccountModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.balance,
    required this.currency,
    this.isShared = false,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'card',
      color: json['color'] ?? '#22c55e',
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'UZS',
      isShared: json['isShared'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'color': color,
    'balance': balance,
    'currency': currency,
    'isShared': isShared,
  };
}
