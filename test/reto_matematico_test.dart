import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_screen.dart';
import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_demo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MathChallengeScreen muestra el reto de 10_reto_matematico', (
    tester,
  ) async {
    // Configurar pantalla simulando dimensiones de teléfono vertical (1024x1536 aspecto)
    tester.view.physicalSize = const Size(1024, 1536);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int? answeredIndex;
    bool? wasCorrect;

    await tester.pumpWidget(
      MaterialApp(
        home: MathChallengeScreen(
          challenge: MathChallengeGenerator.mockup,
          progress: 0.5,
          onAnswered: (idx, ok) {
            answeredIndex = idx;
            wasCorrect = ok;
          },
        ),
      ),
    );

    // Esperar animaciones de entrada (no pumpAndSettle porque Numi tiene _float repetitivo)
    await tester.pump(const Duration(milliseconds: 1000));

    // Verificar textos del mockup 10_reto_matematico
    expect(find.text('Conteo y números'), findsOneWidget);
    expect(find.text('¿Cuántas manzanas hay?'), findsWidgets);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    // Tocar la opción correcta '5'
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(answeredIndex, equals(1));
    expect(wasCorrect, isTrue);
  });

  testWidgets('MathChallengeDemoScreen rota retos al responder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1536);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: MathChallengeDemoScreen()),
    );

    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Conteo y números'), findsOneWidget);

    // Tocar opción '5'
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(milliseconds: 200));

    // Esperar el retardo de 1400ms para el siguiente reto
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));

    // El generador habrá cargado un nuevo reto
    expect(find.byType(MathChallengeScreen), findsOneWidget);
  });
}
