# FinanceFlow - Архитектура приложения Flutter

## 1. Обзор архитектуры

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (Presentation)                 │
│  Screens | Widgets | Pages | Navigation                      │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│             State Management Layer (Riverpod)               │
│  Providers | AsyncNotifiers | StateNotifiers                 │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│            Domain Layer (Business Logic)                     │
│  Entities | Use Cases | Repository Interfaces               │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────┴──────────────────────────────────────────┐
│             Data Layer (Persistence)                         │
│  Models | Repositories | Data Sources (Local & Remote)      │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────┴─────┐         ┌────┴─────┐
   │   Hive   │         │ Firestore │
   │ (Local)  │         │  (Cloud)  │
   └──────────┘         └──────────┘
```

## 2. Слои архитектуры

### 2.1 Presentation Layer (UI)

**Расположение**: `lib/presentation/`

Структура:
```
presentation/
├── screens/
│   ├── home_screen.dart           # Главный экран с балансом и операциями
│   ├── accounts_screen.dart       # Управление счетами
│   ├── analytics_screen.dart      # Графики и отчеты
│   ├── add_transaction_screen.dart # Добавление операции
│   ├── voice_input_screen.dart    # Голосовой ввод
│   ├── settings_screen.dart       # Параметры
│   └── app_shell.dart             # Navigation Shell
│
├── widgets/
│   ├── account_card.dart          # Карточка счета (Soft UI)
│   ├── transaction_item.dart      # Элемент операции
│   ├── soft_ui_button.dart        # Кнопка (Soft UI)
│   ├── currency_input_field.dart  # Поле ввода суммы
│   ├── chart_widgets.dart         # Компоненты графиков
│   └── navigation_bar.dart        # Bottom Navigation
│
└── providers/
    ├── account_provider.dart      # Состояние счетов
    ├── transaction_provider.dart  # Состояние операций
    ├── analytics_provider.dart    # Состояние аналитики
    ├── auth_provider.dart         # Состояние аутентификации
    └── locale_provider.dart       # Состояние локализации
```

**Ключевые принципы**:
- Каждый экран — это StatefulWidget или Stateless
- Используем Riverpod для управления состоянием
- UI компоненты полностью переиспользуемы
- Отделяем бизнес-логику от UI

**Пример использования Riverpod**:
```dart
// В screen
final accountsAsync = ref.watch(accountsProvider);

accountsAsync.when(
  data: (accounts) => ListView(...),
  loading: () => LoadingWidget(),
  error: (err, stack) => ErrorWidget(),
);
```

---

### 2.2 State Management Layer (Riverpod)

**Расположение**: `lib/presentation/providers/`

Использует **Riverpod 2.x** для type-safe state management:

```dart
// Simple Provider (computed state)
final totalBalanceProvider = Provider((ref) {
  final accounts = ref.watch(accountsProvider).maybeWhen(
    data: (data) => data,
    orElse: () => [],
  );
  return accounts.fold(0.0, (sum, acc) => sum + acc.balance);
});

// Async Provider (fetch from repository)
final accountsProvider = FutureProvider((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAccounts();
});

// State Notifier (complex state management)
final selectedAccountProvider = StateNotifierProvider<
    SelectedAccountNotifier,
    String?
>((ref) => SelectedAccountNotifier());

class SelectedAccountNotifier extends StateNotifier<String?> {
  SelectedAccountNotifier() : super(null);
  
  void selectAccount(String accountId) {
    state = accountId;
  }
}
```

**Преимущества Riverpod**:
- ✓ Type-safe (no runtime errors)
- ✓ Easy testing (all logic is pure functions)
- ✓ Automatic caching & invalidation
- ✓ Excellent DevTools support
- ✓ No BuildContext dependencies

---

### 2.3 Domain Layer (Business Logic)

**Расположение**: `lib/domain/`

```
domain/
├── entities/
│   ├── account.dart       # Pure Dart class (не зависит от BDD)
│   ├── transaction.dart
│   ├── user.dart
│   └── category.dart
│
└── repositories/
    ├── account_repository.dart          # Abstract interface
    ├── transaction_repository.dart
    └── currency_repository.dart
```

**Сущности (Entities)** - чистые Dart классы:
```dart
// domain/entities/account.dart
class Account {
  final String id;
  final String name;
  final double balance;
  final String currency;
  // ... методы бизнес-логики
}
```

**Repository Interfaces** - контракты для Data слоя:
```dart
abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<Account> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
  Stream<List<Account>> watchAccounts();
}
```

---

### 2.4 Data Layer (Persistence)

**Расположение**: `lib/data/`

```
data/
├── datasources/
│   ├── local/
│   │   ├── account_local_datasource.dart   # Hive операции
│   │   └── transaction_local_datasource.dart
│   │
│   └── remote/
│       ├── account_remote_datasource.dart  # Firestore операции
│       ├── transaction_remote_datasource.dart
│       └── currency_rate_remote_datasource.dart
│
├── models/
│   ├── account_model.dart         # Freezed моделька для сериализации
│   ├── transaction_model.dart
│   └── category_model.dart
│
└── repositories/
    ├── account_repository_impl.dart       # Реализация interface
    ├── transaction_repository_impl.dart
    └── currency_repository_impl.dart
```

**Models** с использованием Freezed:
```dart
@freezed
class AccountModel with _$AccountModel {
  const factory AccountModel({
    required String id,
    required String name,
    required double balance,
    required String currency,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  factory AccountModel.fromEntity(Account account) => AccountModel(
    id: account.id,
    name: account.name,
    balance: account.balance,
    currency: account.currency,
  );

  Account toEntity() => Account(
    id: id,
    name: name,
    balance: balance,
    currency: currency,
  );
}
```

**Data Sources**:
```dart
// local_datasource.dart
class AccountLocalDataSource {
  final Box<AccountModel> _box;

  Future<List<AccountModel>> getAccounts() async {
    return _box.values.toList();
  }

  Future<void> saveAccounts(List<AccountModel> accounts) async {
    await _box.clear();
    await _box.addAll(accounts);
  }
}

// remote_datasource.dart
class AccountRemoteDataSource {
  final FirebaseFirestore _firestore;

  Stream<List<AccountModel>> getAccountsStream(String userId) {
    return _firestore
        .collection('accounts')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
```

**Repository Implementation** (Offline-first):
```dart
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource _remoteDataSource;
  final AccountLocalDataSource _localDataSource;

  @override
  Future<List<Account>> getAccounts() async {
    try {
      // Fetch from remote
      final remoteAccounts = await _remoteDataSource.getAccounts();
      
      // Save to local cache
      await _localDataSource.saveAccounts(remoteAccounts);
      
      return remoteAccounts.map((model) => model.toEntity()).toList();
    } catch (e) {
      // Fallback to local cache
      final localAccounts = await _localDataSource.getAccounts();
      return localAccounts.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Stream<List<Account>> watchAccounts() {
    return _remoteDataSource.getAccountsStream().map(
      (models) => models.map((m) => m.toEntity()).toList(),
    );
  }
}
```

---

### 2.5 Core Layer (Shared Utilities)

**Расположение**: `lib/core/`

```
core/
├── config/
│   ├── constants.dart             # Цвета, размеры, константы
│   └── app_config.dart            # Конфиги (API keys, endpoints)
│
├── theme/
│   ├── app_theme.dart             # ThemeData (Soft UI, светлая тема)
│   ├── app_colors.dart            # Палитра цветов
│   └── app_text_styles.dart       # Текстовые стили
│
├── utils/
│   ├── currency_formatter.dart    # Форматирование валют
│   ├── date_formatter.dart        # Форматирование дат
│   ├── validators.dart            # Валидация форм
│   └── logger.dart                # Логирование
│
└── extensions/
    ├── string_extensions.dart
    ├── num_extensions.dart
    └── datetime_extensions.dart
```

---

## 3. Data Flow

### 3.1 Простой flow (Fetch Data)

```
1. UI (HomeScreen)
   │
   ├─→ ref.watch(accountsProvider)
   │
2. Riverpod Provider (accountsProvider)
   │
   ├─→ ref.watch(accountRepositoryProvider).getAccounts()
   │
3. Repository Layer
   │
   ├─→ RemoteDataSource.getAccounts() [try]
   ├─→ Save to LocalDataSource [cache]
   │
4. Firestore
   │
   ├─→ Fetch documents
   ├─→ Convert to Models
   │
5. LocalDataSource
   │
   ├─→ Save to Hive Box
   │
6. UI Update
   │
   ├─→ accountsAsync.when(
   │     data: (accounts) => ListView(...),
   │     ...
   │   )
```

### 3.2 Создание операции (Create with Sync)

```
1. UI (AddTransactionScreen)
   ├─→ Form input
   ├─→ Validate
   ├─→ Transaction(...)
   │
2. Riverpod Action (StateNotifier)
   ├─→ ref.read(transactionProvider.notifier).add(tx)
   │
3. Repository.addTransaction()
   ├─→ LocalDataSource.save() [instant feedback]
   ├─→ Add to sync queue (Hive)
   ├─→ RemoteDataSource.add() [async]
   ├─→ Update Firestore
   ├─→ Remove from queue
   │
4. UI
   ├─→ Instant update from local
   ├─→ Sync indicator (loading)
   ├─→ Sync complete
```

---

## 4. Дизайн-система (Soft UI)

### 4.1 Цветовая палитра

**Светлая тема (Light Mode)**:
```dart
AppColors.backgroundPrimary = #F8F9FA     // Background
AppColors.backgroundSecondary = #FFFFFF    // Card backgrounds
AppColors.surface = #F5F7FC                // Input fields

AppColors.primaryAccent = #6366F1          // Main accent (Indigo)
AppColors.secondaryAccent = #10B981        // Income (Green)
AppColors.negativeAccent = #EF4444         // Expense (Red)

AppColors.textPrimary = #1F2937            // Main text
AppColors.textSecondary = #6B7280          // Secondary text
AppColors.textTertiary = #9CA3AF           // Disabled text
```

### 4.2 Soft UI элементы

**Карточки** с мягкими тенями и скругленными углами:
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),   // 24px radius
    boxShadow: [
      BoxShadow(
        offset: Offset(0, 4),
        blurRadius: 12,
        color: Colors.black.withOpacity(0.08), // Мягкая тень
      ),
    ],
  ),
  child: ...,
)
```

**Кнопки**:
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryAccent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    elevation: 0, // Нет резких теней
  ),
  child: Text('Добавить'),
)
```

### 4.3 Типография

```
Display (32px, Bold) - Заголовки экранов
Heading (20px, SemiBold) - Заголовки секций
Body (16px, Regular) - Основной текст
Caption (14px, Regular) - Вторичный текст
Label (12px, Medium) - Labels в формах
```

Используем **Google Fonts**: Inter (body) + Poppins (headings)

---

## 5. Локализация (i18n)

**Расположение**: `assets/l10n/`

Используем **easy_localization** для поддержки 3 языков:

```yaml
# assets/l10n/en.yaml
home:
  greeting: "Welcome!"
  total_balance: "Total Balance"
  recent_transactions: "Recent Transactions"

accounts:
  add_account: "Add Account"
  edit_account: "Edit Account"

# assets/l10n/ru.yaml
home:
  greeting: "Добро пожаловать!"
  total_balance: "Общий баланс"
  recent_transactions: "Последние операции"

# assets/l10n/uz.yaml (Latin)
home:
  greeting: "Xush kelibsiz!"
  total_balance: "Umumiy balans"
```

**Использование в коде**:
```dart
Text(
  context.tr('home.greeting'),
  style: Theme.of(context).textTheme.headlineSmall,
)
```

---

## 6. Тестирование

### 6.1 Unit Tests

```dart
// test/domain/repositories/account_repository_test.dart
void main() {
  group('AccountRepository', () {
    late MockRemoteDataSource mockRemote;
    late MockLocalDataSource mockLocal;
    late AccountRepositoryImpl repository;

    setUp(() {
      mockRemote = MockRemoteDataSource();
      mockLocal = MockLocalDataSource();
      repository = AccountRepositoryImpl(mockRemote, mockLocal);
    });

    test('should return cached accounts when network fails', () async {
      // Arrange
      final cachedAccounts = [AccountModel.demo()];
      when(mockRemote.getAccounts()).thenThrow(Exception());
      when(mockLocal.getAccounts()).thenAnswer((_) async => cachedAccounts);

      // Act
      final result = await repository.getAccounts();

      // Assert
      expect(result, isNotEmpty);
      verify(mockLocal.getAccounts()).called(1);
    });
  });
}
```

### 6.2 Widget Tests

```dart
// test/presentation/widgets/account_card_test.dart
void main() {
  group('AccountCard Widget', () {
    testWidgets('displays account name and balance', (tester) async {
      final account = AccountModel.demo();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCard(account: account),
          ),
        ),
      );

      expect(find.text(account.name), findsOneWidget);
      expect(find.text(account.balance.toCurrency(account.currency)), findsOneWidget);
    });
  });
}
```

---

## 7. Dependency Injection

Через Riverpod (встроено):

```dart
// Регистрация синглтонов
final firebaseProvider = Provider((ref) => FirebaseFirestore.instance);
final hiveProvider = Provider((ref) => Hive.box('accounts'));

// Repository провайдеры
final accountRepositoryProvider = Provider((ref) {
  final remote = AccountRemoteDataSource(ref.watch(firebaseProvider));
  final local = AccountLocalDataSource(ref.watch(hiveProvider));
  return AccountRepositoryImpl(remote, local);
});

// Использование
final accountsProvider = FutureProvider((ref) {
  return ref.watch(accountRepositoryProvider).getAccounts();
});
```

---

## 8. Перфоманс оптимизации

1. **Lazy Loading**: Экраны загружаются при первом обращении
2. **Caching**: Hive + Riverpod встроенное кэширование
3. **Pagination**: Транзакции загружаются порциями (50 за раз)
4. **Image Optimization**: cached_network_image с placeholder'ами
5. **State Splitting**: Разделяем большое состояние на маленькие куски
6. **Const Constructors**: Используем везде где возможно

---

## 9. Документирование кода

Используем Dart документацию:

```dart
/// Форматирует сумму валюты для отображения.
/// 
/// Примеры:
/// ```dart
/// format(50000, 'UZS')  // returns '50 000 сўм'
/// format(100.50, 'USD') // returns '100.50 $'
/// ```
String format(double amount, String currency) {
  // implementation
}
```

---

## 10. Развертывание

### Структура для выпуска:

```
ios/
  Runner.xcodeproj    # iOS config
  GoogleService-Info.plist  # Firebase (iOS)

android/
  app/                # Android module
  google-services.json      # Firebase (Android)

web/
  index.html          # Web entry point
  firebase-config.js  # Firebase (Web)

lib/                  # Flutter код
pubspec.yaml          # Dependencies

.github/
  workflows/
    ci.yml            # GitHub Actions CI/CD
```

---

## Заключение

Эта архитектура обеспечивает:
- ✓ **Масштабируемость**: Clean Architecture разделение ответственности
- ✓ **Тестируемость**: Unit/Widget/Integration тесты
- ✓ **Поддерживаемость**: Четкая структура, документация
- ✓ **Производительность**: Кэширование, ленивая загрузка, оптимизация
- ✓ **Вольность**: Легко добавлять новые функции без нарушения существующего кода
