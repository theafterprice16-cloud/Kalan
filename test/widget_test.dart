import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const KalanApp());
    expect(find.byType(KalanApp), findsOneWidget);
  });
}
