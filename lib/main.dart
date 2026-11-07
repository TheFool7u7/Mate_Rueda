import 'package:wordwonderslink/main_demo.dart' as mate;

export 'package:wordwonderslink/main_demo.dart' show MateRuedaDemoApp;

/// Alias compatible con referencias existentes.
typedef WordWondersApp = mate.MateRuedaDemoApp;

/// Punto de entrada principal de MateRueda.
Future<void> main() => mate.main();
