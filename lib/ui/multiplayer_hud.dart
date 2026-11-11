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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 860,
            child: ValueListenableBuilder<List<MultiplayerPlayer>>(
              valueListenable: net.roomPlayersNotifier,
              builder: (context, players, _) {
                return StreamBuilder<Map<String, dynamic>>(
                  stream: net.onMatchData,
                  builder: (context, _) {
                    if (players.length <= 2) {
                      return _buildDuelLayout(net, player);
                    }
                    return _buildBattleRoyaleLayout(net, player, players);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuelLayout(LanMultiplayerService net, dynamic player) {
    final remotePlayer = game.pvpArena?.remotePlayers.values.firstOrNull;
    final remoteHp = remotePlayer?.hp ?? 100.0;
    final remoteOugi = remotePlayer?.ougi ?? 0.0;
    final remoteName = remotePlayer?.nickname ?? 'Rival';
    final remoteColor = remotePlayer?.playerColor ?? const Color(0xFF00E5FF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Local Player (Left)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildSlotBadge(net.mySlot, net.myColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${net.myNickname} (TÚ)',
                      overflow: TextOverflow.ellipsis,
                      style: ComicTheme.titleText(
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${player.hp.clamp(0, 100).toInt()} / 100',
                    style: ComicTheme.titleText(
                      size: 13,
                      color: ComicTheme.comicYellow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildHealthBar(
                ratio: (player.hp / 100.0).clamp(0.0, 1.0),
                isReversed: false,
              ),
              const SizedBox(height: 3),
              _buildOugiBar(
                ratio: (player.spirit / 100.0).clamp(0.0, 1.0),
                isReversed: false,
              ),
            ],
          ),
        ),

        // 2. Center VS Badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: ComicTheme.panelDecoration(
              backgroundColor: ComicTheme.actionRed,
              borderWidth: 3.0,
              shadowOffset: 3,
            ),
            child: Text(
              'VS',
              style: ComicTheme.titleText(
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // 3. Remote Opponent (Right)
        Expanded(
          flex: 5,
          child: Column(
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
                      remoteName,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: ComicTheme.titleText(
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSlotBadge(
                    remotePlayer?.slot ?? 1,
                    remoteColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildHealthBar(
                ratio: (remoteHp / 100.0).clamp(0.0, 1.0),
                isReversed: true,
              ),
              const SizedBox(height: 3),
              _buildOugiBar(
                ratio: (remoteOugi / 100.0).clamp(0.0, 1.0),
                isReversed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBattleRoyaleLayout(LanMultiplayerService net, dynamic player,
      List<MultiplayerPlayer> players) {
    return Row(
      children: [
        for (int i = 0; i < players.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildMiniCombatantCard(
              p: players[i],
              isLocal: players[i].id == net.myPlayerId,
              localHp: player.hp.toDouble(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniCombatantCard({
    required MultiplayerPlayer p,
    required bool isLocal,
    required double localHp,
  }) {
    final remote = game.pvpArena?.remotePlayers[p.id];
    final currentHp = isLocal ? localHp : (remote?.hp ?? p.hp);
    final ratio = (currentHp / 100.0).clamp(0.0, 1.0);
    final isAlive = currentHp > 0 && p.isAlive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLocal ? ComicTheme.comicYellow : Colors.black,
          width: isLocal ? 2.0 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildSlotBadge(p.slot, p.color, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  p.nickname + (isLocal ? ' (TÚ)' : ''),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAlive ? Colors.white : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                isAlive ? '${currentHp.toInt()}' : 'K.O.',
                style: TextStyle(
                  color: isAlive ? ComicTheme.comicYellow : Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          _buildHealthBar(ratio: ratio, isReversed: false, height: 8),
        ],
      ),
    );
  }

  Widget _buildSlotBadge(int slot, Color color, {double size = 22}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Center(
        child: Text(
          'P${slot + 1}',
          style: TextStyle(
            color: Colors.black,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBar({
    required double ratio,
    required bool isReversed,
    double height = 14,
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
      height: height,
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
                color: barColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF141419),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black, width: 1.0),
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
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          );
        },
      ),
    );
  }
}
