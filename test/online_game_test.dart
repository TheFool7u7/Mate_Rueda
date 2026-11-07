import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wordwonderslink/features/challenge/domain/math_challenge.dart';
import 'package:wordwonderslink/features/local_game/domain/local_game_controller.dart';
import 'package:wordwonderslink/features/online_game/data/mate_room_backend.dart';
import 'package:wordwonderslink/main_demo.dart';

Finder _sem(String label) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.label == label)
    .first;

void main() {
  group('Serialización de MathChallenge', () {
    test('toJson / fromJson conserva todas las categorías y opciones', () {
      final gen = MathChallengeGenerator(Random(42), ChallengeSettings.ampliado);
      for (var i = 0; i < 60; i++) {
        final original = gen.random();
        final copy = MathChallenge.fromJson(original.toJson());
        expect(copy.category, original.category);
        expect(copy.question, original.question);
        expect(copy.visual, original.visual);
        expect(copy.correctIndex, original.correctIndex);
        expect(copy.object, original.object);
        expect(copy.countA, original.countA);
        expect(copy.countB, original.countB);
        expect(copy.shape, original.shape);
        expect(copy.shapeAsObject, original.shapeAsObject);
        expect(copy.options.length, original.options.length);
        for (var j = 0; j < copy.options.length; j++) {
          expect(copy.options[j].label, original.options[j].label);
          expect(copy.options[j].shape, original.options[j].shape);
          expect(copy.options[j].asObject, original.options[j].asObject);
        }
      }
    });
  });

  group('Partida en varios dispositivos (InMemoryMateRoomBackend)', () {
    test('docente + 2 mesas juegan sincronizados y cumplen RNF05', () async {
      final rooms = InMemoryRooms();
      final host = LocalGameController(
        random: Random(7),
        backend: InMemoryMateRoomBackend(uid: 'profe', shared: rooms),
      );
      final mesa1 = LocalGameController(
        backend: InMemoryMateRoomBackend(uid: 'mesa-1', shared: rooms),
      );
      final mesa2 = LocalGameController(
        backend: InMemoryMateRoomBackend(uid: 'mesa-2', shared: rooms),
      );

      final code = await host.createOnlineRoom(
        totalRounds: 4,
        hostPlays: false,
      );
      expect(code.length, roomCodeLength);
      expect(host.isOnline, isTrue);
      expect(host.isHost, isTrue);
      expect(host.hostPlays, isFalse);

      // Código inexistente devuelve false.
      expect(await mesa1.joinOnlineRoom('ZZZZZ'), isFalse);

      // Las 2 mesas se unen con el código de la sala.
      expect(await mesa1.joinOnlineRoom(code), isTrue);
      expect(await mesa2.joinOnlineRoom(code), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(host.teams.length, 2);
      expect(mesa1.teams.length, 2);
      expect(mesa2.teams.length, 2);
      expect(mesa1.myTeamIndex, 0);
      expect(mesa2.myTeamIndex, 1);

      // La docente inicia la partida.
      host.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(mesa1.phase, LocalPhase.spinning);
      expect(mesa2.phase, LocalPhase.spinning);

      // 4 rondas alternando turnos entre Mesa 1 y Mesa 2.
      for (var r = 1; r <= 4; r++) {
        host.drawCategoryIndex();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(mesa1.spinTrigger, r);

        host.onSpinFinished();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(mesa1.phase, LocalPhase.challenge);
        expect(mesa2.phase, LocalPhase.challenge);

        final turnOfMesa1 = r.isOdd;
        expect(mesa1.isMyTurn, turnOfMesa1);
        expect(mesa2.isMyTurn, !turnOfMesa1);

        // Si la mesa que NO está en turno intenta responder, se ignora.
        final wrongClient = turnOfMesa1 ? mesa2 : mesa1;
        await wrongClient.submitAnswer(0);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(host.phase, LocalPhase.challenge);

        // La mesa en turno responde (Mesa 1 acierta, Mesa 2 falla).
        final activeClient = turnOfMesa1 ? mesa1 : mesa2;
        final c = activeClient.challenge!;
        final choice = turnOfMesa1
            ? c.correctIndex
            : (c.correctIndex + 1) % c.options.length;
        await activeClient.submitAnswer(choice);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(host.phase, LocalPhase.feedback);
        expect(mesa1.phase, LocalPhase.feedback);
        expect(mesa2.phase, LocalPhase.feedback);
        expect(host.lastCorrect, turnOfMesa1);

        host.next();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(host.phase, LocalPhase.results);
      expect(mesa1.phase, LocalPhase.results);
      expect(mesa2.phase, LocalPhase.results);
      expect(host.teams[0].stars, 2);
      expect(host.teams[1].stars, 0);
      expect(mesa1.totalStars, 2);

      // Verificación RNF05: todas las acciones se reflejaron en ≤ 3 s.
      expect(mesa1.syncLatenciesMs, isNotEmpty);
      expect(mesa1.rnf05ComplianceRatio, 1.0);

      host.dispose();
      mesa1.dispose();
      mesa2.dispose();
    });

    test(
      '2 dispositivos: anfitrión juega como Mesa 1 + invitado como Mesa 2',
      () async {
        final rooms = InMemoryRooms();
        final cel1 = LocalGameController(
          random: Random(11),
          backend: InMemoryMateRoomBackend(uid: 'cel-1', shared: rooms),
        );
        final cel2 = LocalGameController(
          backend: InMemoryMateRoomBackend(uid: 'cel-2', shared: rooms),
        );

        // Por defecto hostPlays == true: el creador ya es Mesa 1.
        final code = await cel1.createOnlineRoom(totalRounds: 2);
        expect(cel1.teams.length, 1);
        expect(cel1.myTeamIndex, 0);

        // Al unirse el segundo dispositivo se cuentan 2 mesas en ambos.
        expect(await cel2.joinOnlineRoom(code), isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cel1.teams.length, 2);
        expect(cel2.teams.length, 2);
        expect(cel1.myTeamIndex, 0);
        expect(cel2.myTeamIndex, 1);

        cel1.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Ronda 1: turno exclusivo de Mesa 1 (cel1).
        cel1.drawCategoryIndex();
        cel1.onSpinFinished();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cel1.isMyTurn, isTrue);
        expect(cel2.isMyTurn, isFalse);
        await cel1.submitAnswer(cel1.challenge!.correctIndex);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cel2.phase, LocalPhase.feedback);

        // Ronda 2: turno exclusivo de Mesa 2 (cel2).
        cel1.next();
        cel1.drawCategoryIndex();
        cel1.onSpinFinished();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cel1.isMyTurn, isFalse);
        expect(cel2.isMyTurn, isTrue);
        await cel2.submitAnswer(cel2.challenge!.correctIndex);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cel1.phase, LocalPhase.feedback);

        cel1.next();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(cel1.phase, LocalPhase.results);
        expect(cel2.phase, LocalPhase.results);
        expect(cel1.totalStars, 2);

        cel1.dispose();
        cel2.dispose();
      },
    );
  });

  testWidgets('UI permite crear sala multidispositivo y mostrar el código', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1536);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final rooms = InMemoryRooms();
    final controller = LocalGameController(
      backend: InMemoryMateRoomBackend(uid: 'profe', shared: rooms),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MateRuedaDemoApp(
        splashDuration: const Duration(milliseconds: 100),
        controller: controller,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(_sem('Jugar'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    // Seleccionar modo "Varios" dispositivos y crear sala.
    await tester.tap(_sem('Varios'));
    await tester.pump();
    await tester.tap(_sem('Crear sala'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.isOnline, isTrue);
    expect(controller.roomCode, isNotNull);
    expect(find.text('Código de sala'), findsOneWidget);
    expect(find.text(controller.roomCode!), findsOneWidget);
  });
}
