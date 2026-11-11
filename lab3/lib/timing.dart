/// Порівняння послідовного й одночасного виконання асинхронних операцій.
library;

import 'async_repository.dart';
import 'lesson.dart';

/// Час послідовного й одночасного завантаження занять за [ids].
typedef TimingResult = ({Duration sequential, Duration parallel});

/// Завантажує [ids] спершу по одному (`await` у циклі), потім разом
/// (`Future.wait`) і вимірює обидва часи через [Stopwatch].
Future<TimingResult> compareTiming(
  AsyncRepository<Lesson> repo,
  List<String> ids,
) async {
  final sequential = Stopwatch()..start();
  for (final id in ids) {
    await repo.load(id);
  }
  sequential.stop();

  final parallel = Stopwatch()..start();
  await Future.wait([for (final id in ids) repo.load(id)]);
  parallel.stop();

  return (sequential: sequential.elapsed, parallel: parallel.elapsed);
}
