# FinanceFlow - Premium Financial Management App

Современное мобильное приложение для управления личными финансами с поддержкой мультисчетов, голосового ввода, умного распознавания чеков и интерактивной аналитики.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue)
![Dart](https://img.shields.io/badge/Dart-3.1%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 🌟 Ключевые особенности

### 💼 Управление финансами
- **Мультисчеты** - Создавайте именованные счеты (Дом, Семья, Бизнес) с независимыми балансами
- **Многовалютность** - Поддержка UZS, USD, RUB с автоматическим конвертированием
- **История операций** - Полная история всех транзакций с фильтрацией и поиском

### 🎤 Умный ввод
- **Голосовой ввод** - Распознавание речи: "Расход 50 000 сум на продукты со счета Дом"
- **Распознавание чеков** - OCR для автоматического извлечения суммы и даты из чеков
- **Конвертер валют** - Real-time конвертация с курсами Центрального Банка

### 📊 Аналитика
- **Интерактивные графики** - Pie charts по категориям, line charts для трендов
- **Детальные отчеты** - Анализ расходов по месяцам и категориям
- **Экспорт данных** - Скачивание отчетов в PDF и CSV

### 👥 Совместный доступ
- **Общие счеты** - Синхронизация счета "Семья" между несколькими пользователями
- **Управление ролями** - Owner, Editor, Viewer с разными правами доступа
- **Real-time синхронизация** - Облачное хранилище с Firestore

### 🎨 Дизайн
- **Soft UI дизайн** - Мягкие тени, скругленные углы (24px), минималистичный стиль
- **Светлая тема** - Приятная палитра с индиго акцентом (#6366F1)
- **Адаптивный интерфейс** - Оптимизирован для всех размеров экранов

### 🌐 Локализация
- **Русский** - Полная поддержка русского языка
- **Узбекский (Latin)** - Поддержка узбекского языка на латинице
- **Английский** - English interface
- **Динамическая смена** - Переключение языков в параметрах

---

## 📱 Скриншоты

```
┌─────────────────┐
│  HOME SCREEN    │
├─────────────────┤
│ Добро пожаловать!│
│ Вторник, 20 мар │
│                 │
│ Общий баланс    │
│ 4.7M сўм  +12%  │
│                 │
│ Мои счета     + │
│ ┌─────────────┐ │
│ │ 🏠 Дом      │ │
│ │ 500K сўм    │ │
│ └─────────────┘ │
│                 │
│ Quick Actions   │
│ 💰 📈 🎤 📄   │
│                 │
│ Последние опер. │
│ 🛒 -50K | 2ч   │
│ 💼 +150K| вчера│
│ 🚕 -25K | 2дн  │
└─────────────────┘
```

---

## 🚀 Быстрый старт

### Предварительные требования

- Flutter 3.19+ ([install](https://flutter.dev/docs/get-started/install))
- Dart 3.1+
- Android Studio или Xcode
- Firebase Project ([setup](https://firebase.google.com/docs/flutter/setup))

### Установка

1. **Клонируйте репозиторий**
```bash
git clone https://github.com/yourusername/financeflow.git
cd financeflow
```

2. **Установите зависимости**
```bash
flutter pub get
```

3. **Запустите код генератор** (для Freezed моделей)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Настройте Firebase**
   - Создайте Firebase Project на [console.firebase.google.com](https://console.firebase.google.com)
   - Скачайте `GoogleService-Info.plist` (iOS) и `google-services.json` (Android)
   - Поместите файлы в соответствующие директории:
     - iOS: `ios/Runner/`
     - Android: `android/app/`

5. **Запустите приложение**
```bash
# iOS
flutter run -t lib/main.dart

# Android
flutter run --target lib/main.dart

# Web
flutter run -d web
```

---

## 📁 Структура проекта

```
financeflow/
├── lib/
│   ├── main.dart                    # Точка входа
│   ├── core/                        # Общие утилиты
│   │   ├── config/
│   │   │   ├── constants.dart       # Цвета, размеры
│   │   │   └── app_config.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData (Soft UI)
│   │   │   └── app_colors.dart
│   │   └── utils/
│   │       ├── currency_formatter.dart
│   │       ├── date_formatter.dart
│   │       └── validators.dart
│   │
│   ├── data/                        # Data Layer
│   │   ├── models/
│   │   │   ├── account_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   └── category_model.dart
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   └── repositories/
│   │       └── *_repository_impl.dart
│   │
│   ├── domain/                      # Domain Layer
│   │   ├── entities/
│   │   │   ├── account.dart
│   │   │   └── transaction.dart
│   │   └── repositories/
│   │       └── *_repository.dart
│   │
│   └── presentation/                # UI Layer
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── accounts_screen.dart
│       │   ├── analytics_screen.dart
│       │   └── settings_screen.dart
│       ├── widgets/
│       │   ├── account_card.dart
│       │   └── transaction_item.dart
│       └── providers/
│           ├── account_provider.dart
│           └── transaction_provider.dart
│
├── assets/
│   ├── l10n/                        # Локализация
│   │   ├── en.yaml
│   │   ├── ru.yaml
│   │   └── uz.yaml
│   ├── fonts/
│   │   ├── Inter-*.ttf
│   │   └── Poppins-*.ttf
│   └── images/
│
├── test/                            # Тесты
│   ├── domain/
│   ├── data/
│   └── presentation/
│
├── pubspec.yaml                     # Зависимости
├── DATABASE_SCHEMA.md               # Архитектура БД
├── ARCHITECTURE.md                  # Архитектура приложения
└── README.md                        # Этот файл
```

---

## 🔧 Конфигурация

### Firestore Rules

Скопируйте правила безопасности в [Firebase Console](https://console.firebase.google.com) → Firestore → Rules:

```yaml
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /accounts/{accountId} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow write: if request.auth.uid == resource.data.owner_id;
    }
    match /transactions/{transactionId} {
      allow read, write: if request.auth.uid == resource.data.user_id;
    }
  }
}
```

### Environment Variables

Создайте `.env` файл (если используется):
```
FIREBASE_API_KEY=xxx
FIREBASE_PROJECT_ID=financeflow-xxx
FIREBASE_APP_ID=xxx
```

---

## 🎯 Функциональность по фазам

### Phase 1 ✅ (Current)
- [x] Структура проекта и архитектура
- [x] Дизайн-система (Soft UI, светлая тема)
- [x] Главный экран с карточками счетов
- [x] Компоненты UI (AccountCard, TransactionItem)
- [x] Bottom Navigation
- [x] Модели данных (Freezed)

### Phase 2 🔄 (In Progress)
- [ ] Riverpod Providers для синхронизации
- [ ] Firebase Authentication
- [ ] Firestore интеграция
- [ ] Hive локальное кэширование
- [ ] Полная локализация (i18n)

### Phase 3 📅 (Planned)
- [ ] Голосовой ввод (Speech-to-Text)
- [ ] OCR для чеков (ML Kit)
- [ ] Интерактивные графики (fl_chart)
- [ ] Совместный доступ (Realtime sync)
- [ ] Конвертер валют (API интеграция)

### Phase 4 🚀 (Future)
- [ ] Push уведомления
- [ ] Анализ расходов (ML)
- [ ] Export PDF/CSV
- [ ] Backup & Restore
- [ ] Dark mode

---

## 🧪 Тестирование

### Unit Tests
```bash
flutter test test/domain/repositories/
```

### Widget Tests
```bash
flutter test test/presentation/widgets/
```

### Integration Tests
```bash
flutter test integration_test/
```

### Полное тестирование
```bash
flutter test
```

---

## 📚 Документация

- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Структура Firestore, таблицы, индексы
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Clean Architecture, слои, data flow
- **[CONTRIBUTION.md](./CONTRIBUTION.md)** - Руководство для контрибьютеров (Coming Soon)

---

## 🛠️ Инструменты разработки

### DevTools
```bash
# Запустите Flutter DevTools
flutter pub global activate devtools
devtools

# Откройте http://localhost:9100
```

### Riverpod Generator
```bash
# Автоматическая генерация провайдеров
flutter pub run build_runner build
```

### Code Generation
```bash
# Freezed моделии json serialization
flutter pub run build_runner watch
```

---

## 🐛 Известные проблемы

- [ ] Голосовой ввод требует дополнительных разрешений на iOS 14+
- [ ] Синхронизация Firebase может иметь задержку в оффлайн-режиме
- [ ] OCR требует Google ML Kit Firebase (beta функционал)

---

## 🤝 Вклад

Мы приветствуем вклад в проект! Пожалуйста:

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit ваши изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. [LICENSE](./LICENSE) для деталей.

---

## 👨‍💻 Автор

**FinanceFlow Development Team**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: dev@financeflow.app

---

## 🙏 Благодарности

- [Flutter Team](https://flutter.dev) за отличный фреймворк
- [Riverpod](https://riverpod.dev) за управление состоянием
- [Firebase](https://firebase.google.com) за облачное хранилище
- [Google Fonts](https://fonts.google.com) за типографику

---

## 📞 Поддержка

Если у вас есть вопросы или нужна помощь:
- 📧 Email: support@financeflow.app
- 💬 Discord: [Join our community](https://discord.gg/xxx)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/financeflow/issues)

---

**FinanceFlow** - Управляйте финансами умно и красиво! 💰✨
