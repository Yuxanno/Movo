# FinanceFlow - Следующие шаги разработки

Это руководство описывает, что нужно сделать далее для завершения приложения FinanceFlow.

---

## 📋 Текущий статус

✅ **Завершено (Phase 1)**:
- Архитектура Clean Architecture
- Дизайн-система (Soft UI, светлая тема)
- Главный экран с UI компонентами
- Модели данных (Freezed)
- Структура директорий и файлов

🔄 **В процессе (Phase 2)**:
- Riverpod Providers для управления состоянием
- Firebase интеграция
- Локализация (i18n)

---

## 🎯 Phase 2 - State Management & Firebase

### 1. Создать Riverpod Providers

**Файл**: `lib/presentation/providers/account_provider.dart`

```dart
// TODO: Создать providers:
// - accountRepositoryProvider (singleton)
// - accountsProvider (FutureProvider)
// - selectedAccountProvider (StateNotifier)
// - totalBalanceProvider (computed)
```

**Файл**: `lib/presentation/providers/transaction_provider.dart`

```dart
// TODO: Создать providers:
// - transactionRepositoryProvider (singleton)
// - transactionsProvider (FutureProvider)
// - transactionsNotifierProvider (StateNotifier для CRUD операций)
```

**Файл**: `lib/presentation/providers/analytics_provider.dart`

```dart
// TODO: Создать providers для аналитики:
// - categoryAnalyticsProvider
// - monthlyTrendProvider
// - totalExpensesByPeriodProvider
```

### 2. Настроить Firebase

**Создать Firebase проект**:
1. Перейти на https://console.firebase.google.com
2. Создать новый проект (FinanceFlow)
3. Включить Authentication (Email/Password)
4. Создать Firestore database
5. Установить Security Rules

**Скачать конфиги**:
- iOS: `GoogleService-Info.plist` → `ios/Runner/`
- Android: `google-services.json` → `android/app/`
- Web: firebase-config.js (если нужно)

**Создать файл конфига**:
```dart
// lib/core/config/firebase_config.dart
class FirebaseConfig {
  static const String projectId = 'financeflow-xxx';
  static const String appId = 'com.example.financeflow';
}
```

### 3. Создать Data Sources

**Firestore datasource**:
```dart
// lib/data/datasources/remote/account_remote_datasource.dart
class AccountRemoteDataSource {
  final FirebaseFirestore _firestore;

  Future<List<AccountModel>> getAccounts(String userId) async {
    final snapshot = await _firestore
        .collection('accounts')
        .where('user_id', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => AccountModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<AccountModel>> watchAccounts(String userId) {
    return _firestore
        .collection('accounts')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> createAccount(AccountModel account) async {
    await _firestore
        .collection('accounts')
        .doc(account.id)
        .set(account.toJson());
  }

  // TODO: updateAccount, deleteAccount
}
```

**Hive datasource**:
```dart
// lib/data/datasources/local/account_local_datasource.dart
class AccountLocalDataSource {
  final Box<AccountModel> _box;

  Future<List<AccountModel>> getAccounts() async {
    return _box.values.toList();
  }

  Future<void> saveAccounts(List<AccountModel> accounts) async {
    await _box.clear();
    await _box.addAll(accounts);
  }

  Future<void> saveAccount(AccountModel account) async {
    await _box.put(account.id, account);
  }

  // TODO: deleteAccount
}
```

### 4. Создать Repository Implementations

```dart
// lib/data/repositories/account_repository_impl.dart
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource _remoteDataSource;
  final AccountLocalDataSource _localDataSource;

  @override
  Future<List<Account>> getAccounts(String userId) async {
    try {
      // Fetch from remote
      final remoteAccounts = await _remoteDataSource.getAccounts(userId);
      
      // Cache locally
      await _localDataSource.saveAccounts(remoteAccounts);
      
      return remoteAccounts.map((m) => m.toEntity()).toList();
    } catch (e) {
      // Fallback to local cache
      final localAccounts = await _localDataSource.getAccounts();
      return localAccounts.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Stream<List<Account>> watchAccounts(String userId) {
    return _remoteDataSource
        .watchAccounts(userId)
        .map((models) => models.map((m) => m.toEntity()).toList())
        .handleError((e) async {
          // On error, emit cached data
          final cached = await _localDataSource.getAccounts();
          return cached.map((m) => m.toEntity()).toList();
        });
  }

  // TODO: createAccount, updateAccount, deleteAccount
}
```

### 5. Настроить Hive локальный кэш

```dart
// lib/main.dart (обновить)
void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  
  // Open boxes
  await Hive.openBox<AccountModel>('accounts');
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<CategoryModel>('categories');

  // Run app
  runApp(ProviderScope(child: MyApp()));
}
```

**ВАЖНО**: Freezed автоматически генерирует Hive адаптеры. Нужно добавить в models:
```dart
@HiveType(typeId: 0)
@freezed
class AccountModel with _$AccountModel {
  const factory AccountModel({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    // ... остальные поля
  }) = _AccountModel;
}
```

---

## 🌍 Локализация (i18n)

### 1. Создать файлы переводов

**assets/l10n/en.yaml**:
```yaml
app_name: "FinanceFlow"

home:
  greeting: "Welcome!"
  total_balance: "Total Balance"
  my_accounts: "My Accounts"
  recent_transactions: "Recent Transactions"
  add_account: "Add Account"
  quick_actions: "Quick Actions"

transaction:
  add_expense: "Add Expense"
  add_income: "Add Income"
  expense: "Expense"
  income: "Income"
  transfer: "Transfer"
  date: "Date"
  amount: "Amount"
  category: "Category"
  description: "Description"

currencies:
  uzs: "Som"
  usd: "US Dollar"
  rub: "Russian Ruble"

categories:
  food: "Groceries"
  transport: "Transport"
  entertainment: "Entertainment"
  utilities: "Utilities"
  health: "Health"
  education: "Education"
  salary: "Salary"
  other: "Other"
```

**assets/l10n/ru.yaml**:
```yaml
app_name: "FinanceFlow"

home:
  greeting: "Добро пожаловать!"
  total_balance: "Общий баланс"
  my_accounts: "Мои счета"
  recent_transactions: "Последние операции"
  add_account: "Добавить счет"
  quick_actions: "Быстрые действия"

# ... остальные ключи
```

**assets/l10n/uz.yaml**:
```yaml
app_name: "FinanceFlow"

home:
  greeting: "Xush kelibsiz!"
  total_balance: "Umumiy balans"
  my_accounts: "Mening hisoblarim"
  recent_transactions: "So'nggi operatsiyalar"
  add_account: "Hisob qo'shish"
  quick_actions: "Tezkor harakatlar"

# ... остальные ключи
```

### 2. Интегрировать easy_localization

**lib/main.dart** (обновить):
```dart
void main() async {
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('ru'),
        Locale('uz'),
      ],
      path: 'assets/l10n',
      fallbackLocale: Locale('en'),
      child: ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}
```

### 3. Использовать в коде

```dart
// Вместо обычных строк:
Text('Welcome!')

// Используйте:
Text(context.tr('home.greeting'))

// Или с параметрами:
Text(context.tr('total_balance', args: [balance]))
```

---

## 🔐 Authentication

### 1. Создать Auth Service

```dart
// lib/presentation/services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
```

### 2. Создать Auth Provider

```dart
// lib/presentation/providers/auth_provider.dart
final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
  return user?.uid;
});
```

### 3. Создать Login Screen

```dart
// lib/presentation/screens/login_screen.dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement login form with validation
    // TODO: Handle sign in errors
    // TODO: Navigation to home screen on success
  }
}
```

---

## 🔄 Синхронизация данных

### 1. Offline-first синхронизация

```dart
// lib/data/repositories/sync_queue.dart
class SyncQueue {
  final Box<PendingTransaction> _box;

  Future<void> addPending(PendingTransaction transaction) async {
    await _box.add(transaction);
  }

  Future<List<PendingTransaction>> getPending() async {
    return _box.values.toList();
  }

  Future<void> removePending(String id) async {
    await _box.delete(id);
  }

  // TODO: Auto-sync when connection restored
}
```

### 2. Синхронизация при восстановлении подключения

```dart
// lib/presentation/services/connectivity_service.dart
class ConnectivityService {
  Stream<bool> connectionStatusStream() {
    return Connectivity().onConnectivityChanged.map(
      (event) => event != ConnectivityResult.none,
    );
  }
}

// В Repository:
connectionService.connectionStatusStream().listen((isConnected) {
  if (isConnected) {
    _syncPendingTransactions();
  }
});
```

---

## 📊 Аналитика (Phase 3)

### 1. Создать Analytics Providers

```dart
// lib/presentation/providers/analytics_provider.dart

final categoryAnalyticsProvider = FutureProvider((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  
  // Group by category and sum
  final Map<String, double> categoryTotals = {};
  for (final tx in transactions.where((t) => t.type == 'expense')) {
    categoryTotals[tx.categoryId] =
        (categoryTotals[tx.categoryId] ?? 0) + tx.amount.abs();
  }
  
  return categoryTotals;
});

final monthlyTrendProvider = FutureProvider((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  
  // Group by month and calculate balance change
  // TODO: Implementation
});
```

### 2. Обновить Analytics Screen

```dart
// lib/presentation/screens/analytics_screen.dart
class AnalyticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement with providers
    // - Show CategoryPieChart
    // - Show BalanceLineChart
    // - Add filters for date range
    // - Add export buttons (PDF, CSV)
  }
}
```

---

## 🎤 Голосовой ввод (Phase 3)

### 1. Добавить зависимость

```yaml
# pubspec.yaml
dependencies:
  speech_to_text: ^6.4.0
```

### 2. Создать Voice Service

```dart
// lib/presentation/services/voice_service.dart
// See EXAMPLES.md for full implementation
```

### 3. Создать Voice Input Screen

```dart
// lib/presentation/screens/voice_input_screen.dart
// See EXAMPLES.md for full implementation
```

---

## 📷 OCR для чеков (Phase 3)

### 1. Добавить зависимости

```yaml
dependencies:
  camera: ^0.10.0
  google_ml_kit: ^0.16.0
```

### 2. Создать Receipt Scanner

```dart
// lib/presentation/services/receipt_scanner_service.dart
// See EXAMPLES.md for full implementation
```

### 3. Обновить Camera Screen

```dart
// lib/presentation/screens/camera_screen.dart
// See EXAMPLES.md for full implementation
```

---

## 💱 Конвертер валют (Phase 3)

### 1. API интеграция

```dart
// lib/data/datasources/remote/currency_rate_datasource.dart
class CurrencyRateDataSource {
  final Dio _dio;

  Future<Map<String, double>> fetchRates() async {
    try {
      final response = await _dio.get(
        'https://api.example.com/rates',
        options: Options(
          sendTimeout: Duration(seconds: 5),
          receiveTimeout: Duration(seconds: 5),
        ),
      );
      
      return Map<String, double>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
```

### 2. Currency Repository

```dart
// lib/data/repositories/currency_repository_impl.dart
class CurrencyRepositoryImpl implements CurrencyRepository {
  @override
  Future<double> convert(String from, String to, double amount) async {
    final rates = await _remoteDataSource.fetchRates();
    final rate = rates['${from}_$to'];
    if (rate == null) throw Exception('Rate not found');
    return amount * rate;
  }
}
```

---

## 📋 Checklist для завершения Phase 2

- [ ] Создать все Riverpod providers
- [ ] Firebase Authentication работает
- [ ] Firestore CRUD операции (Create, Read, Update, Delete)
- [ ] Hive локальный кэш настроен
- [ ] Локализация (i18n) полностью реализована
- [ ] Тесты для repositories и providers
- [ ] Синхронизация данных между Firestore и Hive

---

## 📋 Checklist для Phase 3

- [ ] Voice Input Screen и NLP парсинг
- [ ] Camera Screen и OCR интеграция
- [ ] Analytics Screen с графиками
- [ ] Currency Converter
- [ ] Settings Screen (язык, валюта по умолчанию)
- [ ] Export данных (PDF, CSV)
- [ ] Push Notifications

---

## 🧪 Тестирование

### Unit Tests

```bash
# Запустить все тесты
flutter test

# Конкретный тест файл
flutter test test/data/repositories/account_repository_test.dart

# С покрытием
flutter test --coverage
```

### Widget Tests

```dart
// test/presentation/widgets/account_card_test.dart
void main() {
  testWidgets('AccountCard displays balance', (tester) async {
    // TODO: Implement
  });
}
```

---

## 🚀 Развертывание

### Подготовка

1. **iOS**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Android**:
   - Проверить `android/build.gradle`
   - Убедиться что Google Services добавлены

### Build

```bash
# iOS Release
flutter build ios --release

# Android Release (APK)
flutter build apk --release

# Android Release (App Bundle для Google Play)
flutter build appbundle --release
```

---

## 📚 Ресурсы

- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Flutter Guide](https://firebase.flutter.dev)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)

---

## 🎯 Итого

После выполнения всех шагов FinanceFlow будет полнофункциональным приложением с:
- ✅ Мультиплатформной поддержкой (iOS, Android)
- ✅ Cloud синхронизацией
- ✅ Трехязычной локализацией
- ✅ Голосовым вводом
- ✅ OCR распознаванием
- ✅ Интерактивной аналитикой
- ✅ Красивым Soft UI дизайном

**Estimated time**: 4-6 недель для опытного Flutter разработчика.
