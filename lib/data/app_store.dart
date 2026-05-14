import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'models/account_model.dart';
import 'models/transaction_model.dart';
import 'models/category_model.dart';

class AppStore extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? userId;
  String? userName;
  String? userLogin;
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  List<CategoryModel> categories = [];
  Map<String, double> rates = {'UZS': 1, 'USD': 12700, 'RUB': 140};
  bool loading = false;
  
  // Localization
  String lang = 'ru';
  final Map<String, Map<String, String>> _translations = {
    'ru': {
      'settings': 'Настройки', 'language': 'Язык', 'accounts': 'Счета', 'operations': 'Операции', 
      'categories': 'Категории', 'biometry': 'Биометрия', 'security_pin': 'Безопасность (PIN)',
      'logout': 'Выйти', 'income': 'Доходы', 'expense': 'Расходы', 'total_balance': 'Общий баланс',
      'cat_food': 'Продукты', 'cat_transport': 'Транспорт', 'cat_cafe': 'Кафе и рестораны',
      'cat_entertainment': 'Развлечения', 'cat_health': 'Здоровье', 'cat_clothes': 'Одежда',
      'cat_utilities': 'Коммунальные', 'cat_other': 'Другое', 'cat_salary': 'Зарплата', 'cat_work': 'Подработка',
      'currency_calc': 'Калькулятор валют', 'recent_ops': 'Последние операции', 'no_ops': 'Нет операций',
      'summary': 'Обзор месяца', 'quick_actions': 'Быстрые действия', 'balance_dyn': 'Динамика баланса',
      'understand': 'Понятно', 'receipt_scanner': 'Сканер чека', 'soon': 'Скоро', 
      'scanner_desc': 'Эта функция находится в разработке и появится в ближайших обновлениях',
      'history': 'История', 'search_hint': 'Поиск...', 'all': 'Все', 'no_txs': 'Нет транзакций',
      'delete_tx_q': 'Удалить транзакцию?', 'delete_tx_desc': 'Баланс счёта будет пересчитан автоматически.',
      'cancel': 'Отмена', 'delete': 'Удалить', 'deleting': 'Удаление...', 'today': 'Сегодня', 'yesterday': 'Вчера',
      'm1': 'января', 'm2': 'февраля', 'm3': 'марта', 'm4': 'апреля', 'm5': 'мая', 'm6': 'июня',
      'm7': 'июля', 'm8': 'августа', 'm9': 'сентября', 'm10': 'октября', 'm11': 'ноября', 'm12': 'декабря',
      'analytics': 'Аналитика', 'balance_period': 'Баланс за период', 'by_months': 'По месяцам',
      'by_categories': 'Расходы по категориям', 'month_short': '1М', '3m_short': '3М', 'year_short': 'Год',
      'no_expenses': 'Нет расходов за период',
      'ms1':'Янв','ms2':'Фев','ms3':'Мар','ms4':'Апр','ms5':'Май','ms6':'Июн','ms7':'Июл',
      'ms8':'Авг','ms9':'Сен','ms10':'Окт','ms11':'Ноя','ms12':'Дек',
      'new_op': 'Новая операция', 'category': 'Категория', 'amount': 'Сумма',
      'description_hint': 'Описание (необязательно)', 'saving': 'Сохранение...', 'add': 'Добавить',
      'login_title': 'Вход', 'login_subtitle': 'Войдите в свой аккаунт', 'login_hint': 'Логин', 'pass_hint': 'Пароль',
      'login_btn': 'Войти', 'no_account': 'Нет аккаунта? ', 'register_link': 'Зарегистрироваться',
      'fill_fields': 'Заполните все поля', 'confirm_login': 'Подтвердите вход', 'slogan': 'Управляй финансами легко',
      'register_title': 'Регистрация', 'step_account': 'Аккаунт', 'step_profile': 'Профиль', 'step_pin': 'PIN-код',
      'step_done': 'Готово', 'pass_min': 'Пароль минимум 6 символов', 'pass_mismatch': 'Пароли не совпадают',
      'enter_name': 'Введите имя', 'create_account': 'Создайте аккаунт', 'create_account_desc': 'Придумайте логин и пароль',
      'pass_hint_reg': 'Пароль (мин. 6 символов)', 'pass_repeat': 'Повторите пароль', 'about_me': 'О себе',
      'name_currency': 'Имя и основная валюта', 'your_name': 'Ваше имя', 'done_title': 'Готово!',
      'done_desc': 'Аккаунт создан. Начните управлять\nсвоими финансами.', 'next_btn': 'Далее', 'start_btn': 'Начать',
      'has_account': 'Уже есть аккаунт? ', 'login_link': 'Войти', 'pin_mismatch': 'PIN не совпадает, попробуйте снова',
      'pin_repeat': 'Повторите PIN-код', 'pin_create': 'Придумайте PIN-код', 'pin_desc': 'Он будет запрашиваться при каждом входе',
      'skip': 'Пропустить', 'wifi_off': 'Wi-Fi выключен', 'no_internet': 'Нет интернета', 'turn_on_net': 'Включите интернет, чтобы продолжить',
      'net_blocked': 'Связь есть, но интернет заблокирован или отсутствует', 'update_btn': 'Обновить', 'settings_btn': 'Настройки',
      'try_again': 'Попробовать снова', 'invalid_pin': 'Неверный PIN-код', 'pins_not_match': 'PIN-коды не совпадают',
      'enter_pin': 'Введите PIN-код', 'my_accounts': 'Мои счета', 'no_accounts_yet': 'Нет счетов. Создайте первый!',
      'new_account': 'Новый счёт', 'currency_label': 'Валюта', 'back_btn': 'Назад', 'no_categories': 'Нет категорий',
      'new_category': 'Новая категория', 'icon_label': 'Иконка', 'color_label': 'Цвет', 'current_month': 'Текущий месяц',
      'enter_current_pin': 'Введите текущий PIN', 'confirm_logout': 'Подтвердите выход', 'add_account': 'Добавить счёт',
      'history_tab': 'История', 'receipt_tab': 'Чек', '30_days': '30 дней', 'shared': 'Совместный', 'balance': 'Баланс',
      'no_data': 'Нет данных', 'not_enough_data': 'Мало данных', 'dashboard': 'Главная',
    },
    'en': {
      'settings': 'Settings', 'language': 'Language', 'accounts': 'Accounts', 'operations': 'Operations',
      'categories': 'Categories', 'biometry': 'Biometry', 'security_pin': 'Security (PIN)',
      'logout': 'Logout', 'income': 'Income', 'expense': 'Expense', 'total_balance': 'Total Balance',
      'cat_food': 'Food', 'cat_transport': 'Transport', 'cat_cafe': 'Cafe & Restaurants',
      'cat_entertainment': 'Entertainment', 'cat_health': 'Health', 'cat_clothes': 'Clothes',
      'cat_utilities': 'Utilities', 'cat_other': 'Other', 'cat_salary': 'Salary', 'cat_work': 'Side Job',
      'currency_calc': 'Currency Calculator', 'recent_ops': 'Recent Transactions', 'no_ops': 'No transactions',
      'summary': 'Month Overview', 'quick_actions': 'Quick Actions', 'balance_dyn': 'Balance Dynamics',
      'understand': 'Got it', 'receipt_scanner': 'Receipt Scanner', 'soon': 'Soon',
      'scanner_desc': 'This feature is under development and will appear in future updates',
      'history': 'History', 'search_hint': 'Search...', 'all': 'All', 'no_txs': 'No transactions',
      'delete_tx_q': 'Delete transaction?', 'delete_tx_desc': 'The account balance will be recalculated automatically.',
      'cancel': 'Cancel', 'delete': 'Delete', 'deleting': 'Deleting...', 'today': 'Today', 'yesterday': 'Yesterday',
      'm1': 'January', 'm2': 'February', 'm3': 'March', 'm4': 'April', 'm5': 'May', 'm6': 'June',
      'm7': 'July', 'm8': 'August', 'm9': 'September', 'm10': 'October', 'm11': 'November', 'm12': 'December',
      'analytics': 'Analytics', 'balance_period': 'Balance for period', 'by_months': 'By months',
      'by_categories': 'Expenses by category', 'month_short': '1M', '3m_short': '3M', 'year_short': 'Year',
      'no_expenses': 'No expenses for the period',
      'ms1':'Jan','ms2':'Feb','ms3':'Mar','ms4':'Apr','ms5':'May','ms6':'Jun','ms7':'Jul',
      'ms8':'Aug','ms9':'Sep','ms10':'Oct','ms11':'Nov','ms12':'Dec',
      'new_op': 'New Operation', 'category': 'Category', 'amount': 'Amount',
      'description_hint': 'Description (optional)', 'saving': 'Saving...', 'add': 'Add',
      'login_title': 'Login', 'login_subtitle': 'Sign in to your account', 'login_hint': 'Username', 'pass_hint': 'Password',
      'login_btn': 'Sign In', 'no_account': 'No account? ', 'register_link': 'Sign Up',
      'fill_fields': 'Fill in all fields', 'confirm_login': 'Confirm login', 'slogan': 'Manage finances easily',
      'register_title': 'Registration', 'step_account': 'Account', 'step_profile': 'Profile', 'step_pin': 'PIN code',
      'step_done': 'Done', 'pass_min': 'Password min 6 characters', 'pass_mismatch': 'Passwords do not match',
      'enter_name': 'Enter name', 'create_account': 'Create account', 'create_account_desc': 'Create a login and password',
      'pass_hint_reg': 'Password (min. 6 chars)', 'pass_repeat': 'Repeat password', 'about_me': 'About me',
      'name_currency': 'Name and base currency', 'your_name': 'Your name', 'done_title': 'Done!',
      'done_desc': 'Account created. Start managing\nyour finances.', 'next_btn': 'Next', 'start_btn': 'Start',
      'has_account': 'Already have an account? ', 'login_link': 'Sign In', 'pin_mismatch': 'PIN does not match, try again',
      'pin_repeat': 'Repeat PIN', 'pin_create': 'Create PIN', 'pin_desc': 'It will be requested on every login',
      'skip': 'Skip', 'wifi_off': 'Wi-Fi is off', 'no_internet': 'No internet', 'turn_on_net': 'Turn on internet to continue',
      'net_blocked': 'Connected, but internet is blocked or missing', 'update_btn': 'Refresh', 'settings_btn': 'Settings',
      'try_again': 'Try again', 'invalid_pin': 'Invalid PIN', 'pins_not_match': 'PINs do not match',
      'enter_pin': 'Enter PIN', 'my_accounts': 'My accounts', 'no_accounts_yet': 'No accounts. Create the first one!',
      'new_account': 'New account', 'currency_label': 'Currency', 'back_btn': 'Back', 'no_categories': 'No categories',
      'new_category': 'New category', 'icon_label': 'Icon', 'color_label': 'Color', 'current_month': 'Current month',
      'enter_current_pin': 'Enter current PIN', 'confirm_logout': 'Confirm logout', 'add_account': 'Add account',
      'history_tab': 'History', 'receipt_tab': 'Receipt', '30_days': '30 days', 'shared': 'Shared', 'balance': 'Balance',
      'no_data': 'No data', 'not_enough_data': 'Not enough data', 'dashboard': 'Dashboard',
    },
    'uz': {
      'settings': 'Sozlamalar', 'language': 'Til', 'accounts': 'Hisoblar', 'operations': 'Operatsiyalar',
      'categories': 'Kategoriyalar', 'biometry': 'Biometriya', 'security_pin': 'Xavfsizlik (PIN)',
      'logout': 'Chiqish', 'income': 'Daromad', 'expense': 'Xarajat', 'total_balance': 'Umumiy balans',
      'cat_food': 'Oziq-ovqat', 'cat_transport': 'Transport', 'cat_cafe': 'Kafe va restoranlar',
      'cat_entertainment': 'Ko\'ngilochar', 'cat_health': 'Salomatlik', 'cat_clothes': 'Kiyimlar',
      'cat_utilities': 'Kommunal', 'cat_other': 'Boshqa', 'cat_salary': 'Oylik', 'cat_work': 'Qo\'shimcha ish',
      'currency_calc': 'Valyuta kalkulyatori', 'recent_ops': 'Oxirgi operatsiyalar', 'no_ops': 'Operatsiyalar yo\'q',
      'summary': 'Oylik sharh', 'quick_actions': 'Tezkor amallar', 'balance_dyn': 'Balans dinamikasi',
      'understand': 'Tushunarli', 'receipt_scanner': 'Chek skaneri', 'soon': 'Tez orada',
      'scanner_desc': 'Ushbu funksiya ishlab chiqilmoqda va yaqin oradagi yangilanishlarda paydo bo\'ladi',
      'history': 'Tarix', 'search_hint': 'Qidiruv...', 'all': 'Barchasi', 'no_txs': 'Operatsiyalar yo\'q',
      'delete_tx_q': 'Transaksiyani o\'chirish?', 'delete_tx_desc': 'Hisob balansi avtomatik ravishda qayta hisoblanadi.',
      'cancel': 'Bekor qilish', 'delete': 'O\'chirish', 'deleting': 'O\'chirilmoqda...', 'today': 'Bugun', 'yesterday': 'Kecha',
      'm1': 'yanvar', 'm2': 'fevral', 'm3': 'mart', 'm4': 'aprel', 'm5': 'may', 'm6': 'iyun',
      'm7': 'iyul', 'm8': 'avgust', 'm9': 'sentabr', 'm10': 'oktabr', 'm11': 'noyabr', 'm12': 'dekabr',
      'analytics': 'Tahlil', 'balance_period': 'Davr uchun balans', 'by_months': 'Oylar bo\'yicha',
      'by_categories': 'Kategoriyalar bo\'yicha xarajatlar', 'month_short': '1O', '3m_short': '3O', 'year_short': 'Yil',
      'no_expenses': 'Davr uchun xarajatlar mavjud emas',
      'ms1':'Yan','ms2':'Fev','ms3':'Mar','ms4':'Apr','ms5':'May','ms6':'Iyun','ms7':'Iyul',
      'ms8':'Avg','ms9':'Sen','ms10':'Okt','ms11':'Noy','ms12':'Dek',
      'new_op': 'Yangi operatsiya', 'category': 'Kategoriya', 'amount': 'Summa',
      'description_hint': 'Tavsif (ixtiyoriy)', 'saving': 'Saqlanmoqda...', 'add': 'Qo\'shish',
      'login_title': 'Kirish', 'login_subtitle': 'Hisobingizga kiring', 'login_hint': 'Login', 'pass_hint': 'Parol',
      'login_btn': 'Kirish', 'no_account': 'Hisobingiz yo\'qmi? ', 'register_link': 'Ro\'yxatdan o\'tish',
      'fill_fields': 'Barcha maydonlarni to\'ldiring', 'confirm_login': 'Kirishni tasdiqlang', 'slogan': 'Moliyani oson boshqaring',
      'register_title': 'Ro\'yxatdan o\'tish', 'step_account': 'Hisob', 'step_profile': 'Profil', 'step_pin': 'PIN-kod',
      'step_done': 'Tayyor', 'pass_min': 'Parol kamida 6 belgi', 'pass_mismatch': 'Parollar mos kelmadi',
      'enter_name': 'Ismingizni kiriting', 'create_account': 'Hisob yarating', 'create_account_desc': 'Login va parol o\'ylab toping',
      'pass_hint_reg': 'Parol (kamida 6 belgi)', 'pass_repeat': 'Parolni takrorlang', 'about_me': 'O\'zim haqimda',
      'name_currency': 'Ism va asosiy valyuta', 'your_name': 'Ismingiz', 'done_title': 'Tayyor!',
      'done_desc': 'Hisob yaratildi. Moliyangizni\nboshqarishni boshlang.', 'next_btn': 'Keyingi', 'start_btn': 'Boshlash',
      'has_account': 'Hisobingiz bormi? ', 'login_link': 'Kirish', 'pin_mismatch': 'PIN mos kelmadi, qayta urinib ko\'ring',
      'pin_repeat': 'PIN-kodni takrorlang', 'pin_create': 'PIN-kod o\'ylab toping', 'pin_desc': 'U har safar kirganingizda so\'raladi',
      'skip': 'O\'tkazib yuborish', 'wifi_off': 'Wi-Fi o\'chirilgan', 'no_internet': 'Internet yo\'q', 'turn_on_net': 'Davom etish uchun internetni yoqing',
      'net_blocked': 'Aloqa bor, lekin internet bloklangan yoki yo\'q', 'update_btn': 'Yangilash', 'settings_btn': 'Sozlamalar',
      'try_again': 'Qayta urinish', 'invalid_pin': 'Noto\'g\'ri PIN-kod', 'pins_not_match': 'PIN-kodlar mos kelmadi',
      'enter_pin': 'PIN-kodni kiriting', 'my_accounts': 'Mening hisoblarim', 'no_accounts_yet': 'Hisoblar yo\'q. Birinchisini yarating!',
      'new_account': 'Yangi hisob', 'currency_label': 'Valyuta', 'back_btn': 'Orqaga', 'no_categories': 'Kategoriyalar yo\'q',
      'new_category': 'Yangi kategoriya', 'icon_label': 'Belgi', 'color_label': 'Rang', 'current_month': 'Joriy oy',
      'enter_current_pin': 'Joriy PIN-kodni kiriting', 'confirm_logout': 'Chiqishni tasdiqlang', 'add_account': 'Hisob qo\'shish',
      'history_tab': 'Tarix', 'receipt_tab': 'Chek', '30_days': '30 kun', 'shared': 'Birgalikda', 'balance': 'Balans',
      'no_data': 'Ma\'lumot yo\'q', 'not_enough_data': 'Ma\'lumot yetarli emas', 'dashboard': 'Asosiy',
    }
  };

  String t(String key) => _translations[lang]?[key] ?? key;

  Future<void> setLanguage(String l) async {
    lang = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
    notifyListeners();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ru';
    notifyListeners();
  }

  void setUser(String? id, {String? name, String? login}) {
    userId = id;
    userName = name;
    userLogin = login;
    _api.setUserId(id);
    if (id == null) {
      accounts = [];
      transactions = [];
      categories = [];
    }
    notifyListeners();
  }

  Future<void> saveUserToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('movo_user', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('movo_user');
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('movo_user');
    setUser(null);
  }

  double get totalBalance => accounts.fold(0, (s, a) => s + a.balance);

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

  Future<void> fetchAccounts() async {
    if (userId == null) return;
    loading = true;
    notifyListeners();
    try {
      accounts = await _api.fetchAccounts();
    } catch (e) {
      debugPrint('fetchAccounts error: $e');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> fetchTransactions({String? accountId}) async {
    if (userId == null) return;
    try {
      transactions = await _api.fetchTransactions(accountId: accountId);
    } catch (e) {
      debugPrint('fetchTransactions error: $e');
    }
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (userId == null) return;
    try {
      categories = await _api.fetchCategories();
    } catch (e) {
      debugPrint('fetchCategories error: $e');
    }
    notifyListeners();
  }

  Future<void> fetchRates() async {
    try {
      rates = await _api.fetchRates();
    } catch (e) {
      debugPrint('fetchRates error: $e');
    }
    notifyListeners();
  }

  Future<void> addAccount(Map<String, dynamic> data) async {
    try {
      final account = await _api.addAccount(data);
      accounts.insert(0, account);
      notifyListeners();
    } catch (e) {
      debugPrint('addAccount error: $e');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _api.deleteAccount(id);
      accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteAccount error: $e');
    }
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      final tx = await _api.addTransaction(data);
      transactions.insert(0, tx);
      final idx = accounts.indexWhere((a) => a.id == data['accountId']);
      if (idx != -1) {
        final a = accounts[idx];
        final delta = data['type'] == 'income' ? data['amount'] as double : -(data['amount'] as double);
        accounts[idx] = AccountModel(
          id: a.id, name: a.name, icon: a.icon, color: a.color,
          balance: a.balance + delta, currency: a.currency, isShared: a.isShared,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('addTransaction error: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final tx = transactions.firstWhere((t) => t.id == id);
      await _api.deleteTransaction(id);
      // Удаляем локально только после успешного ответа сервера
      transactions.removeWhere((t) => t.id == id);
      final idx = accounts.indexWhere((a) => a.id == tx.accountId);
      if (idx != -1) {
        final a = accounts[idx];
        final delta = tx.type == 'income' ? -tx.amount : tx.amount;
        accounts[idx] = AccountModel(
          id: a.id, name: a.name, icon: a.icon, color: a.color,
          balance: a.balance + delta, currency: a.currency, isShared: a.isShared,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
      rethrow;
    }
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final cat = await _api.addCategory(data);
      categories.add(cat);
      notifyListeners();
    } catch (e) {
      debugPrint('addCategory error: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _api.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteCategory error: $e');
    }
  }

  double convertAmount(double amount, String from, String to) {
    final inUZS = amount * (rates[from] ?? 1);
    return inUZS / (rates[to] ?? 1);
  }

  String translateCategory(String category, String fallback) {
    final key = 'cat_${category.toLowerCase().replaceAll(' ', '_')}';
    return t(key);
  }
}
