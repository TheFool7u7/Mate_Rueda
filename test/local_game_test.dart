import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/features/challenge/presentation/screens/math_challenge_screen.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/local_game/presentation/screens/local_results_screen.dart';
import 'package:wordwonderslink/main_demo.dart';

/// Busca un widget Semantics por su etiqueta (no requiere activar la
/// accesibilidad en el test).
Finder sem(String label) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.label == label)
    .first;

/// La navegación de go_router necesita dos frames para montar la página.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('LocalGameController', () {
    test('rota turnos, suma estrellas y termina en resultados', () {
      final g = LocalGameController(random: Random(1));
      g.configure(teamCount: 3, totalRounds: 5);
      expect(g.teams.length, 3);

      g.start();
      expect(g.phase, LocalPhase.spinning);
      expect(g.round, 1);
      expect(g.currentTeamIndex, 0);

      final seenTeams = <int>[];
      var more = true;
      while (more) {
        seenTeams.add(g.currentTeamIndex);
        g.drawCategoryIndex();
        g.onSpinFinished();
        expect(g.phase, LocalPhase.challenge);
        final c = g.challenge!;
        // La mesa 1 siempre acierta; las demás siempre fallan.
        final idx = g.currentTeamIndex == 0
            ? c.correctIndex
            : (c.correctIndex + 1) % c.options.length;
        expect(g.answer(idx), g.currentTeamIndex == 0);
        expect(g.phase, LocalPhase.feedback);
        more = g.next();
      }

      expect(seenTeams, [0, 1, 2, 0, 1]);
      expect(g.phase, LocalPhase.results);
      expect(g.teams[0].stars, 2);
      expect(g.teams[1].stars, 0);
      expect(g.totalStars, 2);
      expect(g.ranking.first, g.teams[0]);
    });

    test('restart reinicia estrellas y reset limpia la partida', () {
      final g = LocalGameController(random: Random(2));
      g.configure(teamCount: 2, totalRounds: 5);
      g.start();
      g.drawCategoryIndex();
      g.onSpinFinished();
      g.answer(g.challenge!.correctIndex);
      expect(g.totalStars, 1);

      g.restart();
      expect(g.totalStars, 0);
      expect(g.round, 1);

      g.reset();
      expect(g.teams, isEmpty);
    });

    test('limita mesas entre 1 y 6', () {
      final g = LocalGameController();
      g.configure(teamCount: 99);
      expect(g.teamCount, LocalGameController.maxTeams);
      g.configure(teamCount: 0);
      expect(g.teamCount, LocalGameController.minTeams);
    });
  });

  testWidgets('flujo completo: splash → menú → ... → resultados', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1536);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MateRuedaDemoApp(splashDuration: Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    // Menú
    expect(find.text('¡Hola, profe! ¿Listos?'), findsWidgets);
    await tester.tap(sem('Jugar'));
    await settle(tester);

    // Crear partida: 2 mesas, 5 rondas
    expect(find.text('Crear partida'), findsWidgets);
    await tester.tap(sem('Menos mesas'));
    await tester.pump();
    await tester.tap(sem('Crear sala'));
    await settle(tester);

    // Sala de espera
    expect(find.text('Sala de espera'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.tap(sem('Iniciar partida'));
    await settle(tester);

    final ctx = tester.element(find.byType(Scaffold).first);
    final game = ctx.read<LocalGameController>();
    expect(game.teams.length, 2);

    // 5 rondas completas.
    for (var round = 1; round <= 5; round++) {
      expect(find.textContaining('Ronda $round de 5'), findsWidgets);
      await tester.tap(sem('¡Girar!'));
      await tester.pump(const Duration(milliseconds: 100)); // arranca el ticker
      await tester.pump(const Duration(milliseconds: 4000)); // giro
      await tester.pump(const Duration(milliseconds: 2000)); // categoría
      await settle(tester);

      expect(find.byType(MathChallengeScreen), findsOneWidget);
      final c = game.challenge!;
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.tap(
        sem(c.options[c.correctIndex].label).first,
      );
      await tester.pump(const Duration(milliseconds: 1500));
      await settle(tester);

      // Retroalimentación positiva
      expect(find.text('¡Muy bien!'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.tap(
        sem(round == 5 ? 'Ver resultados' : 'Siguiente'),
      );
      await settle(tester);
    }

    expect(find.byType(LocalResultsScreen), findsOneWidget);
    expect(game.totalStars, 5);
    expect(find.text('¡Buen trabajo, equipo!'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1600));

    await tester.tap(sem('Volver al menú'));
    await settle(tester);
    expect(find.text('¡Hola, profe! ¿Listos?'), findsWidgets);
  });
}
