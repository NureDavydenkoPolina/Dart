/// Важке синхронне обчислення та його винесення в ізолят.
library;

import 'dart:async';
import 'dart:isolate';

/// Лічильник, який демонструє, що ізолят має власну копію пам’яті.
int sharedCounter = 0;

bool _isPrime(int n) {
  if (n < 2) return false;
  if (n.isEven) return n == 2;
  for (var divisor = 3; divisor * divisor <= n; divisor += 2) {
    if (n % divisor == 0) return false;
  }
  return true;
}

/// Сума простих чисел, менших за [limit]. Навмисно важке обчислення.
int sumOfPrimesBelow(int limit) {
  var sum = 0;
  for (var n = 2; n < limit; n++) {
    if (_isPrime(n)) sum += n;
  }
  return sum;
}

/// Результат вимірювання: значення, час і кількість «тиків» таймера.
///
/// Таймер тікає кожні 50 мс. Якщо головний ізолят заблоковано, тиків немає.
typedef Measurement = ({int result, Duration elapsed, int ticks});

Future<Measurement> _measure(FutureOr<int> Function() work) async {
  var ticks = 0;
  final timer = Timer.periodic(
    const Duration(milliseconds: 50),
    (_) => ticks++,
  );
  final watch = Stopwatch()..start();
  final result = await work();
  watch.stop();
  final ticksDuring = ticks;
  timer.cancel();
  return (result: result, elapsed: watch.elapsed, ticks: ticksDuring);
}

/// Обчислює суму простих у головному ізоляті (блокує цикл подій).
Future<Measurement> measureOnMainIsolate(int limit) =>
    _measure(() => sumOfPrimesBelow(limit));

/// Обчислює суму простих в окремому ізоляті через [Isolate.run].
Future<Measurement> measureInIsolate(int limit) =>
    _measure(() => Isolate.run(() => sumOfPrimesBelow(limit)));

/// Змінює [sharedCounter] усередині ізолята й повертає значення всередині
/// та зовні.
Future<({int inside, int outside})> mutateGlobalInIsolate() async {
  final inside = await Isolate.run(() {
    sharedCounter++;
    return sharedCounter;
  });
  return (inside: inside, outside: sharedCounter);
}
