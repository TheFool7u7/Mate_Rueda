import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget helper para mostrar SVGs de los assets/icons de forma reutilizable.
/// Evita repetir la ruta y configuración en cada pantalla.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 32, this.color});

  /// Rutas de iconos SVG disponibles
  static const _base = 'assets/icons';

  static const String trofeo = '$_base/trofeo.svg';
  static const String medallaOro = '$_base/medalla_oro.svg';
  static const String medallaPlata = '$_base/medalla_plata.svg';
  static const String medallaBronce = '$_base/medalla_bronce.svg';
  static const String medallaSinRango = '$_base/medalla_sin_rango.svg';
  static const String control = '$_base/control_videojuegos.svg';
  static const String saludo = '$_base/saludo_lobby.svg';
  static const String puntos = '$_base/puntos.svg';
  static const String libro = '$_base/libro.svg';
  static const String lapiz = '$_base/lapiz.svg';
  static const String estrellaCalificar = '$_base/estrella_calificar.svg';
  static const String topJugadores = '$_base/top_jugadores.svg';
  static const String respuestaComun = '$_base/respuesta_comun.svg';
  static const String respuestaExcelente = '$_base/respuesta_excelente.svg';
  static const String respuestaSorprendente =
      '$_base/respuesta_sorprendente.svg';
  static const String castigoClock = '$_base/castigo_clock.svg';
  static const String castigoSkull = '$_base/castigo_skull.svg';
  static const String unirseASalaCadena = '$_base/unirse_a_sala_cadena.svg';
  static const String crearSalaJugadores = '$_base/crear_sala_jugadores.svg';

  // Nuevos iconos agregados
  static const String checkVerde = '$_base/check_verde.svg';
  static const String notasMusicales = '$_base/notas_musicales.svg';
  static const String conectado = '$_base/conectado.svg';
  static const String desconectado = '$_base/desconectado.svg';
  static const String selfie = '$_base/selfie.svg';
  static const String camara = '$_base/camara.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      name,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
