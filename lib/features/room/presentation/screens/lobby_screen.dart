import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:wordwonderslink/core/constants/app_colors.dart';
import 'package:wordwonderslink/core/constants/app_dimensions.dart';
import 'package:wordwonderslink/core/constants/app_strings.dart';
import 'package:wordwonderslink/features/room/domain/room_model.dart';
import 'package:wordwonderslink/features/auth/presentation/providers/auth_provider.dart';
import 'package:wordwonderslink/features/room/presentation/providers/room_provider.dart';
import 'package:wordwonderslink/core/routes/app_router.dart';
import 'package:wordwonderslink/shared/presentation/widgets/common/app_button.dart';
import 'package:wordwonderslink/shared/data/audio_manager_service.dart';

/// Pantalla del lobby — sala de espera antes de iniciar la partida.
/// Muestra jugadores conectados, código para compartir, y botón iniciar (host).
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    AudioManagerService().playTrack('lobby.mp3', loop: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RoomProvider, AuthProvider>(
      builder: (context, roomProvider, authProvider, _) {
        final room = roomProvider.currentRoom;
        final uid = authProvider.currentUid;

        if (room == null) {
          // La sala fue eliminada (el host la cerró) → volver a home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La sala fue cerrada por el host.'),
                  duration: Duration(seconds: 3),
                ),
              );
              context.go(AppRoutes.home);
            }
          });
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Detectar si el juego comenzó
        if (room.status == RoomStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.game);
          });
        }

        final isHost = room.isHost(uid ?? '');

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
              onPressed: () {
                roomProvider.leaveRoom(authProvider.currentUser!);
                context.pop();
              },
            ),
            title: Text(
              AppStrings.lobbyTitle,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppDimensions.spacingL(context)),

                      // Código de sala
                      _buildRoomCode(context, room.roomCode, roomProvider),

                      SizedBox(height: AppDimensions.spacingXXL(context)),

                      // Lista de jugadores
                      Text(
                        '${AppStrings.playersLabel} (${room.players.length}/${room.maxPlayers})',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL(context),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingM(context)),

                      Expanded(child: _buildPlayerList(room, uid ?? '')),

                      // Info de configuración
                      _buildConfigInfo(room),

                      SizedBox(height: AppDimensions.spacingL(context)),

                      // Botón iniciar (solo host) o estado de espera
                      if (isHost)
                        AppButton.red(
                          text: room.canStart
                              ? AppStrings.startGame
                              : AppStrings.waitingForPlayers,
                          icon: room.canStart
                              ? Icons.play_arrow
                              : Icons.hourglass_top,
                          onPressed: room.canStart
                              ? () => roomProvider.startGame(uid!)
                              : null,
                        )
                      else
                        Container(
                          height: AppDimensions.buttonHeight(context),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXXL(context),
                            ),
                          ),
                          child: Text(
                            AppStrings.waitingForHost,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: AppDimensions.fontSizeL(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      SizedBox(height: AppDimensions.spacingXL(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomCode(
    BuildContext context,
    String code,
    RoomProvider roomProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingL(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.shareCode,
            style: TextStyle(
              color: Colors.white70,
              fontSize: AppDimensions.fontSizeS(context),
            ),
          ),
          SizedBox(height: AppDimensions.spacingS(context)),
          Text(
            code,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          SizedBox(height: AppDimensions.spacingM(context)),
          GestureDetector(
            onTap: () {
              roomProvider.copyRoomCode();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.codeCopied)),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL(context),
                vertical: AppDimensions.spacingXS(context),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusRound(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: Colors.white, size: 16),
                  SizedBox(width: AppDimensions.spacingXS(context)),
                  Text(
                    AppStrings.copyCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimensions.fontSizeS(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(RoomModel room, String currentUid) {
    return ListView.builder(
      itemCount: room.maxPlayers,
      itemBuilder: (context, index) {
        final hasPlayer = index < room.players.length;
        if (hasPlayer) {
          final player = room.players[index];
          final isMe = player.uid == currentUid;
          final isHost = player.uid == room.hostUid;
          return _PlayerTile(
            player: player,
            isMe: isMe,
            isHost: isHost,
            index: index,
          );
        }
        return _EmptySlot(index: index);
      },
    );
  }

  Widget _buildConfigInfo(RoomModel room) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.spacingM(context)),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(icon: Icons.people, label: '${room.maxPlayers} jugadores'),
          _InfoChip(icon: Icons.timer, label: '${room.timePerTurn}s por turno'),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final PlayerRef player;
  final bool isMe;
  final bool isHost;
  final int index;

  const _PlayerTile({
    required this.player,
    required this.isMe,
    required this.isHost,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingS(context)),
      padding: EdgeInsets.all(AppDimensions.spacingM(context)),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primaryBlue.withValues(alpha: 0.08)
            : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
        border: isMe
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                AppColors.playerColors[index % AppColors.playerColors.length],
            child: Text(
              player.username.isNotEmpty
                  ? player.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: AppDimensions.spacingM(context)),
          Expanded(
            child: Text(
              '${player.username}${isMe ? ' (Tú)' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppDimensions.fontSizeM(context),
                color: AppColors.textDark,
              ),
            ),
          ),
          if (isHost)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusRound(context),
                ),
              ),
              child: Text(
                'HOST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final int index;
  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spacingS(context)),
      padding: EdgeInsets.all(AppDimensions.spacingM(context)),
      decoration: BoxDecoration(
        color: AppColors.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM(context)),
        border: Border.all(
          color: AppColors.dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.dividerColor,
            child: Icon(Icons.person_add, color: AppColors.textGrey, size: 18),
          ),
          SizedBox(width: AppDimensions.spacingM(context)),
          Text(
            AppStrings.waitingPlayer,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: AppDimensions.fontSizeM(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS(context),
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
