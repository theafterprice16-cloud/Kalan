import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/core/engine/split.dart';

void main() {
  group('splitEvenly puts leftover minor units on the first payment', () {
    final cases = <(int, int, List<int>)>[
      (10000, 4, [2500, 2500, 2500, 2500]),
      (10000, 3, [3334, 3333, 3333]),
      (100, 3, [34, 33, 33]),
      (1, 1, [1]),
      (5, 4, [2, 1, 1, 1]),
      (
        325000,
        12,
        [
          27087,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
          27083,
        ],
      ),
      (0, 2, [0, 0]),
    ];
    for (final (total, parts, expected) in cases) {
      test('$total / $parts', () {
        final result = splitEvenly(total, parts);
        expect(result, expected);
        expect(result.fold<int>(0, (a, b) => a + b), total);
      });
    }
  });

  test('sum always equals total', () {
    for (var total = 0; total < 500; total += 7) {
      for (var parts = 1; parts <= 13; parts++) {
        final r = splitEvenly(total, parts);
        expect(r.fold<int>(0, (a, b) => a + b), total);
        expect(r.length, parts);
      }
    }
  });

  test('rejects invalid input', () {
    expect(() => splitEvenly(100, 0), throwsArgumentError);
    expect(() => splitEvenly(-1, 2), throwsArgumentError);
  });
}
