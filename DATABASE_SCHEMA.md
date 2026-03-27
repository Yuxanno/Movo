# FinanceFlow - Архитектура базы данных

## Обзор

Приложение использует **Firestore** (облачное хранилище) как основную БД и **Hive** для локального кэша на устройстве.

---

## Firestore Collections

### 1. **users** - Профили пользователей
```yaml
Collection: users
Document ID: {user_id} # UUID
Fields:
  - id: String (UUID) ✓ Primary Key
  - email: String (unique index) ✓
  - phone: String (optional)
  - language: String (ru|uz|en) default: ru
  - timezone: String (UTC+5, etc)
  - created_at: Timestamp
  - updated_at: Timestamp
  - profile_name: String
  - avatar_url: String (optional)

Indexes:
  - email (ascending, unique)
  - created_at (descending)

Subcollections:
  - None (все связанные данные в родительских коллекциях)
```

---

### 2. **accounts** - Именованные счета (мультисчеты)
```yaml
Collection: accounts
Document ID: {account_id} # UUID
Fields:
  - id: String (UUID) ✓ Primary Key
  - user_id: String (FK → users.id) ✓
  - name: String (Дом, Семья, Бизнес, etc)
  - icon: String (emoji: 🏠, 👨‍👩‍👧‍👦, 💼)
  - balance: Double (0.0 default)
  - currency: String (UZS|USD|RUB)
  - color: String (hex: #6366F1)
  - is_shared: Boolean (false default)
  - owner_id: String (FK → users.id) ✓
  - created_at: Timestamp
  - updated_at: Timestamp

Indexes:
  - user_id (ascending)
  - owner_id (ascending)
  - is_shared (ascending)
  - created_at (descending)

Subcollections:
  - members (account_members - документы пользователей с доступом)

Rules (RLS):
  - Read: owner_id == request.auth.uid OR user_id in members
  - Write/Delete: owner_id == request.auth.uid
```

---

### 3. **account_members** - Совместный доступ к счетам
```yaml
Subcollection: accounts/{account_id}/members
Document ID: {user_id} # UUID пользователя, приглашенного к счету
Fields:
  - id: String (UUID) ✓ Primary Key (= user_id)
  - account_id: String (FK → accounts.id) ✓
  - user_id: String (FK → users.id) ✓
  - role: String (owner|editor|viewer)
  - joined_at: Timestamp
  - invited_by: String (FK → users.id)
  - invited_at: Timestamp

Indexes:
  - account_id (ascending)
  - user_id (ascending)
  - role (ascending)

Rules (RLS):
  - Read: account_id owner or member of this account
  - Write: account_id owner only
```

---

### 4. **transactions** - История операций
```yaml
Collection: transactions
Document ID: {transaction_id} # UUID
Fields:
  - id: String (UUID) ✓ Primary Key
  - account_id: String (FK → accounts.id) ✓
  - user_id: String (FK → users.id) ✓
  - amount: Double (positive for income, negative for expense)
  - currency: String (UZS|USD|RUB)
  - original_currency: String (optional, if converted)
  - converted_amount: Double (optional)
  - exchange_rate: Double (optional)
  - category_id: String (FK → categories.id) ✓
  - description: String (Продукты, Такси, etc)
  - type: String (income|expense|transfer)
  - date: Timestamp (when transaction occurred)
  - created_at: Timestamp
  - updated_at: Timestamp
  - receipt_url: String (optional, Firebase Storage URL)
  - tags: Array<String> (optional: #groceries, #urgent)

Indexes:
  - account_id (ascending), date (descending)
  - user_id (ascending), date (descending)
  - category_id (ascending), date (descending)
  - type (ascending), date (descending)
  - account_id (ascending), type (ascending), date (descending)

Rules (RLS):
  - Read: user_id == request.auth.uid OR account member
  - Write/Delete: user_id == request.auth.uid
```

---

### 5. **categories** - Категории расходов/доходов
```yaml
Collection: categories
Document ID: {category_id} # UUID
Fields:
  - id: String (UUID) ✓ Primary Key
  - user_id: String (FK → users.id) ✓
  - name: String (Продукты, Транспорт, Развлечения, Зарплата)
  - icon: String (emoji: 🛒, 🚕, 🎬, 💼)
  - color: String (hex: #FB923C)
  - type: String (income|expense|both)
  - is_default: Boolean (true for predefined)
  - sort_order: Integer (for UI ordering)
  - created_at: Timestamp

Indexes:
  - user_id (ascending), is_default (descending)
  - user_id (ascending), type (ascending)

Default Categories:
  - 🛒 Продукты (expense)
  - 🚕 Транспорт (expense)
  - 🎬 Развлечения (expense)
  - 💡 Коммунальные (expense)
  - 🏥 Здоровье (expense)
  - 📚 Образование (expense)
  - 💼 Зарплата (income)
  - 📌 Прочее (both)
```

---

### 6. **currency_rates** - Курсы валют (кэш)
```yaml
Collection: currency_rates
Document ID: {from_currency}_{to_currency}_{timestamp} # UZS_USD_2024031
Fields:
  - id: String (UUID) ✓ Primary Key
  - from_currency: String (UZS)
  - to_currency: String (USD|RUB)
  - rate: Double (12500.0)
  - source: String (api.example.com)
  - fetched_at: Timestamp
  - expires_at: Timestamp (current_time + 1 hour)

Indexes:
  - from_currency (ascending), to_currency (ascending), fetched_at (descending)

Auto-deletion:
  - Firestore TTL policy: 1 hour expiration
```

---

## Hive Local Cache

Используется для **оффлайн-первого подхода** и синхронизации локальных данных:

### Boxes:
```dart
// Локальный кэш данных
'accounts' → List<AccountModel>
'transactions' → List<TransactionModel>
'categories' → List<CategoryModel>
'currency_rates' → Map<String, CurrencyRate>
'user_prefs' → Map<String, dynamic>
  - last_sync_time: DateTime
  - offline_transactions: List (queue for sync)
```

---

## Security Rules (Firestore)

```yaml
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users Collection
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Accounts Collection
    match /accounts/{accountId} {
      allow read: if request.auth.uid == resource.data.user_id 
                     || request.auth.uid in resource.data.members;
      allow create: if request.auth.uid == request.resource.data.owner_id;
      allow update, delete: if request.auth.uid == resource.data.owner_id;

      // Account Members Subcollection
      match /members/{memberId} {
        allow read: if request.auth.uid == get(/databases/$(database)/documents/accounts/$(accountId)).data.owner_id
                       || request.auth.uid == memberId;
        allow write: if request.auth.uid == get(/databases/$(database)/documents/accounts/$(accountId)).data.owner_id;
      }
    }

    // Transactions Collection
    match /transactions/{transactionId} {
      allow read, write: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid == request.resource.data.user_id;
    }

    // Categories Collection
    match /categories/{categoryId} {
      allow read, write: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid == request.resource.data.user_id;
    }

    // Currency Rates (public read)
    match /currency_rates/{rateId} {
      allow read: if true;
    }
  }
}
```

---

## API Endpoints (Future Firebase Cloud Functions)

### Authentication
- `POST /auth/register` - Регистрация
- `POST /auth/login` - Вход
- `POST /auth/logout` - Выход
- `POST /auth/refresh-token` - Обновление токена

### Accounts
- `GET /accounts` - Список счетов пользователя
- `POST /accounts` - Создание счета
- `PUT /accounts/{id}` - Редактирование
- `DELETE /accounts/{id}` - Удаление
- `POST /accounts/{id}/share` - Приглашение члена

### Transactions
- `GET /accounts/{id}/transactions` - История транзакций
- `POST /transactions` - Создание транзакции
- `PUT /transactions/{id}` - Редактирование
- `DELETE /transactions/{id}` - Удаление
- `POST /transactions/{id}/receipt` - Загрузка чека (OCR)

### Analytics
- `GET /accounts/{id}/analytics/summary` - Сводка по месяцам
- `GET /accounts/{id}/analytics/categories` - Расходы по категориям
- `GET /accounts/{id}/analytics/trends` - Тренды за период

### Currency
- `GET /currency/rates` - Текущие курсы
- `POST /currency/convert` - Конвертация суммы

---

## Миграции и Setup

### Phase 1 - Инициализация (Done ✓)
- Создание Firestore Collections
- Установка Security Rules
- Создание индексов

### Phase 2 - Синхронизация
- Riverpod Providers для синхронизации
- Cloud Functions для аггрегации
- FCM интеграция для уведомлений

### Phase 3 - Аналитика
- Хранение аналитических снимков
- Cloud Tasks для аргрегирования данных

---

## Оптимизация и Performance

### Query Optimization
```dart
// ✓ Оптимальные запросы
db.collection('transactions')
  .where('account_id', isEqualTo: accountId)
  .orderBy('date', descending: true)
  .limit(50)

// ✗ Избегаем (требует индекс)
db.collection('transactions')
  .where('type', isEqualTo: 'expense')
  .where('date', isGreaterThan: startDate)
  .orderBy('date', descending: true)
```

### Firestore Indexes (Auto-created)
- Composite indexes for complex queries
- TTL for old records in currency_rates

### Caching Strategy
1. **Local (Hive)**: Кэш последних 100 транзакций
2. **Remote (Firestore)**: Полная история
3. **Memory (Riverpod)**: Текущая сессия (30 минут TTL)

---

## Резервное копирование и восстановление

- Автоматические снимки Firestore (Google управляет)
- Экспорт данных в PDF/CSV через Cloud Functions
- User данные могут быть удалены (GDPR compliance)

---

## Примеры Dart/Flutter моделей

```dart
// Freezed для type-safety
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String accountId,
    required String userId,
    required double amount,
    required String currency,
    required String categoryId,
    required String description,
    required String type, // income, expense, transfer
    required DateTime date,
    required DateTime createdAt,
    String? receiptUrl,
  }) = _Transaction;

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      accountId: data['account_id'],
      userId: data['user_id'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'],
      categoryId: data['category_id'],
      description: data['description'],
      type: data['type'],
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      receiptUrl: data['receipt_url'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'account_id': accountId,
    'user_id': userId,
    'amount': amount,
    'currency': currency,
    'category_id': categoryId,
    'description': description,
    'type': type,
    'date': Timestamp.fromDate(date),
    'created_at': Timestamp.fromDate(createdAt),
    'receipt_url': receiptUrl,
  };
}
```

---

## Заключение

Эта архитектура обеспечивает:
- ✓ Безопасность (RLS в Firestore)
- ✓ Масштабируемость (облачное хранилище)
- ✓ Оффлайн функционал (Hive кэш)
- ✓ Real-time синхронизация (Firestore listeners)
- ✓ Быстрые запросы (оптимизированные индексы)
