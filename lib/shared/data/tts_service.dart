import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voz (texto a voz) compartida por toda la app.
///
/// Un único motor evita que una pantalla que se cierra (`dispose`) corte la
/// frase que acaba de empezar la pantalla siguiente: antes, cada pantalla
/// tenía su propio `FlutterTts` y su `stop()` interrumpía el motor común.
/// Aquí solo se corta una frase cuando se pide otra, o al llamar a [stop]
/// de forma explícita.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  Future<void>? _initFuture;

  /// Se incrementa en cada petición; permite ignorar peticiones obsoletas
  /// si llegan varias seguidas.
  int _ticket = 0;

  Future<void> _init() {
    return _initFuture ??= () async {
      try {
        final tts = FlutterTts();
        // es-MX es la voz más cercana al español de Costa Rica.
        await tts.setLanguage('es-MX');
        await tts.setSpeechRate(0.45);
        await tts.setPitch(1.1);
        await tts.setVolume(1.0);
        // Esperar a que termine la frase antes de dar por concluido speak().
        await tts.awaitSpeakCompletion(true);
        _tts = tts;
      } catch (e) {
        debugPrint('TTS no disponible: $e');
      }
    }();
  }

  /// Lee [text] en voz alta, cortando la frase anterior si la hubiera.
  Future<void> speak(String text) async {
    final ticket = ++_ticket;
    try {
      await _init();
      final tts = _tts;
      if (tts == null || ticket != _ticket) return;
      await tts.stop();
      // Pequeña pausa: algunos motores ignoran un speak() inmediatamente
      // posterior a un stop() y la frase sale cortada.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (ticket != _ticket) return;
      await tts.speak(text);
    } catch (e) {
      debugPrint('Error de TTS: $e');
    }
  }

  /// Corta la voz actual (p. ej. cuando el niño ya respondió).
  Future<void> stop() async {
    _ticket++;
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
