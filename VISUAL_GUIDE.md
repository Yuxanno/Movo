# FinanceFlow - Визуальное руководство

---

## 📱 UI/UX Design System

### 1. Soft UI Элементы

#### Карточки (Cards)

```
┌────────────────────────────────┐ ← Border Radius: 24px
│                                │
│  ☰ Дом              [Совместно]│ ← Header with shared badge
│  UZS                           │
│                                │
│  Баланс                        │
│  500 000 сўм                   │ ← Large, Bold, Indigo color
│                                │
└────────────────────────────────┘
        Soft Shadow (8, 4, 12)
```

#### Buttons

```
Elevated Button:
┌─────────────────────┐
│  + Добавить счет    │ ← 24px radius, no shadow, hover effect
└─────────────────────┘
Background: #6366F1 (Indigo)
Text: White, Poppins SemiBold

Outline Button:
┌─────────────────────┐
│   Отмена            │ ← Border: 1px divider
└─────────────────────┘
Background: Transparent
Border: #E5E7EB
Text: #6B7280 (Secondary)
```

#### Input Fields

```
┌─────────────────────┐
│ ○ Сумма             │ ← Focused: Blue border, 2px
│ 50 000              │ ← Placeholder: Light grey
│                     │ ← Fill: #F5F7FC (Surface)
└─────────────────────┘
Border Radius: 16px
```

---

## 🎨 Color Palette

### Light Theme

```
BACKGROUNDS:
┌─────────────────────────────────┐
│ #F8F9FA - Primary Background    │
│ #FFFFFF - Secondary (Cards)     │
│ #F5F7FC - Surface (Inputs)      │
└─────────────────────────────────┘

ACCENTS:
┌─────────────────────────────────┐
│ #6366F1 - Primary (Indigo)      │ ← Main brand
│ #10B981 - Income (Green)        │
│ #EF4444 - Expense (Red)         │
└─────────────────────────────────┘

TEXT:
┌─────────────────────────────────┐
│ #1F2937 - Primary Text          │
│ #6B7280 - Secondary Text        │
│ #9CA3AF - Tertiary (Disabled)   │
└─────────────────────────────────┘

CATEGORY COLORS:
┌─────────────────────────────────┐
│ 🛒 #FB923C - Food               │
│ 🚕 #3B82F6 - Transport          │
│ 🎬 #A855F7 - Entertainment      │
│ 💡 #06B6D4 - Utilities          │
│ 🏥 #FD08C0 - Health             │
│ 📚 #8B5CF6 - Education          │
│ 💼 #10B981 - Salary             │
└─────────────────────────────────┘
```

---

## 📐 Layout Structure

### Home Screen Layout

```
┌─────────────────────────────┐
│ ← Sliver AppBar             │
│ Добро пожаловать!           │ ← Display text
│ Вторник, 20 марта           │ ← Caption
│              [Profile Icon] │
├─────────────────────────────┤
│                             │
│ ┌───────────────────────┐   │
│ │ Общий баланс          │   │ ← Balance Card (32px v-padding)
│ │ 4.7M сўм      +12%    │   │
│ └───────────────────────┘   │
│                             │ ← 24px gap
│ Мои счета                + │ ← Heading + Add button
│ ┌─────────────────────────┐ │
│ │ 🏠 Дом                  │ │ ← Carousel
│ │ 500 000 сўм             │ │   (85% viewport)
│ └─────────────────────────┘ │
│ ● ○ ○                       │ ← Page indicator
│                             │ ← 24px gap
│ 💰 📈 🎤 📄               │ ← 4 Quick Action buttons
│                             │ ← 24px gap
│ Последние операции          │ ← Heading
│ ┌─────────────────────────┐ │
│ │ 🛒 | -50 000 | 2ч назад │ │ ← Transaction item
│ │ 💼 | +150 000| вчера    │ │
│ │ 🚕 | -25 000 | 2 дней   │ │
│ └─────────────────────────┘ │
│                             │ ← SafeArea padding
└─────────────────────────────┘

Legend:
- Responsive grid
- ScrollView with SliverAppBar
- 16px horizontal padding
- 24px vertical gaps
- Bottom navigation below
```

---

## 🔤 Typography System

### Font Hierarchy

```
DISPLAY (32px, Bold, Inter)
┌──────────────────────────────────┐
│ Welcome to FinanceFlow           │ ← Main screen titles
└──────────────────────────────────┘

HEADING (20px, SemiBold, Poppins)
┌──────────────────────────────────┐
│ Мои счета                        │ ← Section titles
└──────────────────────────────────┘

BODY LARGE (16px, Regular, Inter)
┌──────────────────────────────────┐
│ This is the main content text     │ ← Main content
└──────────────────────────────────┘

BODY MEDIUM (14px, Regular, Inter)
┌──────────────────────────────────┐
│ Secondary information             │ ← Descriptions
└──────────────────────────────────┘

LABEL (12px, Medium, Poppins)
┌──────────────────────────────────┐
│ Form labels and badges           │ ← Small UI text
└──────────────────────────────────┘
```

### Line Height

```
Tight (1.2):     "Заголовки"
Normal (1.4):    "Основной текст"
Relaxed (1.6):   "Описания и длинный текст"
```

---

## 🎭 Component Library

### 1. Account Card Component

```
┌──────────────────────────────────┐
│                                  │
│ ┌─────┐  Дом         [Совместно] │
│ │ 🏠  │                          │
│ └─────┘  UZS                     │
│                                  │
│          Баланс                  │
│          500 000 сўм             │
│                                  │
└──────────────────────────────────┘

Properties:
- Width: 300.w (responsive)
- Height: 160.h
- Margin: 8.w (left/right)
- Icon container: 40x40
- Gradient background (primary color with opacity)
- Border: 1px or 2px if selected
- BoxShadow: softShadow or selected shadow
```

### 2. Transaction Item Component

```
┌─────────────────────────────────────┐
│ ┌───┐                               │
│ │🛒 │ Продукты           -50 000 сўм│
│ └───┘ Базар              сегодня    │
│       2 часа назад                  │
│                                     │
└─────────────────────────────────────┘

Layout:
- Category icon: 44x44
- Title + Description + Date (left)
- Amount + Date (right, text-align right)
- Border bottom: 0.5px divider
- Padding: 16px horizontal, 12px vertical
```

### 3. Quick Action Button

```
    ┌──────┐
    │ 💰   │
    │      │ ← 50x50 circle
    └──────┘
    Расход  ← Label below

Properties:
- Container: 50x50 (rounded 16px)
- Icon size: 24
- Background: color.withOpacity(0.15)
- Label: 12px, centered
```

### 4. Balance Card

```
┌────────────────────────────────────┐
│                                    │
│ Общий баланс                       │
│ 4.7M сўм                 +12.5%    │
│                                    │
└────────────────────────────────────┘

Properties:
- Gradient background (primary with opacity)
- Padding: 24px
- Border radius: 24px
- Shadow: soft
```

---

## 🧭 Navigation Structure

### Navigation Hierarchy

```
ROOT (AppShell)
│
├─ Home Screen (Bottom Nav Index 0)
│  ├─ Account Detail Screen (push)
│  ├─ Add Transaction Screen (dialog)
│  └─ Voice Input Screen (dialog)
│
├─ Analytics Screen (Bottom Nav Index 1)
│  └─ Date Filter Dialog
│
├─ Accounts Screen (Bottom Nav Index 2)
│  ├─ Create Account Dialog
│  ├─ Edit Account Dialog
│  └─ Share Account Screen
│
└─ Settings Screen (Bottom Nav Index 3)
   ├─ Language Selection
   ├─ Currency Selection
   └─ Profile Settings
```

### Bottom Navigation

```
┌─────────────────────────────────────────┐
│ 🏠       📊       💼       ⚙️           │ ← Fixed height
│ Главная  Аналитика Счета   Параметры    │
└─────────────────────────────────────────┘

- Height: 64dp (with label) or 56dp (no label)
- Background: #FFFFFF
- Selected color: #6366F1
- Unselected color: #9CA3AF
- Icon size: 24
- Animation: smooth transition (300ms)
```

---

## 📊 Data Models Diagram

```
USER
├── id: String (PK)
├── email: String
├── language: String (ru|uz|en)
├── created_at: DateTime
└── accounts: List<Account> (1:N)

ACCOUNT
├── id: String (PK)
├── user_id: String (FK)
├── name: String
├── balance: Double
├── currency: String (UZS|USD|RUB)
├── icon: String (emoji)
├── color: String (hex)
├── is_shared: Boolean
├── created_at: DateTime
├── members: List<Member> (1:N)
└── transactions: List<Transaction> (1:N)

TRANSACTION
├── id: String (PK)
├── account_id: String (FK)
├── user_id: String (FK)
├── amount: Double
├── currency: String
├── category_id: String (FK)
├── description: String
├── type: String (income|expense|transfer)
├── date: DateTime
├── created_at: DateTime
└── receipt_url: String? (optional)

CATEGORY
├── id: String (PK)
├── user_id: String (FK)
├── name: String
├── icon: String (emoji)
├── color: String (hex)
├── type: String (income|expense|both)
├── is_default: Boolean
└── created_at: DateTime

ACCOUNT_MEMBER (Subcollection)
├── id: String (PK = user_id)
├── account_id: String (FK)
├── user_id: String (FK)
├── role: String (owner|editor|viewer)
└── joined_at: DateTime
```

---

## 🔄 State Management Flow

### Data Flow Diagram

```
USER ACTION (Tap Button)
        ↓
    SCREEN
        ↓
   WIDGET (build)
        ↓
   ref.watch(provider)
        ↓
   PROVIDER (FutureProvider / StateNotifier)
        ↓
   REPOSITORY (interface)
        ↓
   DATA SOURCES
   ├── LOCAL (Hive) ← Try first (offline)
   └── REMOTE (Firestore) ← Real-time sync
        ↓
    MODELS (from Freezed)
        ↓
    ENTITIES (domain layer)
        ↓
   RETURN TO PROVIDER
        ↓
    UI UPDATE
        ↓
   SCREEN REBUILD
```

### State Notifier for Add Transaction

```
UI Form
  ↓
ref.read(transactionNotifier.notifier).add(tx)
  ↓
StateNotifier receives action
  ↓
Repository.add(tx)
  ├─ LocalDataSource.save() [instant]
  ├─ RemoteDataSource.create() [async]
  └─ Update UI state
  ↓
Provider updates
  ↓
UI rebuilds with new transaction
```

---

## 📱 Screen Wireframes

### Home Screen

```
[Header: Welcome | Profile]
┌─────────────────┐
│  Total Balance  │
│  4.7M сўм  +12% │
└─────────────────┘
Accounts (Carousel)
[🏠 Дом] [👨‍👩‍👧 Семья] [💼 Бизнес]
  Indicators
Quick Actions
[💰] [📈] [🎤] [📄]
Recent Transactions
[Transaction 1]
[Transaction 2]
[Transaction 3]
[Bottom Nav]
```

### Analytics Screen

```
[Header: Analytics]
Period Filter: [This Month ▼]
┌─────────────────────────┐
│    Pie Chart            │
│   Categories            │
│                         │
│ 🛒 40%  🚕 25% 🎬 15%  │
│ 💡 20%                  │
└─────────────────────────┘
Line Chart (Balance Trend)
[Trend chart...]
[Export PDF] [Export CSV]
[Bottom Nav]
```

---

## 🎬 Animations & Interactions

### Page Transitions

```
Push (Add Transaction):
  Source screen slides left
  New screen slides in from right
  Duration: 300ms
  Curve: easeInOut

Pop (Close):
  New screen slides out right
  Source screen stays visible
  Duration: 200ms
  Curve: easeOut
```

### Element Animations

```
Button Press:
  - Scale: 0.95 (tap down)
  - Duration: 100ms
  - Release: back to 1.0

Account Carousel:
  - Swipe to slide
  - Page indicator smoothly updates
  - Selected card has border & shadow

Loading State:
  - Skeleton loaders (shimmer)
  - Circular progress indicator
  - Duration: indeterminate
```

---

## ♿ Accessibility

### Semantic HTML

```
AppBar Title:  semanticLabel="Application Home"
Buttons:       semanticLabel="Add new account"
Icons:         semanticLabel="Menu"
Images:        semanticLabel="Transaction Receipt"
Forms:         Label associated with input
```

### Color Contrast

```
Text on White:     #1F2937 (4.8:1) ✓ AA
Text on Primary:   #FFFFFF (11.5:1) ✓ AAA
Text on Secondary: #6B7280 (4.6:1) ✓ AA
Disabled text:     #9CA3AF (3.8:1) ✓ AA
```

### Font Sizing

```
Minimum: 12px (labels)
Body: 14-16px
Headings: 18-32px
Line height: 1.4-1.6
Touch target: 48x48dp minimum
```

---

## 📐 Responsive Design

### Breakpoints

```
XSmall:  < 360px  (old phones)
Small:   360-600px (iPhone SE, small Android)
Medium:  600-900px (Tablets, large phones)
Large:   > 900px  (Large tablets, foldables)
```

### Adaptations

```
Small Screens (< 600px):
- Single column layouts
- Horizontal scroll for carousels
- Larger touch targets (64px)
- Bottom sheet for modals

Medium Screens (600-900px):
- 2-column layouts
- Vertical scroll
- Normal touch targets (48px)

Large Screens (> 900px):
- Multi-column layouts
- Side navigation possible
- Desktop navigation bar
```

---

## 🎯 Soft UI Animation Example

```dart
// Hover/Press effect on card
container.onHover = (isHover) {
  setState(() {
    if (isHover) {
      // Increase shadow
      boxShadow = AppSizes.shadowMedium;
      // Slightly scale up
      transform = Matrix4.identity()..scale(1.02);
    } else {
      // Back to soft shadow
      boxShadow = AppSizes.shadowSoft;
      transform = Matrix4.identity();
    }
  });
};

// Animate with duration
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  boxShadow: [boxShadow],
  transform: transform,
  child: ...,
);
```

---

## Заключение

Эта визуальная архитектура обеспечивает:
- Консистентный Soft UI дизайн
- Легкую адаптивность к разным экранам
- Хорошую доступность (a11y)
- Гладкие анимации и переходы
- Минималистичный, премиальный вид
