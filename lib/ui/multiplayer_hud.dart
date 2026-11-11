import 'package:flutter/material.dart';
import '../game/manga_game.dart';
import '../game/services/lan_multiplayer_service.dart';
import 'comic_theme.dart';

class MultiplayerHud extends StatelessWidget {
  final MangaGame game;

  const MultiplayerHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final net = LanMultiplayerService.instance;
    final player = game.player;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 820,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Local Player (Left): Avatar + Nickname + Continuous HP Bar + Ougi Bar
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: net.myColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                'P1',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              net.myNickname,
                              overflow: TextOverflow.ellipsis,
                              style: ComicTheme.titleText(
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${player.hp.clamp(0, 100)} / 100',
                            style: ComicTheme.titleText(
                              size: 13,
                              color: ComicTheme.comicYellow,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Continuous Health Bar
                      _buildHealthBar(
                        ratio: (player.hp / 100.0).clamp(0.0, 1.0),
                        isReversed: false,
                        playerColor: net.myColor,
                      ),
                      const SizedBox(height: 3),

                      // Slower-Charging Ougi Ultimate Bar
                      _buildOugiBar(
                        ratio: (player.spirit / 100.0).clamp(0.0, 1.0),
                        isReversed: false,
                      ),
                    ],
                  ),
                ),

                // 2. Center: Manga VS Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: ComicTheme.actionRed,
                      borderWidth: 3.5,
                      shadowOffset: 4,
                    ),
                    child: Text(
                      'VS',
                      style: ComicTheme.titleText(
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 3. Remote Opponent (Right): Continuous HP Bar + Ougi Bar + Avatar + Nickname
                Expanded(
                  flex: 5,
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: net.onMatchData,
                    builder: (context, snapshot) {
                      final remoteHp = game.pvpRemotePlayer?.hp ?? 100.0;
                      final remoteOugi = game.pvpRemotePlayer?.ougi ?? 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${remoteHp.clamp(0, 100).toInt()} / 100',
                                style: ComicTheme.titleText(
                                  size: 13,
                                  color: ComicTheme.comicYellow,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  net.opponentNickname,
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                  style: ComicTheme.titleText(
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: net.opponentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'P2',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Opponent Continuous Health Bar
                          _buildHealthBar(
                            ratio: (remoteHp / 100.0).clamp(0.0, 1.0),
                            isReversed: true,
                            playerColor: net.opponentColor,
                          ),
                          const SizedBox(height: 3),

                          // Opponent Ougi Bar
                          _buildOugiBar(
                            ratio: (remoteOugi / 100.0).clamp(0.0, 1.0),
                            isReversed: true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBar({
    required double ratio,
    required bool isReversed,
    required Color playerColor,
  }) {
    Color barColor;
    if (ratio > 0.50) {
      barColor = const Color(0xFF00E676);
    } else if (ratio > 0.25) {
      barColor = ComicTheme.comicYellow;
    } else {
      barColor = ComicTheme.actionRed;
    }

    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * ratio;
          return Stack(
            children: [
              Align(
                alignment: isReversed
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOugiBar({
    required double ratio,
    required bool isReversed,
  }) {
    final isFull = ratio >= 1.0;
    return Container(
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * ratio;
          return Align(
            alignment: isReversed
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: fillWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isFull ? ComicTheme.comicYellow : ComicTheme.energyCyan,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}

