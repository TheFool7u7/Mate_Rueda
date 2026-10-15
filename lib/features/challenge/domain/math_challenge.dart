import 'dart:math';

/// Las 5 categorías matemáticas de MateRueda (Avance II, sección 3.1).
enum MathCategory {
  conteo('Conteo y números', 'OA1'),
  comparacion('Comparación', 'OA2'),
  sumas('Sumas', 'OA3'),
  restas('Restas', 'OA4'),
  figuras('Figuras geométricas', 'OA5');

  const MathCategory(this.label, this.oa);

  /// Nombre visible en el banner del reto.
  final String label;

  /// Objetivo de aprendizaje relacionado.
  final String oa;
}

/// Objetos ilustrables que se usan como apoyo visual en los retos.
enum ChallengeObject {
  manzana('manzana', 'manzanas'),
  estrella('estrella', 'estrellas'),
  pelota('pelota', 'pelotas'),
  flor('flor', 'flores');

  const ChallengeObject(this.singular, this.plural);
  final String singular;
  final String plural;
}

/// Figuras geométricas básicas (categoría OA5).
enum ShapeKind {
  circulo('círculo'),
  cuadrado('cuadrado'),
  triangulo('triángulo'),
  rectangulo('rectángulo');

  const ShapeKind(this.label);
  final String label;
}

/// Cómo se dibuja la ilustración central del reto.
enum ChallengeVisual {
  /// Un solo grupo de objetos (conteo).
  group,

  /// Dos grupos lado a lado (comparación).
  twoGroups,

  /// Grupo A + grupo B (suma).
  addition,

  /// Grupo inicial con algunos tachados (resta).
  subtraction,

  /// Una figura geométrica (figuras).
  shape,
}

/// Una opción de respuesta táctil.
class ChallengeOption {
  const ChallengeOption({required this.label, this.shape});

  /// Texto grande que se muestra en el botón ("5", "Izquierda", ...).
  final String label;

  /// Para retos de figuras: la figura que se dibuja en el botón.
  final ShapeKind? shape;
}

/// Un reto matemático listo para mostrarse.
class MathChallenge {
  const MathChallenge({
    required this.category,
    required this.question,
    required this.visual,
    required this.options,
    required this.correctIndex,
    this.object = ChallengeObject.manzana,
    this.countA = 0,
    this.countB = 0,
    this.shape,
  });

  final MathCategory category;
  final String question;
  final ChallengeVisual visual;
  final List<ChallengeOption> options;
  final int correctIndex;

  final ChallengeObject object;

  /// Cantidad del primer grupo (o total inicial en restas).
  final int countA;

  /// Cantidad del segundo grupo (o cantidad retirada en restas).
  final int countB;

  /// Figura a reconocer (solo categoría figuras).
  final ShapeKind? shape;

  bool isCorrect(int index) => index == correctIndex;

  /// Texto que se lee en voz alta con el botón de audio.
  String get narration => question;
}

/// Genera retos aleatorios adecuados para primer grado (cantidades 0–10).
///
/// TODO(materueda): cuando el flujo multijugador esté adaptado, el reto
/// lo generará el host y se sincronizará por Realtime Database.
class MathChallengeGenerator {
  MathChallengeGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  MathChallenge generate(MathCategory category) {
    switch (category) {
      case MathCategory.conteo:
        return _conteo();
      case MathCategory.comparacion:
        return _comparacion();
      case MathCategory.sumas:
        return _suma();
      case MathCategory.restas:
        return _resta();
      case MathCategory.figuras:
        return _figura();
    }
  }

  MathChallenge random() =>
      generate(MathCategory.values[_rng.nextInt(MathCategory.values.length)]);

  ChallengeObject _randomObject() =>
      ChallengeObject.values[_rng.nextInt(ChallengeObject.values.length)];

  int _between(int min, int max) => min + _rng.nextInt(max - min + 1);

  /// Construye 3 opciones numéricas consecutivas que contienen [answer].
  (List<ChallengeOption>, int) _numericOptions(int answer, {int min = 0}) {
    // Posición de la respuesta correcta dentro de las 3 opciones.
    var pos = _rng.nextInt(3);
    if (answer - pos < min) pos = answer - min;
    final start = answer - pos;
    final options = List.generate(
      3,
      (i) => ChallengeOption(label: '${start + i}'),
    );
    return (options, pos);
  }

  MathChallenge _conteo() {
    final obj = _randomObject();
    final n = _between(2, 8);
    final (options, correct) = _numericOptions(n, min: 1);
    return MathChallenge(
      category: MathCategory.conteo,
      question: '¿Cuántas ${obj.plural} hay?',
      visual: ChallengeVisual.group,
      object: obj,
      countA: n,
      options: options,
      correctIndex: correct,
    );
  }

  MathChallenge _comparacion() {
    final obj = _randomObject();
    final a = _between(1, 6);
    int b;
    do {
      b = _between(1, 6);
    } while (b == a);
    final askMore = _rng.nextBool();
    final leftWins = askMore ? a > b : a < b;
    return MathChallenge(
      category: MathCategory.comparacion,
      question: askMore ? '¿Dónde hay más?' : '¿Dónde hay menos?',
      visual: ChallengeVisual.twoGroups,
      object: obj,
      countA: a,
      countB: b,
      options: const [
        ChallengeOption(label: '◀'),
        ChallengeOption(label: '▶'),
      ],
      correctIndex: leftWins ? 0 : 1,
    );
  }

  MathChallenge _suma() {
    final obj = _randomObject();
    final a = _between(1, 5);
    final b = _between(1, 4);
    final (options, correct) = _numericOptions(a + b, min: 1);
    return MathChallenge(
      category: MathCategory.sumas,
      question: '¿Cuánto es $a + $b?',
      visual: ChallengeVisual.addition,
      object: obj,
      countA: a,
      countB: b,
      options: options,
      correctIndex: correct,
    );
  }

  MathChallenge _resta() {
    final obj = _randomObject();
    final a = _between(3, 8);
    final b = _between(1, a - 1);
    final (options, correct) = _numericOptions(a - b);
    return MathChallenge(
      category: MathCategory.restas,
      question: '¿Cuánto es $a − $b?',
      visual: ChallengeVisual.subtraction,
      object: obj,
      countA: a,
      countB: b,
      options: options,
      correctIndex: correct,
    );
  }

  MathChallenge _figura() {
    final shapes = List.of(ShapeKind.values)..shuffle(_rng);
    final target = shapes.first;
    final choices = shapes.take(3).toList()..shuffle(_rng);
    return MathChallenge(
      category: MathCategory.figuras,
      question: '¿Cuál es el ${target.label}?',
      visual: ChallengeVisual.shape,
      shape: target,
      options: choices
          .map((s) => ChallengeOption(label: s.label, shape: s))
          .toList(),
      correctIndex: choices.indexOf(target),
    );
  }

  /// Reto fijo idéntico al mockup 10_reto_matematico (5 manzanas; 4-5-6).
  static const MathChallenge mockup = MathChallenge(
    category: MathCategory.conteo,
    question: '¿Cuántas manzanas hay?',
    visual: ChallengeVisual.group,
    object: ChallengeObject.manzana,
    countA: 5,
    options: [
      ChallengeOption(label: '4'),
      ChallengeOption(label: '5'),
      ChallengeOption(label: '6'),
    ],
    correctIndex: 1,
  );
}
