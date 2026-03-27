# FinanceFlow - Примеры кода и использования

Этот документ содержит практические примеры для реализации основных функций приложения.

---

## 1. Использование Riverpod Providers

### Простой Provider (вычисляемое состояние)

```dart
// lib/presentation/providers/account_provider.dart

import 'package:riverpod/riverpod.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

// Repository Provider (синглтон)
final accountRepositoryProvider = Provider((ref) {
  return AccountRepositoryImpl(
    ref.watch(firebaseProvider),
    ref.watch(hiveProvider),
  );
});

// Fetch всех счетов
final accountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAccounts();
});

// Общий баланс (вычисляется автоматически)
final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) => accounts.fold(0.0, (sum, acc) => sum + acc.balance),
    orElse: () => 0.0,
  );
});

// Выбранный счет (StateNotifier)
final selectedAccountProvider = StateNotifierProvider<SelectedAccountNotifier, String?>((ref) {
  return SelectedAccountNotifier();
});

class SelectedAccountNotifier extends StateNotifier<String?> {
  SelectedAccountNotifier() : super(null);

  void selectAccount(String accountId) => state = accountId;
  void clearSelection() => state = null;
}

// Транзакции для выбранного счета
final selectedAccountTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final selectedId = ref.watch(selectedAccountProvider);
  if (selectedId == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactionsByAccountId(selectedId);
});
```

### Использование в UI

```dart
// lib/presentation/screens/home_screen.dart

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Следим за состоянием
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return Scaffold(
      body: accountsAsync.when(
        // Данные успешно загружены
        data: (accounts) => Column(
          children: [
            // Карточка с общим балансом
            BalanceCard(balance: totalBalance),

            // Список счетов
            ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return AccountCard(
                  account: account,
                  onTap: () {
                    // Выбираем счет
                    ref.read(selectedAccountProvider.notifier)
                        .selectAccount(account.id);
                  },
                );
              },
            ),
          ],
        ),

        // Данные загружаются
        loading: () => Center(
          child: CircularProgressIndicator(),
        ),

        // Ошибка загрузки
        error: (error, stack) => Center(
          child: Text('Ошибка: ${error.toString()}'),
        ),
      ),
    );
  }
}
```

---

## 2. Добавление новой транзакции

### Repository слой

```dart
// lib/data/repositories/transaction_repository_impl.dart

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _remoteDataSource;
  final TransactionLocalDataSource _localDataSource;

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      // 1. Сохраняем локально для мгновенного обновления UI
      await _localDataSource.saveTransaction(transaction);

      // 2. Отправляем на Firestore
      await _remoteDataSource.createTransaction(transaction);

      // 3. Удаляем из очереди синхронизации
      await _localDataSource.removeFromSyncQueue(transaction.id);
    } catch (e) {
      // При ошибке добавляем в очередь для отложенной синхронизации
      await _localDataSource.addToSyncQueue(transaction);
      rethrow;
    }
  }
}
```

### Provider для создания транзакции

```dart
// lib/presentation/providers/transaction_provider.dart

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepositoryImpl(
    ref.watch(firebaseProvider),
    ref.watch(hiveProvider),
  );
});

// StateNotifier для управления списком транзакций
final transactionsNotifierProvider = StateNotifierProvider<
    TransactionsNotifier,
    AsyncValue<List<TransactionModel>>
>((ref) {
  return TransactionsNotifier(
    ref.watch(transactionRepositoryProvider),
  );
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _repository.getTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Добавить новую транзакцию
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _repository.addTransaction(transaction);
      
      // Обновляем список
      final current = state.maybeWhen(
        data: (data) => data,
        orElse: () => <TransactionModel>[],
      );
      
      state = AsyncValue.data([transaction, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
```

### Использование в экране добавления операции

```dart
// lib/presentation/screens/add_transaction_screen.dart

class AddTransactionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    var description = '';
    var amount = 0.0;
    var categoryId = 'cat_food';

    return Scaffold(
      appBar: AppBar(title: Text('Новая операция')),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            // Поле описания
            TextFormField(
              decoration: InputDecoration(labelText: 'Описание'),
              validator: (value) => value?.isEmpty ?? true ? 'Обязательно' : null,
              onSaved: (value) => description = value ?? '',
            ),

            // Поле суммы
            TextFormField(
              decoration: InputDecoration(labelText: 'Сумма'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Обязательно';
                if (double.tryParse(value!) == null) return 'Некорректная сумма';
                return null;
              },
              onSaved: (value) => amount = double.parse(value ?? '0'),
            ),

            // Кнопка добавления
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                formKey.currentState!.save();

                // Создаем транзакцию
                final transaction = TransactionModel(
                  id: const Uuid().v4(),
                  accountId: 'current_account_id',
                  userId: 'current_user_id',
                  amount: -amount, // Отрицательно для расходов
                  currency: 'UZS',
                  categoryId: categoryId,
                  description: description,
                  type: 'expense',
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  // Добавляем через provider
                  await ref
                      .read(transactionsNotifierProvider.notifier)
                      .addTransaction(transaction);

                  // Закрываем экран
                  Navigator.of(context).pop();

                  // Показываем уведомление об успехе
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Операция добавлена!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. Голосовой ввод

### Speech-to-Text интеграция

```dart
// lib/presentation/services/voice_service.dart

import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> initialize() async {
    await _speech.initialize(
      onError: (error) => print('Error: $error'),
      onStatus: (status) => print('Status: $status'),
    );
  }

  Future<String?> startListening() async {
    if (!_speech.isAvailable) {
      return null;
    }

    String recognizedText = '';

    _speech.listen(
      localeId: 'ru_RU',
      onResult: (result) {
        recognizedText = result.recognizedWords;
        print('Recognized: $recognizedText');
      },
    );

    return recognizedText;
  }

  void stopListening() {
    _speech.stop();
  }
}

// NLP парсинг голосовой команды
class VoiceCommandParser {
  /// Парсит фразу: "Расход 50 000 сум на продукты со счета Дом"
  static VoiceCommand? parse(String text) {
    final regex = RegExp(
      r'(расход|доход|трансфер)\s+([\d\s]+)\s+(\w+)?\s+(?:на|со счета)?(.+)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match == null) return null;

    final type = match.group(1)?.toLowerCase(); // расход, доход, трансфер
    final amountStr = match.group(2)?.replaceAll(' ', ''); // 50000
    final currency = match.group(3) ?? 'UZS'; // сум, dollar
    final description = match.group(4)?.trim(); // продукты

    final amount = double.tryParse(amountStr ?? '0') ?? 0;

    return VoiceCommand(
      type: type == 'расход' ? 'expense' : 'income',
      amount: amount,
      currency: currency,
      description: description,
    );
  }
}

class VoiceCommand {
  final String type;
  final double amount;
  final String currency;
  final String? description;

  VoiceCommand({
    required this.type,
    required this.amount,
    required this.currency,
    this.description,
  });
}
```

### Voice Input Screen

```dart
// lib/presentation/screens/voice_input_screen.dart

class VoiceInputScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  late VoiceService _voiceService;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _voiceService.initialize();
  }

  void _startListening() async {
    setState(() => _isListening = true);

    final text = await _voiceService.startListening();
    if (text != null) {
      setState(() => _recognizedText = text);

      // Парсим команду
      final command = VoiceCommandParser.parse(text);
      if (command != null) {
        _processCommand(command);
      }
    }

    setState(() => _isListening = false);
  }

  void _processCommand(VoiceCommand command) {
    // Создаем транзакцию из распознанной команды
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      accountId: 'current_account',
      userId: 'current_user',
      amount: command.type == 'expense' ? -command.amount : command.amount,
      currency: command.currency,
      categoryId: 'cat_other',
      description: command.description ?? '',
      type: command.type,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Добавляем транзакцию
    ref.read(transactionsNotifierProvider.notifier).addTransaction(transaction);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Голосовой ввод')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Микрофон
            GestureDetector(
              onTap: _startListening,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 20),

            if (_isListening)
              Text('Слушаю...', style: Theme.of(context).textTheme.headlineSmall)
            else
              Text('Нажмите на микрофон', style: Theme.of(context).textTheme.bodyMedium),

            SizedBox(height: 20),

            // Распознанный текст
            if (_recognizedText.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_recognizedText),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    super.dispose();
  }
}
```

---

## 4. OCR для чеков

### Scan Receipt Service

```dart
// lib/presentation/services/receipt_scanner_service.dart

import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ReceiptScannerService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<Receipt?> scanReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Парсим текст
      final text = recognizedText.text;

      // Ищем сумму (регулярное выражение)
      final amountRegex = RegExp(r'(\d+[\.,]\d{2}|\d+)');
      final amountMatch = amountRegex.firstMatch(text);

      // Ищем дату
      final dateRegex = RegExp(r'(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})');
      final dateMatch = dateRegex.firstMatch(text);

      return Receipt(
        amount: double.tryParse(
          amountMatch?.group(1)?.replaceAll(',', '.') ?? '0',
        ) ?? 0,
        date: dateMatch != null ? _parseDate(dateMatch.group(1)!) : DateTime.now(),
        rawText: text,
      );
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr.replaceAll(RegExp(r'[/\-\.]'), '-'));
    } catch (e) {
      return DateTime.now();
    }
  }
}

class Receipt {
  final double amount;
  final DateTime date;
  final String rawText;

  Receipt({
    required this.amount,
    required this.date,
    required this.rawText,
  });
}
```

### Camera Screen для сканирования

```dart
// lib/presentation/screens/camera_screen.dart

class CameraScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    await _cameraController.initialize();
    setState(() {});
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _cameraController.takePicture();

      // Сканируем чек
      final scanner = ReceiptScannerService();
      final receipt = await scanner.scanReceipt(image.path);

      if (receipt != null) {
        // Создаем транзакцию
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          accountId: 'current_account',
          userId: 'current_user',
          amount: -receipt.amount,
          currency: 'UZS',
          categoryId: 'cat_food',
          description: receipt.rawText,
          type: 'expense',
          date: receipt.date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          receiptUrl: image.path,
        );

        // Добавляем
        await ref
            .read(transactionsNotifierProvider.notifier)
            .addTransaction(transaction);

        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePhoto,
                child: Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
```

---

## 5. Конвертер валют

### Currency Service

```dart
// lib/presentation/services/currency_service.dart

class CurrencyService {
  static const Map<String, double> exchangeRates = {
    'UZS_USD': 0.000082, // 1 UZS = 0.000082 USD
    'UZS_RUB': 0.0093,   // 1 UZS = 0.0093 RUB
    'USD_UZS': 12195,    // 1 USD = 12195 UZS
    'USD_RUB': 113,      // 1 USD = 113 RUB
    'RUB_UZS': 107,      // 1 RUB = 107 UZS
    'RUB_USD': 0.0089,   // 1 RUB = 0.0089 USD
  };

  /// Конвертирует сумму из одной валюты в другую
  static double convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (fromCurrency == toCurrency) return amount;

    final key = '${fromCurrency}_$toCurrency';
    final rate = exchangeRates[key];

    if (rate == null) {
      throw Exception('Exchange rate not found: $key');
    }

    return amount * rate;
  }

  /// Получает все конвертации для суммы
  static Map<String, double> convertAll(
    double amount,
    String fromCurrency,
  ) {
    return {
      'UZS': convert(amount, fromCurrency, 'UZS'),
      'USD': convert(amount, fromCurrency, 'USD'),
      'RUB': convert(amount, fromCurrency, 'RUB'),
    };
  }
}

// Использование
final convertedAmountsProvider = Provider<Map<String, double>>((ref) {
  final selected = ref.watch(selectedAmountProvider);
  final currency = ref.watch(selectedCurrencyProvider);

  return CurrencyService.convertAll(selected, currency);
});
```

---

## 6. Интерактивные графики

### Pie Chart для категорий

```dart
// lib/presentation/widgets/category_pie_chart.dart

import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(selectedAccountTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Группируем по категориям
        final categoryTotals = <String, double>{};

        for (final tx in transactions) {
          if (tx.type == 'expense') {
            categoryTotals[tx.categoryId] =
                (categoryTotals[tx.categoryId] ?? 0) + tx.amount.abs();
          }
        }

        // Создаем pie sections
        final sections = categoryTotals.entries.map((e) {
          final color = TransactionItem.categoryColors[e.key] ??
              AppColors.categoryOther;

          return PieChartSectionData(
            value: e.value,
            title: CurrencyFormatter.formatCompact(e.value, 'UZS'),
            radius: 60,
            color: color,
          );
        }).toList();

        return PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }
}
```

### Line Chart для трендов

```dart
// lib/presentation/widgets/balance_line_chart.dart

import 'package:fl_chart/fl_chart.dart';

class BalanceLineChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(selectedAccountTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        // Группируем по дням и вычисляем баланс
        final dailyBalances = <DateTime, double>{};

        for (final tx in transactions.where((t) => t.type != 'transfer')) {
          final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
          dailyBalances[date] = (dailyBalances[date] ?? 0) + tx.amount;
        }

        // Сортируем по дате
        final sortedDates = dailyBalances.keys.toList()..sort();

        // Создаем spots для графика
        var cumulativeBalance = 0.0;
        final spots = sortedDates.asMap().entries.map((e) {
          cumulativeBalance += dailyBalances[e.value] ?? 0;
          return FlSpot(e.key.toDouble(), cumulativeBalance);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: true),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primaryAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primaryAccent,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primaryAccent.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  }
}
```

---

## Заключение

Эти примеры демонстрируют основные паттерны и функции приложения FinanceFlow. Для дополнительной информации смотрите:

- **ARCHITECTURE.md** - Детальная архитектура приложения
- **DATABASE_SCHEMA.md** - Структура базы данных
- **Официальная документация**:
  - [Riverpod docs](https://riverpod.dev)
  - [Flutter docs](https://flutter.dev)
  - [Firebase docs](https://firebase.google.com/docs)
