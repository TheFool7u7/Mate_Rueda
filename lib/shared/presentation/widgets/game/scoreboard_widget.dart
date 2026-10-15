import 'package:flutter/material.dart';
import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_icon.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Widget del scoreboard que muestra los jugadores y sus puntajes.
/// Se posiciona en la esquina superior derecha de la pantalla de juego.
class ScoreboardWidget extends StatelessWidget {
  final List<PlayerRef> players;
  final Map<String, dynamic> playersData;
  final String? activePlayerUid;

  const ScoreboardWidget({
    super.key,
    required this.players,
    required this.playersData,
    this.activePlayerUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.scoreboardWidth(context),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS(context),
              vertical: AppDimensions.spacingXS(context),
            ),
            decoration: BoxDecoration(
              gradient: AppColors.buttonBlueGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusM(context)),
                topRight: Radius.circular(AppDimensions.radiusM(context)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcon.puntos, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'PUNTOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontSizeXS(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Filas de jugadores
          ...players.asMap().entries.map((entry) {
            final player = entry.value;
            final score = _getPlayerScore(player.uid);
            final isActive = player.uid == activePlayerUid;
            final isConnected = _isPlayerConnected(player.uid);

            return _PlayerScoreRow(
              username: player.username,
              score: score,
              isActive: isActive,
              isConnected: isConnected,
              playerColor: AppColors
                  .playerColors[entry.key % AppColors.playerColors.length],
            );
          }),
        ],
      ),
    );
  }

  int _getPlayerScore(String uid) {
    final data = playersData[uid] as Map<dynamic, dynamic>?;
    return (data?['roundScore'] as int?) ?? 0;
  }

  bool _isPlayerConnected(String uid) {
    final data = playersData[uid] as Map<dynamic, dynamic>?;
    return (data?['isConnected'] as bool?) ?? false;
  }
}

/// Fila individual de un jugador en el scoreboard
class _PlayerScoreRow extends StatefulWidget {
  final String username;
  final int score;
  final bool isActive;
  final bool isConnected;
  final Color playerColor;

  const _PlayerScoreRow({
    required this.username,
    required this.score,
    required this.isActive,
    required this.isConnected,
    required this.playerColor,
  });

  @override
  State<_PlayerScoreRow> createState() => _PlayerScoreRowState();
}

class _PlayerScoreRowState extends State<_PlayerScoreRow> {
  @override
  void didUpdateWidget(covariant _PlayerScoreRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score > oldWidget.score) {
      AudioManagerService().playSfx('count_points.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.scoreboardRowHeight(context),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS(context),
      ),
      decoration: BoxDecoration(
        color: widget.isActive
            ? widget.playerColor.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Indicador de color del jugador
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isConnected ? widget.playerColor : AppColors.textGrey,
            ),
          ),
          SizedBox(width: AppDimensions.spacingXS(context)),
          // Username (recortado si es muy largo)
          Expanded(
            child: Text(
              widget.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXS(context),
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isConnected ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
          ),
          // Puntaje
          Text(
            '${widget.score}',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS(context),
              fontWeight: FontWeight.w800,
              color: widget.playerColor,
            ),
          ),
        ],
      ),
    );
  }
}
