import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
class AccountModel with _$AccountModel {
  const factory AccountModel({
    required String id,
    required String userId,
    required String name,
    required String icon, // emoji
    required double balance,
    required String currency, // UZS, USD, RUB
    required String color, // hex code
    required bool isShared,
    required String ownerId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  // Mock factory for demo
  factory AccountModel.demo() {
    return AccountModel(
      id: '1',
      userId: 'user_1',
      name: 'Дом',
      icon: '🏠',
      balance: 500000,
      currency: 'UZS',
      color: '#6366F1',
      isShared: false,
      ownerId: 'user_1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
