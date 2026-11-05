// Кав’ярня «Зерно»: звіт про продажі за зміну.
// Програма працює правильно, але написана в імперативному стилі.

typedef Sale = ({
  String item,
  String kind,
  int price,
  int quantity,
  bool isTakeaway,
});

const sales = <Sale>[
  (item: 'Лате', kind: 'кава', price: 65, quantity: 2, isTakeaway: true),
  (item: 'Капучино', kind: 'кава', price: 60, quantity: 3, isTakeaway: false),
  (item: 'Матча', kind: 'чай', price: 75, quantity: 1, isTakeaway: false),
  (item: 'Чизкейк', kind: 'десерт', price: 95, quantity: 2, isTakeaway: true),
  (item: 'Еспресо', kind: 'кава', price: 40, quantity: 1, isTakeaway: true),
  (item: 'Сирник', kind: 'десерт', price: 70, quantity: 3, isTakeaway: false),
];

final settings = (minTotal: 150, kind: 'кава');

int revenue(List<Sale> sales) {
  return sales.fold(0, (sum, sale) => sum + sale.price * sale.quantity);
}

List<String> itemsOf(List<Sale> sales, String kind) {
  return sales
      .where((sale) => sale.kind == kind)
      .map((sale) => sale.item)
      .toList();
}

int countLarge(List<Sale> sales, int minTotal) {
  return sales.where((sale) => sale.price * sale.quantity >= minTotal).length;
}

Map<String, int> revenueByKind(List<Sale> sales) {
  return sales.fold<Map<String, int>>({}, (totals, sale) {
    totals[sale.kind] = (totals[sale.kind] ?? 0) + sale.price * sale.quantity;
    return totals;
  });
}

String formatAmount(int amount) => '$amount грн';

String describe(Sale sale, {bool withKind = false, bool upperCase = false}) {
  var text = '${sale.item} × ${sale.quantity}';

  if (withKind) {
    text += ' (${sale.kind})';
  }

  return upperCase ? text.toUpperCase() : text;
}

void printReport(List<Sale> sales, {bool onlyTakeaway = false}) {
  final selected = <Sale>[];

  for (final sale in sales) {
    if (!onlyTakeaway || sale.isTakeaway) {
      selected.add(sale);
    }
  }

  final lines = selected
      .map((sale) => describe(sale, withKind: true, upperCase: false))
      .toList();

  lines.forEach(print);
}

void main() {
  print('Виручка: ${formatAmount(revenue(sales))}');
  print('Кава: ${itemsOf(sales, settings.kind)}');
  print(
    'Великих чеків: '
    '${countLarge(sales, settings.minTotal)}',
  );

  final amounts = sales.map((sale) => sale.price * sale.quantity).toList();

  final formatted = amounts.map(formatAmount).join(', ');

  print('Чеки: $formatted');

  revenueByKind(sales).forEach((kind, sum) {
    print(' $kind: ${formatAmount(sum)}');
  });

  printReport(sales, onlyTakeaway: true);
}
