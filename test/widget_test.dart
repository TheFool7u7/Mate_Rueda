import 'package:flutter_test/flutter_test.dart';
import 'package:wordwonderslink/main.dart';

void main() {
  testWidgets('App se inicializa correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const WordWondersApp(splashDuration: Duration(milliseconds: 100)),
    );
    expect(find.byType(WordWondersApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
