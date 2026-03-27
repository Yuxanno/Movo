import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  // Category emoji mapping
  static const Map<String, String> categoryEmojis = {
    'cat_food': '🛒',
    'cat_transport': '🚕',
    'cat_entertainment': '🎬',
    'cat_utilities': '💡',
    'cat_health': '🏥',
    'cat_education': '📚',
    'cat_salary': '💼',
    'cat_other': '📌',
  };

  static const Map<String, String> categoryNames = {
    'cat_food': 'Продукты',
    'cat_transport': 'Транспорт',
    'cat_entertainment': 'Развлечения',
    'cat_utilities': 'Коммунальные',
    'cat_health': 'Здоровье',
    'cat_education': 'Образование',
    'cat_salary': 'Зарплата',
    'cat_other': 'Прочее',
  };

  static const Map<String, Color> categoryColors = {
    'cat_food': AppColors.categoryFood,
    'cat_transport': AppColors.categoryTransport,
    'cat_entertainment': AppColors.categoryEntertainment,
    'cat_utilities': AppColors.categoryUtilities,
    'cat_health': AppColors.categoryHealth,
    'cat_education': AppColors.categoryEducation,
    'cat_salary': AppColors.secondaryAccent,
    'cat_other': AppColors.categoryOther,
  };

  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  Color _getTransactionColor() {
    return transaction.type == 'expense'
        ? AppColors.negativeAccent
        : AppColors.secondaryAccent;
  }

  Color _getCategoryColor() {
    return categoryColors[transaction.categoryId] ??
        AppColors.categoryOther;
  }

  String _getCategoryEmoji() {
    return categoryEmojis[transaction.categoryId] ?? '📌';
  }

  String _getCategoryName() {
    return categoryNames[transaction.categoryId] ?? 'Прочее';
  }

  String _getAmountPrefix() {
    return transaction.type == 'expense' ? '−' : '+';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountColor = _getTransactionColor();
    final categoryColor = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge.w,
          vertical: AppSizes.paddingMedium.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider,
              width: 0.5.h,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Category Icon & Info
            Expanded(
              child: Row(
                children: [
                  // Category Icon Container
                  Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusLarge,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(),
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Category Name & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(),
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          transaction.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          transaction.date.toTransactionDate(),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_getAmountPrefix()}${transaction.amount.abs().toCurrency(transaction.currency)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                if (transaction.convertedAmount != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '${transaction.convertedAmount?.toCurrency(transaction.originalCurrency ?? transaction.currency)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
