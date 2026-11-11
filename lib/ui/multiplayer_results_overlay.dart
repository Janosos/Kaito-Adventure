import 'dart:math';
import 'package:flutter/material.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import '../game/services/lan_multiplayer_service.dart';
import 'comic_theme.dart';

class MultiplayerResultsOverlay extends StatefulWidget {
  final MangaGame game;

  const MultiplayerResultsOverlay({super.key, required this.game});

  @override
  State<MultiplayerResultsOverlay> createState() =>
      _MultiplayerResultsOverlayState();
}

class _MultiplayerResultsOverlayState extends State<MultiplayerResultsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    AudioService.playSfx(AudioService.sfxVictory);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final net = LanMultiplayerService.instance;

    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: Stack(
        children: [
          // Dynamic Manga Radial Speedlines
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MangaSpeedLinesPainter(
                  lineCount: 42,
                  color: ComicTheme.comicYellow.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 900,
                    height: 520,
                    padding: const EdgeInsets.all(16),
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: const Color(0xFF16161F),
                      borderWidth: 4.5,
                      shadowOffset: 8,
                    ),
                    child: Column(
                      children: [
                        // 1. Title Banner
                        _buildHeaderBanner(),
                        const SizedBox(height: 12),

                        // 2. Smash Bros Style Character Podium
                        Expanded(
                          child: ValueListenableBuilder<List<MultiplayerPlayer>?>(
                            valueListenable: net.resultsPodiumNotifier,
                            builder: (context, podium, _) {
                              final players = podium ?? net.roomPlayers.values.toList();
                              return _buildPodium(players, net);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. Rematch Status / Countdown Banner
                        ValueListenableBuilder<int?>(
                          valueListenable: net.rematchCountdownNotifier,
                          builder: (context, countdown, _) {
                            if (countdown != null) {
                              return _buildCountdownBanner(countdown);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 8),

                        // 4. Bottom Controls Bar
                        _buildBottomControls(net),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.comicYellow,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.black, size: 28),
          const SizedBox(width: 10),
          Text(
            'RESULTADOS DE LA BATALLA',
            style: ComicTheme.titleText(
              size: 22,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.sports_kabaddi, color: Colors.black, size: 28),
        ],
      ),
    );
  }

  Widget _buildPodium(
      List<MultiplayerPlayer> players, LanMultiplayerService net) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          'Esperando resultados...',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Sort: 1st place in center, other placements flanking
    final winner = players.first;
    final others = players.length > 1 ? players.sublist(1) : <MultiplayerPlayer>[];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Flank Left (2nd place or others)
        if (others.isNotEmpty)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < others.length && i < 2; i++)
                  _buildDefeatedPedestal(
                    player: others[i],
                    rank: i + 2,
                    isLocal: others[i].id == net.myPlayerId,
                  ),
              ],
            ),
          ),

        // CENTER: 1ST PLACE WINNER SPOTLIGHT
        Expanded(
          flex: 4,
          child: _buildWinnerPedestal(
            winner: winner,
            isLocal: winner.id == net.myPlayerId,
          ),
        ),

        // Flank Right (3rd, 4th, 5th places)
        if (others.length > 2)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 2; i < others.length; i++)
                  _buildDefeatedPedestal(
                    player: others[i],
                    rank: i + 2,
                    isLocal: others[i].id == net.myPlayerId,
                  ),
              ],
            ),
          )
        else
          const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildWinnerPedestal({
    required MultiplayerPlayer winner,
    required bool isLocal,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Shining Crown & Aura
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final bounce = sin(_animController.value * pi) * 6.0;
            return Transform.translate(
              offset: Offset(0, -bounce),
              child: child,
            );
          },
          child: Column(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: ComicTheme.comicYellow,
                size: 38,
              ),
              const SizedBox(height: 4),

              // Victorious Shinobi Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: winner.color.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ComicTheme.comicYellow,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: winner.color.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 46,
                        color: winner.color,
                      ),
                      Text(
                        'P${winner.slot + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Nickname Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ComicTheme.comicYellow, width: 2),
          ),
          child: Text(
            winner.nickname + (isLocal ? ' (TÚ)' : ''),
            overflow: TextOverflow.ellipsis,
            style: ComicTheme.titleText(
              size: 14,
              color: ComicTheme.comicYellow,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Tall Gold Pedestal
        Container(
          width: 140,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFD600),
                Color(0xFFFF8F00),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '1° LUGAR',
                style: ComicTheme.titleText(
                  size: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '¡CAMPEÓN!',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefeatedPedestal({
    required MultiplayerPlayer player,
    required int rank,
    required bool isLocal,
  }) {
    final pedestalHeight = (110.0 - rank * 14.0).clamp(55.0, 95.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Fallen / Defeated Shinobi Avatar
        Opacity(
          opacity: 0.75,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(
                color: player.color.withValues(alpha: 0.7),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.close,
                    size: 26,
                    color: player.color,
                  ),
                  Text(
                    'P${player.slot + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Nickname Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Text(
            player.nickname + (isLocal ? ' (TÚ)' : ''),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Lower Stone Pedestal
        Container(
          width: 95,
          height: pedestalHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A38),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank° LUGAR',
                style: ComicTheme.titleText(
                  size: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'DERROTADO',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownBanner(int seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.actionRed,
        borderWidth: 3,
        shadowOffset: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, color: ComicTheme.comicYellow, size: 22),
          const SizedBox(width: 8),
          Text(
            '¡REVANCHA CONFIRMADA! INICIANDO EN $seconds...',
            style: ComicTheme.titleText(
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(LanMultiplayerService net) {
    final localPlayer = net.roomPlayers[net.myPlayerId];
    final hasVoted = localPlayer?.votedRematch ?? false;
    final votedCount =
        net.roomPlayers.values.where((p) => p.votedRematch).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. Rematch Vote Button
        GestureDetector(
          onTap: () {
            AudioService.buttonHaptic();
            AudioService.playSfx(AudioService.sfxStart);
            net.voteRematch();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: ComicTheme.panelDecoration(
              backgroundColor: hasVoted
                  ? const Color(0xFF00E676)
                  : ComicTheme.comicYellow,
              borderWidth: 3.5,
              shadowOffset: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasVoted ? Icons.check_circle : Icons.replay,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasVoted
                      ? '¡LISTO PARA REVANCHA! ($votedCount/2)'
                      : 'VOLVER A JUGAR ($votedCount/2)',
                  style: ComicTheme.titleText(
                    size: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // 2. Return to Main Menu
        GestureDetector(
          onTap: () {
            AudioService.buttonHaptic();
            AudioService.playSfx(AudioService.sfxClick);
            widget.game.returnToMainMenu();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: ComicTheme.panelDecoration(
              backgroundColor: const Color(0xFF333344),
              borderWidth: 3.5,
              shadowOffset: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SALIR AL MENÚ',
                  style: ComicTheme.titleText(
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
