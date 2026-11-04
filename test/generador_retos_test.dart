import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';

/// Valor numérico de la respuesta correcta de un reto numérico.
int _answer(MathChallenge c) => int.parse(c.options[c.correctIndex].label);

void main() {
  group('Comparación (OA2)', () {
    test('ofrece 3 opciones y cubre mayor, menor e igual', () {
      final gen = MathChallengeGenerator(Random(3));
      var equals = 0;
      for (var i = 0; i < 300; i++) {
        final c = gen.generate(MathCategory.comparacion);
        expect(c.options.map((o) => o.label), ['◀', '=', '▶']);
        final label = c.options[c.correctIndex].label;
        final more = c.question == '¿Dónde hay más?';
        if (c.countA == c.countB) {
          equals++;
          expect(label, '=');
        } else if (more) {
          expect(label, c.countA > c.countB ? '◀' : '▶');
        } else {
          expect(label, c.countA < c.countB ? '◀' : '▶');
        }
      }
      expect(equals, greaterThan(0));
    });
  });

  group('Rangos configurables', () {
    for (final entry in {
      'básico': ChallengeSettings.basico,
      'ampliado': ChallengeSettings.ampliado,
    }.entries) {
      test('respeta el nivel ${entry.key}', () {
        final s = entry.value;
        final gen = MathChallengeGenerator(Random(11), s);
        for (var i = 0; i < 300; i++) {
          final conteo = gen.generate(MathCategory.conteo);
          expect(conteo.countA, inInclusiveRange(2, s.countMax));
          expect(_answer(conteo), conteo.countA);

          final suma = gen.generate(MathCategory.sumas);
          expect(suma.countA + suma.countB, lessThanOrEqualTo(s.sumMax));
          expect(_answer(suma), suma.countA + suma.countB);

          final resta = gen.generate(MathCategory.restas);
          expect(resta.countA, lessThanOrEqualTo(s.subMax));
          expect(resta.countB, lessThan(resta.countA));
          expect(_answer(resta), resta.countA - resta.countB);

          final comp = gen.generate(MathCategory.comparacion);
          expect(comp.countA, inInclusiveRange(1, s.compareMax));
          expect(comp.countB, inInclusiveRange(1, s.compareMax));
        }
      });
    }

    test('las 3 opciones numéricas son distintas y no negativas', () {
      final gen = MathChallengeGenerator(Random(5), ChallengeSettings.ampliado);
      for (var i = 0; i < 300; i++) {
        final c = gen.random();
        if (c.category == MathCategory.figuras ||
            c.category == MathCategory.comparacion) {
          continue;
        }
        final values = c.options.map((o) => int.parse(o.label)).toList();
        expect(values.toSet().length, 3);
        expect(values.every((v) => v >= 0), isTrue);
      }
    });
  });
}
