// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionModelImpl _$$TransactionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionModelImpl(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      originalCurrency: json['originalCurrency'] as String?,
      convertedAmount: (json['convertedAmount'] as num?)?.toDouble(),
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      categoryId: json['categoryId'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      receiptUrl: json['receiptUrl'] as String?,
    );

Map<String, dynamic> _$$TransactionModelImplToJson(
        _$TransactionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'userId': instance.userId,
      'amount': instance.amount,
      'currency': instance.currency,
      'originalCurrency': instance.originalCurrency,
      'convertedAmount': instance.convertedAmount,
      'exchangeRate': instance.exchangeRate,
      'categoryId': instance.categoryId,
      'description': instance.description,
      'type': instance.type,
      'date': instance.date.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'receiptUrl': instance.receiptUrl,
    };
