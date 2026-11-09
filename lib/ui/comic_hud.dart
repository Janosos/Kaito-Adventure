import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class ComicHud extends StatefulWidget {
  final MangaGame game;
  const ComicHud({super.key, required this.game});

  @override
  State<ComicHud> createState() => _ComicHudState();
}

class _ComicHudState extends State<ComicHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _ticker.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final player = game.player;
    final boss = game.activeBoss;

    return SafeArea(
      child: Stack(
        children: [
          // Top Left: 2D Cartoon Player Status Card
          Positioned(
            top: 14,
            left: 16,
            child: _buildPlayerStatusCard(player),
          ),

          // Top Right: Chapter & Score Card + Pause Button
          Positioned(
            top: 14,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreCard(game),
                const SizedBox(width: 8),
                _buildPauseButton(game),
              ],
            ),
          ),

          // Right: Dynamic Manga Combo Banner
          if (player.comboCount >= 2)
            Positioned(
              right: 24,
              top: 100,
              child: _buildComboBanner(player),
            ),

          // Bottom Center: 2D Cartoon Boss Health & Break Bar
          if (boss != null && !boss.isDefeated)
            Positioned(
              bottom: 24,
              left: 30,
              right: 30,
              child: _buildBossHud(boss),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatusCard(dynamic player) {
    final hp = player.hp as int;
    final maxHp = player.maxHp as int;
    final spirit = (player.spirit as double).clamp(0.0, 100.0);
    final isUltReady = spirit >= 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite,
        borderWidth: 3,
        shadowOffset: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2D Cartoon Kaito Avatar Portrait
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                CartoonAssets.portraitKaito,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name tag & Shinobi badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: ComicTheme.inkBlack,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '忍 KAITO',
                      style: ComicTheme.mangaHeader(
                          fontSize: 13, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SHINOBI',
                    style: ComicTheme.comicBody(
                        fontSize: 11, color: Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 2D Cartoon Health Hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(maxHp, (index) {
                  final isFull = index < hp;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Image.asset(
                      isFull
                          ? CartoonAssets.uiHeartFull
                          : CartoonAssets.uiHeartEmpty,
                      width: 22,
                      height: 22,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),

              // Ougi / Spirit Gauge Bar with 2D Cartoon Spirit Orb Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    CartoonAssets.uiSpiritOrb,
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'OUGI: ',
                    style: ComicTheme.mangaHeader(
                        fontSize: 12, color: ComicTheme.inkBlack),
                  ),
                  Container(
                    width: 96,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ComicTheme.halftoneGray,
                      borderRadius: BorderRadius.circular(3),
                      border:
                          Border.all(color: ComicTheme.inkBlack, width: 2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: spirit / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUltReady
                              ? ComicTheme.comicYellow
                              : ComicTheme.energyCyan,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                  if (isUltReady) ...[
                    const SizedBox(width: 4),
                    Text(
                      'MAX!!',
                      style: ComicTheme.comicTitle(
                        fontSize: 13,
                        color: ComicTheme.actionRed,
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(MangaGame game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ComicTheme.comicPanelDecoration(
        backgroundColor: ComicTheme.paperWhite,
        borderWidth: 3,
        shadowOffset: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            CartoonAssets.uiScoreScroll,
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHAPTER ${game.currentLevelIndex}',
                style: ComicTheme.mangaHeader(
                    fontSize: 13, color: ComicTheme.actionRed),
              ),
              Text(
                'SCORE: ${game.score.toString().padLeft(6, '0')}',
                style: ComicTheme.comicTitle(
                    fontSize: 18, color: ComicTheme.inkBlack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(MangaGame game) {
    return GestureDetector(
      onTap: () => game.togglePause(),
      child: Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(7),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor: ComicTheme.comicYellow,
        ),
        child: Image.asset(
          CartoonAssets.uiPause,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildComboBanner(dynamic player) {
    final count = player.comboCount as int;
    String grade = 'GOOD!';
    Color gradeColor = ComicTheme.comicYellow;
    if (count >= 10) {
      grade = 'INSANE!!';
      gradeColor = ComicTheme.actionRed;
    } else if (count >= 5) {
      grade = 'SUGOI!!';
      gradeColor = ComicTheme.energyCyan;
    }

    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: ComicTheme.comicPanelDecoration(
          backgroundColor: gradeColor,
          borderColor: ComicTheme.inkBlack,
          borderWidth: 3,
          shadowOffset: 4,
        ),
        child: Column(
          children: [
            Text(
              'COMBO x$count',
              style: ComicTheme.comicTitle(
                  fontSize: 22, color: ComicTheme.inkBlack),
            ),
            Text(
              grade,
              style: ComicTheme.mangaHeader(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBossHud(dynamic boss) {
    final double hpRatio = (boss.currentHp / boss.maxHp).clamp(0.0, 1.0);
    final double stunRatio = (boss.stunGauge / 100.0).clamp(0.0, 1.0);
    final isStunned = boss.isStunned as bool;
    final bossName = boss.name as String;
    final bossPortrait = bossName.contains('KUROKAGE')
        ? CartoonAssets.portraitKurokage
        : CartoonAssets.portraitRyuKotei;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: ComicTheme.comicPanelDecoration(
            backgroundColor: ComicTheme.paperWhite,
            borderColor: ComicTheme.inkBlack,
            borderWidth: 3,
            shadowOffset: 4,
          ),
          child: Row(
            children: [
              // 2D Cartoon Boss Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ComicTheme.inkBlack, width: 2.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    bossPortrait,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              color: ComicTheme.actionRed,
                              child: Text(
                                'BOSS',
                                style: ComicTheme.mangaHeader(
                                    fontSize: 13, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${boss.name}: ${boss.title}',
                              style: ComicTheme.comicTitle(
                                fontSize: 18,
                                color: ComicTheme.inkBlack,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'PHASE ${boss.currentPhase}/${boss.maxPhases}',
                          style: ComicTheme.mangaHeader(
                              fontSize: 14, color: ComicTheme.inkBlack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Boss Main Health Bar
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: ComicTheme.halftoneGray,
                        border:
                            Border.all(color: ComicTheme.inkBlack, width: 2.5),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: hpRatio,
                            child: Container(
                              color: isStunned
                                  ? ComicTheme.comicYellow
                                  : ComicTheme.actionRed,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(hpRatio * 100).toInt()}%',
                              style: ComicTheme.comicTitle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Stun / Break Gauge Bar
                    Row(
                      children: [
                        Text(
                          'STUN BREAK: ',
                          style: ComicTheme.mangaHeader(
                              fontSize: 11, color: Colors.grey.shade800),
                        ),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: ComicTheme.halftoneGray,
                              border: Border.all(
                                  color: ComicTheme.inkBlack, width: 1.5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: stunRatio,
                              child: Container(
                                color: isStunned
                                    ? Colors.redAccent
                                    : ComicTheme.energyCyan,
                              ),
                            ),
                          ),
                        ),
                        if (isStunned) ...[
                          const SizedBox(width: 6),
                          Text(
                            'BREAK STATUS (2x DMG)!',
                            style: ComicTheme.comicTitle(
                              fontSize: 11,
                              color: ComicTheme.actionRed,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
