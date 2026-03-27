import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';

class AccountCard extends StatelessWidget {
  final AccountModel account;
  final bool isSelected;
  final VoidCallback? onTap;

  const AccountCard({
    Key? key,
    required this.account,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  /// Parse hex color from account.color
  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppColors.primaryAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(account.color);
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300.w,
        height: 160.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          // Gradient background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.15),
              accentColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusXL),
          border: isSelected
              ? Border.all(color: accentColor, width: 2)
              : Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            else
              AppSizes.shadowSoft,
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXLarge.w,
            vertical: AppSizes.paddingLarge.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Icon and Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusLarge,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            account.icon,
                            style: TextStyle(fontSize: 24.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        account.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (account.isShared)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusSmall,
                        ),
                      ),
                      child: Text(
                        'Совместно',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryAccent,
                        ),
                      ),
                    ),
                ],
              ),

              // Currency indicator
              Text(
                account.currency,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Баланс',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    account.balance.toCurrency(account.currency),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
