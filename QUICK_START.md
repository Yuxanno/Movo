# FinanceFlow - Quick Start Guide

Быстрый гайд для запуска приложения и разработки.

---

## 🚀 За 5 минут до первого запуска

### 1. Установить зависимости

```bash
flutter pub get
```

### 2. Запустить приложение

```bash
# На все платформы (требует подключенное устройство или эмулятор)
flutter run

# Или на конкретной платформе
flutter run -d ios        # iOS simulator
flutter run -d android    # Android emulator
flutter run -d web        # Chrome browser
```

### 3. Готово! 🎉

Вы должны увидеть:
- **Home Screen** с балансом, карточками счетов и историей операций
- **Bottom Navigation** с 4 экранами
- **Soft UI дизайн** с мягкими тенями и скругленными углами

---

## 📂 Ключевые файлы

### Главный код

| Файл | Назначение |
|------|-----------|
| `lib/main.dart` | Точка входа |
| `lib/core/theme/app_theme.dart` | Тема (цвета, шрифты) |
| `lib/core/config/constants.dart` | Константы (размеры, цвета) |
| `lib/presentation/screens/home_screen.dart` | Главный экран |
| `lib/presentation/widgets/account_card.dart` | Карточка счета |
| `lib/presentation/widgets/transaction_item.dart` | Элемент операции |

### Документация

| Файл | Содержание |
|------|-----------|
| `README.md` | Обзор проекта, установка, структура |
| `ARCHITECTURE.md` | Clean Architecture, слои, patterns |
| `DATABASE_SCHEMA.md` | Firestore, Hive, Security Rules |
| `EXAMPLES.md` | Code snippets (Riverpod, Voice, OCR) |
| `NEXT_STEPS.md` | План развития, TODO лист |
| `VISUAL_GUIDE.md` | UI/UX, wireframes, animations |
| `PROJECT_SUMMARY.md` | Итоговое резюме проекта |

---

## 🎨 Как использовать компоненты

### AccountCard (Карточка счета)

```dart
import 'package:financeflow/presentation/widgets/account_card.dart';

AccountCard(
  account: accountModel,
  isSelected: true,
  onTap: () => print('Tapped account'),
)
```

### TransactionItem (Элемент операции)

```dart
import 'package:financeflow/presentation/widgets/transaction_item.dart';

TransactionItem(
  transaction: transactionModel,
  onTap: () => print('Tapped transaction'),
)
```

---

## 🛠️ Разработка

### Hot Reload

```bash
# Сохранить файл - автоматически перезагружается
# Или нажать 'r' в консоли для Hot Reload
# Или 'R' для полного перестарта
```

### DevTools

```bash
# Открыть Flutter DevTools
flutter pub global activate devtools
devtools
# Перейти на http://localhost:9100
```

### Логирование

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

---

## 📊 Структура данных

### Демо данные

Главный экран использует демо данные:

```dart
// lib/presentation/screens/home_screen.dart

accounts = [
  AccountModel.demo(),           // 🏠 Дом - 500K UZS
  AccountModel(...),             // 👨‍👩‍👧 Семья - 1.2M UZS (Shared)
  AccountModel(...),             // 💼 Бизнес - 3.5M USD
];

transactions = [
  TransactionModel.demo1(),      // Расход 50K
  TransactionModel.demo2(),      // Доход 150K
  TransactionModel.demo3(),      // Расход 25K
];
```

### Добавить свои данные

```dart
final account = AccountModel(
  id: 'acc_1',
  userId: 'user_1',
  name: 'Мой счет',
  icon: '💰',
  balance: 1000000,
  currency: 'UZS',
  color: '#6366F1',
  isShared: false,
  ownerId: 'user_1',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

---

## 🎨 Кастомизация дизайна

### Изменить цвета

```dart
// lib/core/config/constants.dart
class AppColors {
  static const Color primaryAccent = Color(0xFF6366F1); // Измени сюда
  static const Color secondaryAccent = Color(0xFF10B981);
  static const Color negativeAccent = Color(0xFFEF4444);
}
```

### Изменить шрифты

```dart
// lib/core/theme/app_theme.dart
bodyLarge: GoogleFonts.inter(      // Измени сюда
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppColors.textPrimary,
),
```

### Изменить размеры

```dart
// lib/core/config/constants.dart
class AppSizes {
  static const double borderRadiusXL = 24.0;    // Измени сюда
  static const double paddingLarge = 16.0;
}
```

---

## 🔗 Форматирование валют и дат

### Использование утилит

```dart
import 'package:financeflow/core/utils/currency_formatter.dart';
import 'package:financeflow/core/utils/date_formatter.dart';

// Валюты
50000.toCurrency('UZS');           // '50 000 сўм'
1200000.toCurrencyCompact('UZS');  // '1.2M сўм'

// Даты
DateTime.now().toTransactionDate(); // 'Сегодня'
DateTime.now().toTime();            // '14:30'
DateTime.now().toRelativeTime();    // '2 часа назад'
```

---

## ✅ Чеклист для разработки Phase 2

- [ ] Создать `lib/presentation/providers/account_provider.dart`
- [ ] Создать `lib/presentation/providers/transaction_provider.dart`
- [ ] Создать `lib/data/repositories/account_repository_impl.dart`
- [ ] Интегрировать Firebase Auth
- [ ] Настроить Hive boxes
- [ ] Добавить Firestore datasource
- [ ] Создать Login Screen
- [ ] Реализовать CRUD операции
- [ ] Добавить локализацию (i18n)
- [ ] Написать unit тесты

Подробный гайд: смотрите **NEXT_STEPS.md**

---

## 📚 Ресурсы

### Официальная документация
- [Flutter docs](https://flutter.dev)
- [Dart docs](https://dart.dev)
- [Material Design 3](https://material.io/design)

### Библиотеки
- [Riverpod docs](https://riverpod.dev)
- [Firebase Flutter](https://firebase.flutter.dev)
- [Freezed](https://pub.dev/packages/freezed)

### Примеры
- **EXAMPLES.md** - Ready-to-use code snippets
- **ARCHITECTURE.md** - Design patterns
- **DATABASE_SCHEMA.md** - Backend setup

---

## 🐛 Решение проблем

### "flutter: command not found"

```bash
# Добавить Flutter в PATH
export PATH="$PATH:$HOME/flutter/bin"
```

### "Packages out of date"

```bash
flutter pub upgrade
flutter pub get
```

### "Build failing"

```bash
flutter clean
flutter pub get
flutter run
```

### "Emulator/Device not found"

```bash
# Список доступных устройств
flutter devices

# Запустить эмулятор
open -a Simulator              # iOS
emulator -avd Pixel_5          # Android
```

---

## 📋 Файловая структура

```
financeflow/
├── lib/
│   ├── main.dart                   ← Начни отсюда
│   ├── core/                       ← Shared utils & theme
│   │   ├── config/constants.dart
│   │   ├── theme/app_theme.dart
│   │   └── utils/
│   ├── data/                       ← Data layer
│   │   ├── models/
│   │   ├── datasources/
│   │   └── repositories/
│   ├── domain/                     ← Business logic
│   │   ├── entities/
│   │   └── repositories/
│   └── presentation/               ← UI
│       ├── screens/
│       │   ├── home_screen.dart    ← Главный экран
│       │   └── app_shell.dart      ← Navigation
│       ├── widgets/
│       │   ├── account_card.dart
│       │   └── transaction_item.dart
│       └── providers/
│
├── assets/
│   ├── l10n/                       ← Переводы
│   ├── fonts/                      ← Шрифты
│   └── images/                     ← Изображения
│
├── pubspec.yaml                    ← Зависимости
├── README.md                       ← Документация
└── *.md                            ← Другие гайды
```

---

## 🎯 Типичные задачи

### Добавить новый экран

```dart
// 1. Создать файл
// lib/presentation/screens/my_screen.dart

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Center(child: Text('Hello')),
    );
  }
}

// 2. Добавить в Navigation
// lib/presentation/screens/app_shell.dart
static const List<Widget> _screens = [
  HomeScreen(),
  MyScreen(),  // ← Добавить
  ...
];
```

### Добавить новую категорию

```dart
// lib/presentation/widgets/transaction_item.dart
static const Map<String, String> categoryEmojis = {
  'cat_food': '🛒',
  'cat_my_new': '🎯',  // ← Добавить
};

static const Map<String, Color> categoryColors = {
  'cat_food': AppColors.categoryFood,
  'cat_my_new': Color(0xFF12AB45),  // ← Добавить
};
```

### Форматировать новую валюту

```dart
// lib/core/utils/currency_formatter.dart
static const Map<String, String> currencySymbols = {
  'UZS': 'сўм',
  'USD': '\$',
  'RUB': '₽',
  'EUR': '€',  // ← Добавить
};
```

---

## 🚀 Развертывание

### Build для iOS

```bash
flutter build ios --release
# Откроется Xcode для final setup
```

### Build для Android

```bash
flutter build appbundle --release
# APK находится в build/app/outputs/
```

### Build для Web

```bash
flutter build web --release
# Результат в build/web/
```

---

## 💡 Pro Tips

### 1. Используй const везде

```dart
// ✅ Хорошо
const SizedBox(height: 16);

// ❌ Плохо
SizedBox(height: 16);
```

### 2. Используй extensions

```dart
// ✅ Хорошо
50000.toCurrency('UZS')

// ❌ Плохо
CurrencyFormatter.format(50000, 'UZS')
```

### 3. Используй named parameters

```dart
// ✅ Хорошо
AccountCard(
  account: account,
  isSelected: true,
  onTap: () => {},
)

// ❌ Плохо
AccountCard(account, true, () => {})
```

---

## 🎓 Следующие шаги

1. **Запусти приложение** - `flutter run`
2. **Изучи файлы** - Начни с `main.dart` и `home_screen.dart`
3. **Прочитай документацию** - ARCHITECTURE.md для понимания структуры
4. **Добавь Firebase** - Следуй NEXT_STEPS.md
5. **Напиши тесты** - Unit tests для repositories

---

## 📞 Помощь

Не знаешь что делать? Смотри:
1. **QUICK_START.md** - Этот файл (быстрые ответы)
2. **README.md** - Описание проекта
3. **EXAMPLES.md** - Code snippets
4. **ARCHITECTURE.md** - Как устроено
5. **NEXT_STEPS.md** - Что делать дальше

---

## ✨ Готово!

Ты установил **FinanceFlow** - полнофункциональное приложение управления финансами на Flutter с профессиональной архитектурой и красивым Soft UI дизайном.

**Happy coding!** 🚀
