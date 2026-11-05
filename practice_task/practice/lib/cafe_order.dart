/// Перелік можливих станів замовлення.
enum OrderStatus {
  /// Замовлення прийняте, але ще не передане на кухню.
  newOrder,

  /// Замовлення готується.
  preparing,

  /// Замовлення видане клієнту.
  issued,
}

/// Описує пункт меню з його назвою та ціною.
class MenuItem implements Comparable<MenuItem> {
  /// Назва пункту меню.
  final String name;

  /// Ціна пункту меню в копійках.
  final int priceKopecks;

  /// Створює пункт меню з [name] та [priceKopecks].
  ///
  /// Кидає [ArgumentError], якщо назва порожня або ціна не є додатною.
  MenuItem({required String name, required int priceKopecks})
    : name = _validateName(name),
      priceKopecks = _validatePrice(priceKopecks);

  @override
  int compareTo(MenuItem other) {
    return priceKopecks.compareTo(other.priceKopecks);
  }

  static String _validateName(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'name',
        'Назва пункту меню не може бути порожньою.',
      );
    }

    return value;
  }

  static int _validatePrice(int value) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'priceKopecks',
        'Ціна повинна бути додатною.',
      );
    }

    return value;
  }
}

/// Представляє пункт меню та його кількість у замовленні.
class OrderItem implements Comparable<OrderItem> {
  /// Пункт меню, що входить до замовлення.
  final MenuItem item;

  /// Кількість одиниць пункту в замовленні.
  final int quantity;

  /// Створює позицію замовлення з [item] та [quantity].
  ///
  /// Кидає [RangeError], якщо [quantity] не входить у межі від 1 до 20.
  OrderItem({required this.item, required int quantity})
    : quantity = _validateQuantity(quantity);

  @override
  int compareTo(OrderItem other) {
    return item.priceKopecks.compareTo(other.item.priceKopecks);
  }

  static int _validateQuantity(int value) {
    if (value < 1 || value > 20) {
      throw RangeError.value(
        value,
        'quantity',
        'Кількість має бути від 1 до 20.',
      );
    }

    return value;
  }
}

/// Зберігає інформацію про зміну стану та час цієї зміни.
class StateChange {
  /// Назва нового стану.
  final String state;

  /// Час переходу до нового стану.
  final DateTime timestamp;

  /// Створює запис про зміну стану.
  const StateChange({required this.state, required this.timestamp});
}

/// Додає можливість вести журнал змін стану об'єкта.
mixin StateChangeJournal {
  final List<StateChange> _stateChanges = [];

  /// Повертає журнал змін стану без можливості змінити його ззовні.
  Iterable<StateChange> get stateChanges => List.unmodifiable(_stateChanges);

  void _recordStateChange(String state) {
    _stateChanges.add(StateChange(state: state, timestamp: DateTime.now()));
  }
}

/// Представляє замовлення в кав'ярні та керує його станом і позиціями.
class CafeOrder with StateChangeJournal {
  final int _number;
  final bool _hasLoyaltyCard;
  final List<OrderItem> _items = [];

  OrderStatus _status = OrderStatus.newOrder;

  /// Створює нове замовлення з номером [number].
  ///
  /// [_hasLoyaltyCard] визначає, чи застосовується знижка 5 відсотків.
  ///
  /// Кидає [ArgumentError], якщо [number] не є додатним.
  CafeOrder(int number, {this._hasLoyaltyCard = false}) : _number = number {
    _validateNumber(number);
    _recordStateChange(_status.name);
  }

  /// Створює замовлення з активною карткою лояльності.
  CafeOrder.withLoyaltyCard(int number) : this(number, hasLoyaltyCard: true);

  /// Створює нове замовлення на основі [previous] з номером [newNumber].
  ///
  /// Позиції копіюються в нове замовлення, а його початковий стан є `newOrder`.
  ///
  /// Кидає [ArgumentError], якщо [newNumber] не є додатним або збігається
  /// з номером попереднього замовлення.
  factory CafeOrder.repeat(CafeOrder previous, int newNumber) {
    _validateNumber(newNumber);

    if (newNumber == previous.number) {
      throw ArgumentError.value(
        newNumber,
        'newNumber',
        'Повторене замовлення повинно мати новий номер.',
      );
    }

    final order = CafeOrder(newNumber, hasLoyaltyCard: previous.hasLoyaltyCard);

    order._items.addAll(
      previous._items.map(
        (orderItem) =>
            OrderItem(item: orderItem.item, quantity: orderItem.quantity),
      ),
    );

    return order;
  }

  /// Номер замовлення.
  int get number => _number;

  /// Чи має замовлення знижку за карткою лояльності.
  bool get hasLoyaltyCard => _hasLoyaltyCard;

  /// Поточний стан замовлення.
  OrderStatus get status => _status;

  /// Чи не містить замовлення жодної позиції.
  bool get isEmpty => _items.isEmpty;

  /// Загальна кількість одиниць у замовленні.
  int get totalQuantity {
    return _items.fold(0, (total, orderItem) => total + orderItem.quantity);
  }

  /// Загальна вартість позицій без знижки в копійках.
  int get subtotalKopecks {
    return _items.fold(
      0,
      (total, orderItem) =>
          total + orderItem.item.priceKopecks * orderItem.quantity,
    );
  }

  /// Загальна вартість замовлення зі знижкою в копійках.
  int get totalKopecks {
    if (!_hasLoyaltyCard) {
      return subtotalKopecks;
    }

    return subtotalKopecks * 95 ~/ 100;
  }

  /// Повертає перелік позицій без можливості змінити внутрішній список.
  Iterable<OrderItem> get items => List.unmodifiable(_items);

  /// Додає [quantity] одиниць пункту [item] до замовлення.
  ///
  /// Якщо пункт уже є в замовленні, його кількість збільшується.
  ///
  /// Кидає [StateError], якщо замовлення вже готується або видане.
  /// Кидає [RangeError], якщо нова кількість перевищує 20.
  void addItem(MenuItem item, {int quantity = 1}) {
    _ensureNewOrder();
    _validateMenuItem(item);
    _validateQuantity(quantity);

    final index = _items.indexWhere(
      (orderItem) =>
          orderItem.item.name == item.name &&
          orderItem.item.priceKopecks == item.priceKopecks,
    );

    if (index == -1) {
      _items.add(OrderItem(item: item, quantity: quantity));
      return;
    }

    final currentQuantity = _items[index].quantity;
    final newQuantity = currentQuantity + quantity;

    if (newQuantity > 20) {
      throw RangeError.value(
        newQuantity,
        'quantity',
        'Загальна кількість однієї позиції не може перевищувати 20.',
      );
    }

    _items[index] = OrderItem(item: item, quantity: newQuantity);
  }

  /// Прибирає [quantity] одиниць пункту [item] із замовлення.
  ///
  /// Якщо після видалення кількість стає нульовою, позиція вилучається.
  ///
  /// Кидає [StateError], якщо замовлення вже не є новим або такої позиції
  /// немає в замовленні.
  /// Кидає [RangeError], якщо [quantity] перевищує поточну кількість.
  void removeItem(MenuItem item, {int quantity = 1}) {
    _ensureNewOrder();
    _validateMenuItem(item);
    _validateQuantity(quantity);

    final index = _items.indexWhere(
      (orderItem) =>
          orderItem.item.name == item.name &&
          orderItem.item.priceKopecks == item.priceKopecks,
    );

    if (index == -1) {
      throw StateError('Позицію "${item.name}" не знайдено в замовленні.');
    }

    final currentQuantity = _items[index].quantity;

    if (quantity > currentQuantity) {
      throw RangeError.value(
        quantity,
        'quantity',
        'Неможливо прибрати більше одиниць, ніж є в замовленні.',
      );
    }

    if (quantity == currentQuantity) {
      _items.removeAt(index);
      return;
    }

    _items[index] = OrderItem(
      item: _items[index].item,
      quantity: currentQuantity - quantity,
    );
  }

  /// Передає непорожнє замовлення на кухню.
  ///
  /// Кидає [StateError], якщо замовлення вже не є новим або не містить позицій.
  void startPreparing() {
    if (_status != OrderStatus.newOrder) {
      throw StateError('Замовлення вже не перебуває у стані "нове".');
    }

    if (isEmpty) {
      throw StateError('Порожнє замовлення не можна передати на кухню.');
    }

    _status = OrderStatus.preparing;
    _recordStateChange(_status.name);
  }

  /// Завершує приготування замовлення та переводить його у виданий стан.
  ///
  /// Кидає [StateError], якщо замовлення ще не перебуває у стані приготування.
  void markIssued() {
    if (_status != OrderStatus.preparing) {
      throw StateError('Видати можна лише замовлення, яке готується.');
    }

    _status = OrderStatus.issued;
    _recordStateChange(_status.name);
  }

  void _ensureNewOrder() {
    if (_status != OrderStatus.newOrder) {
      throw StateError('Склад замовлення можна змінювати лише у стані "нове".');
    }
  }

  static void _validateNumber(int number) {
    if (number <= 0) {
      throw ArgumentError.value(
        number,
        'number',
        'Номер замовлення має бути додатним.',
      );
    }
  }

  static void _validateQuantity(int quantity) {
    if (quantity < 1 || quantity > 20) {
      throw RangeError.value(
        quantity,
        'quantity',
        'Кількість має бути від 1 до 20.',
      );
    }
  }

  static void _validateMenuItem(MenuItem item) {
    if (item.name.trim().isEmpty) {
      throw ArgumentError.value(
        item.name,
        'name',
        'Назва пункту меню не може бути порожньою.',
      );
    }

    if (item.priceKopecks <= 0) {
      throw ArgumentError.value(
        item.priceKopecks,
        'priceKopecks',
        'Ціна повинна бути додатною.',
      );
    }
  }
}

/// Представляє варіант замовлення на виніс із додатковою вартістю упаковки.
class TakeawayCafeOrder extends CafeOrder {
  /// Створює замовлення на виніс на основі [source].
  TakeawayCafeOrder.fromOrder(CafeOrder source)
    : super(source.number, hasLoyaltyCard: source.hasLoyaltyCard) {
    for (final orderItem in source.items) {
      addItem(orderItem.item, quantity: orderItem.quantity);
    }
  }

  @override
  int get totalKopecks => super.totalKopecks + 1000;
}

/// Додає форматування цілих значень у копійках у гривні.
extension UahFormatting on int {
  /// Повертає суму у форматі `125,50 грн`.
  String get formattedUah {
    final absoluteValue = abs();
    final hryvnias = absoluteValue ~/ 100;
    final kopecks = absoluteValue % 100;
    final sign = this < 0 ? '-' : '';

    return '$sign$hryvnias,${kopecks.toString().padLeft(2, '0')} грн';
  }
}
