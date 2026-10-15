import 'package:flutter_test/flutter_test.dart';
import 'package:wordwonderslink/main.dart';

void main() {
  testWidgets('App se inicializa correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const WordWondersApp());
    // Verificar que la app arranca sin errores
    expect(find.byType(WordWondersApp), findsOneWidget);
  });
}
