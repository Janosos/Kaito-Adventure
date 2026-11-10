import 'package:flutter/material.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class MangaCutInOverlay extends StatefulWidget {
  final MangaGame game;
  const MangaCutInOverlay({super.key, required this.game});

  @override
  State<MangaCutInOverlay> createState() => _MangaCutInOverlayState();
}

class _MangaCutInOverlayState extends State<MangaCutInOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final bossName = game.cutInBossName;
    final quote = game.cutInQuote;
    final themeColor = game.cutInColor;
    final portraitAsset = game.cutInPortraitAsset;
    final screenSize = MediaQuery.of(context).size;
    final double uiScale = (screenSize.height / 500.0).clamp(0.72, 1.0);
    final double bannerHeight = 190.0 * uiScale;
    final double portraitSize = 146.0 * uiScale;

    // Cache the slanted halftone banner inside a RepaintBoundary as AnimatedBuilder's child:
    // Preserves 100% of the original visual design (slanted banner, halftone dots, glow shadow,
    // portrait frame, CUT-IN! tag, and speech bubble) while rasterizing the halftone pattern once!
    final Widget slantedBanner = RepaintBoundary(
      child: Transform.rotate(
        angle: -0.04,
        child: Container(
          width: double.infinity,
          height: bannerHeight,
          decoration: BoxDecoration(
            color: ComicTheme.inkBlack,
            border: const Border.symmetric(
              horizontal: BorderSide(color: Colors.white, width: 4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 8),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Halftone texture overlay (Original design)
              Positioned.fill(
                child: CustomPaint(
                  painter: HalftonePainter(
                    dotColor: themeColor.withValues(alpha: 0.25),
                    spacing: 8,
                    dotRadius: 2.0,
                  ),
                ),
              ),

              // Content with 2D Cartoon Character Portrait (Original design, responsive scaled)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 36 * uiScale,
                  vertical: 14 * uiScale,
                ),
                child: Row(
                  children: [
                    // 2D Cartoon Character Portrait Frame
                    Container(
                      width: portraitSize,
                      height: portraitSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor,
                            offset: const Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        portraitAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 22 * uiScale),

                    // Character Callout Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * uiScale,
                        vertical: 8 * uiScale,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUT-IN!',
                            style: ComicTheme.mangaHeader(
                              fontSize: 15 * uiScale,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            bossName,
                            style: ComicTheme.comicTitle(
                              fontSize: 30 * uiScale,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 22 * uiScale),

                    // Speech Bubble
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(14 * uiScale),
                        decoration: ComicTheme.comicPanelDecoration(
                          backgroundColor: ComicTheme.paperWhite,
                          borderColor: Colors.black,
                          borderWidth: 3,
                          shadowOffset: 4,
                        ),
                        child: Text(
                          '"$quote"',
                          style: ComicTheme.comicTitle(
                            fontSize: 20 * uiScale,
                            color: ComicTheme.inkBlack,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        child: slantedBanner,
        builder: (context, child) {
          final progress = _anim.value;
          double slide = 0.0;
          if (progress < 0.2) {
            slide = (1.0 - (progress / 0.2)) * 300;
          } else if (progress > 0.8) {
            slide = -((progress - 0.8) / 0.2) * 300;
          }

          return Stack(
            children: [
              // Radial Speed Lines (Original design)
              Positioned.fill(
                child: CustomPaint(
                  painter: SpeedLinesPainter(
                    color: Colors.black.withValues(alpha: 0.35),
                    count: 36,
                    progress: progress * 8,
                  ),
                ),
              ),

              // Slanted Dramatic 2D Cartoon Cut-In Banner
              Center(
                child: Transform.translate(
                  offset: Offset(slide, 0),
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
