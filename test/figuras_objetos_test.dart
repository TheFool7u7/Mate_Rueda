import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/challenge/presentation/widgets/challenge_illustrations.dart';

void main() {
  test('cada figura tiene su objeto del hogar', () {
    expect(ShapeKind.circulo.objectName, 'reloj de pared');
    expect(ShapeKind.cuadrado.objectName, 'ventana');
    expect(ShapeKind.triangulo.objectName, 'pedazo de pizza');
    expect(ShapeKind.rectangulo.objectName, 'celular');
  });

  test('retos de figuras: alternan variantes y la respuesta es correcta', () {
    final gen = MathChallengeGenerator(Random(7));
    var objectToShape = 0;
    var shapeToObject = 0;

    for (var i = 0; i < 200; i++) {
      final c = gen.generate(MathCategory.figuras);
      expect(c.options.length, 3);
      expect(c.correctIndex, inInclusiveRange(0, 2));
      // Opciones sin repetir.
      expect(c.options.map((o) => o.shape).toSet().length, 3);
      // La opción correcta corresponde a la figura objetivo.
      expect(c.options[c.correctIndex].shape, c.shape);

      if (c.shapeAsObject) {
        objectToShape++;
        expect(c.options.every((o) => !o.asObject), isTrue);
        expect(c.question, contains(c.shape!.objectName));
      } else {
        shapeToObject++;
        expect(c.options.every((o) => o.asObject), isTrue);
        expect(c.question, contains(c.shape!.label));
      }
    }
    expect(objectToShape, greaterThan(0));
    expect(shapeToObject, greaterThan(0));
  });

  testWidgets('HouseholdObjectIcon dibuja los 4 objetos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final s in ShapeKind.values)
              HouseholdObjectIcon(shape: s, size: 80),
          ],
        ),
      ),
    );
    expect(find.byType(HouseholdObjectIcon), findsNWidgets(4));
  });
}
