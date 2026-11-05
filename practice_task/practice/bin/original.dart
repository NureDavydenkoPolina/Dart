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
 
final Map<String, dynamic> settings = {'minTotal': 150, 'kind': 'кава'};
 
int revenue(List<Sale> sales) {
  var sum = 0;
  for (var sale in sales) {
    sum += sale.price * sale.quantity;
  }
  return sum;
}
 
List<String> itemsOf(List<Sale> sales, String kind) {
  var result = <String>[];
  for (var sale in sales) {
    if (sale.kind == kind) {
      result.add(sale.item);
    }
  }
  return result;
}
 
int countLarge(List<Sale> sales, int minTotal) {
  var count = 0;
  for (var sale in sales) {
    if (sale.price * sale.quantity >= minTotal) {
      count++;
    }
  }
  return count;
}
 
Map<String, int> revenueByKind(List<Sale> sales) {
  var totals = <String, int>{};
  for (var sale in sales) {
    totals[sale.kind] = (totals[sale.kind] ?? 0) + sale.price * sale.quantity;
  }
  return totals;
}
 
formatAmount(int amount) => '$amount грн';
 
String describe(Sale sale, bool withKind, bool upperCase) {
  var text = '${sale.item} × ${sale.quantity}';
  if (withKind) {
    text += ' (${sale.kind})';
  }
  return upperCase ? text.toUpperCase() : text;
}
 
void printReport(List<Sale> sales, bool onlyTakeaway) {
  var selected = <Sale>[];
  for (var sale in sales) {
    if (!onlyTakeaway || sale.isTakeaway) {
      selected.add(sale);
    }
  }
  var lines = selected.map((sale) => describe(sale, true, false)).toList();
  lines.forEach((line) => print(line));
}
 
void main() {
  print('Виручка: ${formatAmount(revenue(sales))}');
  print('Кава: ${itemsOf(sales, settings['kind'])}');
  print('Великих чеків: ${countLarge(sales, settings['minTotal'])}');
  var amounts = sales.map((sale) => sale.price * sale.quantity).toList();
  var formatted = amounts.map((a) => formatAmount(a)).join(', ');
  print('Чеки: $formatted');
  revenueByKind(sales).forEach((kind, sum) {
    print('  $kind: ${formatAmount(sum)}');
  });
  printReport(sales, true);
}

