import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/config/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/account_card.dart';
import '../widgets/transaction_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _accountController;
  int _currentAccountIndex = 0;

  // Mock data
  late List<AccountModel> accounts;
  late List<TransactionModel> transactions;

  @override
  void initState() {
    super.initState();
    _accountController = PageController(viewportFraction: 0.85);
    
    // Initialize demo data
    accounts = [
      AccountModel.demo(),
      AccountModel(
        id: '2',
        userId: 'user_1',
        name: 'Семья',
        icon: '👨‍👩‍👧‍👦',
        balance: 1200000,
        currency: 'UZS',
        color: '#10B981',
        isShared: true,
        ownerId: 'user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AccountModel(
        id: '3',
        userId: 'user_1',
        name: 'Бизнес',
        icon: '💼',
        balance: 3500000,
        currency: 'USD',
        color: '#F59E0B',
        isShared: false,
        ownerId: 'user_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    transactions = [
      TransactionModel.demo1(),
      TransactionModel.demo2(),
      TransactionModel.demo3(),
      TransactionModel(
        id: 'tx_4',
        accountId: '1',
        userId: 'user_1',
        amount: -15000,
        currency: 'UZS',
        categoryId: 'cat_entertainment',
        description: 'Кино с друзьями',
        type: 'expense',
        date: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'tx_5',
        accountId: '1',
        userId: 'user_1',
        amount: -30000,
        currency: 'UZS',
        categoryId: 'cat_utilities',
        description: 'Электричество',
        type: 'expense',
        date: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  double _getTotalBalance() {
    return accounts.fold(0, (sum, account) => sum + account.balance);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // App Bar with greeting
          SliverAppBar(
            backgroundColor: AppColors.backgroundPrimary,
            elevation: 0,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Добро пожаловать!',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Вторник, 20 марта',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16.w),
                child: CircleAvatar(
                  radius: 20.w,
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryAccent,
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 8.h),

                // Total Balance Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXLarge.w,
                      vertical: AppSizes.paddingXLarge.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryAccent.withOpacity(0.1),
                          AppColors.primaryAccent.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusXL,
                      ),
                      boxShadow: [AppSizes.shadowSoft],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Общий баланс',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getTotalBalance().toCurrency('UZS'),
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAccent.withOpacity(
                                  0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusSmall,
                                ),
                              ),
                              child: Text(
                                '+12.5%',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Accounts Carousel Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Мои счета',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20.sp,
                          color: AppColors.primaryAccent,
                        ),
                        label: Text(
                          'Добавить',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Accounts Carousel
                SizedBox(
                  height: 160.h,
                  child: PageView.builder(
                    controller: _accountController,
                    onPageChanged: (index) {
                      setState(() => _currentAccountIndex = index);
                    },
                    itemCount: accounts.length,
                    itemBuilder: (context, index) => AccountCard(
                      account: accounts[index],
                      isSelected: index == _currentAccountIndex,
                      onTap: () {
                        _accountController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Page Indicator
                Center(
                  child: SmoothPageIndicator(
                    controller: _accountController,
                    count: accounts.length,
                    effect: WormEffect(
                      dotWidth: 8.w,
                      dotHeight: 8.h,
                      spacing: 8.w,
                      strokeWidth: 0,
                      dotColor: AppColors.divider,
                      activeDotColor: AppColors.primaryAccent,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Quick Actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Icons.add,
                        label: 'Расход',
                        color: AppColors.negativeAccent,
                      ),
                      _buildQuickAction(
                        icon: Icons.trending_up,
                        label: 'Доход',
                        color: AppColors.secondaryAccent,
                      ),
                      _buildQuickAction(
                        icon: Icons.mic,
                        label: 'Голос',
                        color: AppColors.primaryAccent,
                      ),
                      _buildQuickAction(
                        icon: Icons.receipt_long,
                        label: 'Чек',
                        color: Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Recent Transactions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Последние операции',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                SizedBox(height: 12.h),
              ],
            ),
          ),

          // Transactions List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TransactionItem(
                transaction: transactions[index],
                onTap: () {
                  // Handle transaction tap
                },
              ),
              childCount: transactions.length,
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 20.h),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // Handle quick action
      },
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
              boxShadow: [AppSizes.shadowSoft],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
