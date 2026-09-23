# Movo — Премиум-приложение для управления личными финансами

Современное мобильное и веб-приложение для управления личными финансами с поддержкой нескольких счетов, голосового ввода и интерактивной аналитики.

---

## 🚀 Быстрый старт

### Предварительные требования

- Node.js 20+
- Flutter 3.19+
- MongoDB (локальный или облачный, например MongoDB Atlas)
- .env файл (создай из .env.example)

### Установка зависимостей

```bash
# Для веб-части (Next.js)
npm install
# или
pnpm install

# Для мобильной части (Flutter)
flutter pub get
```

### Настройка переменных окружения

Создай файл `.env` в корне проекта по образцу `.env.example`:

```env
MONGODB_URI=mongodb://localhost:27017/movo
JWT_SECRET=your-secret-key-here
```

### Запуск

#### Веб-версия (Next.js)

```bash
npm run dev
# или
pnpm dev
```
Открой в браузере [http://localhost:3000](http://localhost:3000)

#### Мобильная версия (Flutter)

```bash
# На устройстве/эмуляторе
flutter run

# В браузере (Chrome)
flutter run -d chrome
```

---

## 📦 Стек технологий

### Веб-часть (Next.js API + Frontend)
- Next.js 16.2
- React 19
- TypeScript
- MongoDB + Mongoose
- Zod (валидация)
- Tailwind CSS
- Radix UI (компоненты)
- Zustand (стейт-менеджмент)

### Мобильная часть (Flutter)
- Flutter 3.19+
- Provider (стейт-менеджмент)
- http (запросы к API)
- flutter_secure_storage (хранение секретов)
- google_mobile_ads (реклама)

---

## 📁 Структура проекта

```
movo/
├── app/                    # Next.js App Router
│   └── api/               # API маршруты
│       ├── accounts/
│       ├── auth/
│       ├── categories/
│       ├── currency/
│       ├── scan-receipt/
│       ├── transactions/
│       └── voice/
├── lib/                   # Общий код
│   ├── core/              # Core утилиты
│   ├── data/              # Data layer (Flutter)
│   ├── models/            # Mongoose модели
│   ├── presentation/      # UI Flutter
│   ├── auth.ts            # JWT утилиты
│   ├── db.ts              # Подключение к MongoDB
│   └── validators.ts      # Zod схемы
├── project-memory/        # Память проекта (задачи, проблемы)
├── public/                # Статические файлы Next.js
├── scripts/               # Скрипты
├── test/                  # Тесты Flutter
└── web/                   # Flutter web файлы
```

---

## 📝 Память проекта

Для отслеживания задач и проблем смотри файлы в директории `project-memory/`:
- `tasks.json` — список задач
- `issues.json` — найденные проблемы
- `decisions.md` — принятые архитектурные решения

---

## 📜 Лицензия

MIT
