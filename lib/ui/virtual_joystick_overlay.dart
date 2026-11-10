import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'comic_theme.dart';

class VirtualJoystickOverlay extends StatefulWidget {
  final MangaGame game;
  const VirtualJoystickOverlay({super.key, required this.game});

  @override
  State<VirtualJoystickOverlay> createState() => _VirtualJoystickOverlayState();
}

class _VirtualJoystickOverlayState extends State<VirtualJoystickOverlay>
    with SingleTickerProviderStateMixin {
  bool _leftPressed = false;
  bool _rightPressed = false;
  late final AnimationController _uiTicker;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _uiTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _uiTicker.addListener(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTickMs >= 80) {
        _lastTickMs = now;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTicker.dispose();
    super.dispose();
  }

  void _updateMove() {
    double horizontal = 0.0;
    if (_leftPressed) horizontal -= 1.0;
    if (_rightPressed) horizontal += 1.0;
    widget.game.player.moveInput = horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.game.player;
    final isUltReady = player.spirit >= 100.0;
    final kunaiCd = player.kunaiCooldown;
    final isKunaiReady = kunaiCd <= 0.01;
    final screenSize = MediaQuery.of(context).size;
    final double uiScale = (screenSize.height / 500.0).clamp(0.68, 1.0);
    final bool isCompact = screenSize.height < 440;
    final double edgePad = isCompact ? 10.0 : 18.0;
    final double bottomPad = isCompact ? 10.0 : 18.0;

    return SafeArea(
      child: RepaintBoundary(
        child: Stack(
          children: [
            // Bottom Left: Zero-Latency Multi-Touch 2D Cartoon D-Pad (Responsive Scaled)
            Positioned(
              left: edgePad,
              bottom: bottomPad,
              child: Transform.scale(
                scale: uiScale,
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDirectionButton(
                      assetPath: CartoonAssets.uiDpadLeft,
                      label: 'LEFT',
                      isPressed: _leftPressed,
                      onPressStart: () {
                        setState(() => _leftPressed = true);
                        _updateMove();
                      },
                      onPressEnd: () {
                        setState(() => _leftPressed = false);
                        _updateMove();
                      },
                    ),
                    const SizedBox(width: 14),
                    _buildDirectionButton(
                      assetPath: CartoonAssets.uiDpadRight,
                      label: 'RIGHT',
                      isPressed: _rightPressed,
                      onPressStart: () {
                        setState(() => _rightPressed = true);
                        _updateMove();
                      },
                      onPressEnd: () {
                        setState(() => _rightPressed = false);
                        _updateMove();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Right: Ergonomic Max-2-Row Arcade Skill Cluster
            // Never stacks 3-buttons high, so OUGI [U] never overlaps the Top-Right Score/Pause HUD!
            Positioned(
              right: edgePad,
              bottom: bottomPad,
              child: Transform.scale(
                scale: uiScale,
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Column 1 (Bottom-Left of Cluster): OUGI Ultimate Button (when 100% Spirit)
                    if (isUltReady) ...[
                      _buildActionButton(
                        iconAsset: CartoonAssets.uiSkillOugi,
                        label: 'OUGI [U]',
                        color: ComicTheme.comicYellow,
                        isLarge: true,
                        onTap: () => widget.game.player.performUltimate(),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Column 2 (Middle): Kunai (5s Cooldown) + Dash
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          iconAsset: CartoonAssets.uiSkillKunai,
                          label: isKunaiReady
                              ? 'KUNAI [L]'
                              : '${kunaiCd.toStringAsFixed(1)}s',
                          color: isKunaiReady
                              ? Colors.white
                              : ComicTheme.halftoneGray,
                          isOnCooldown: !isKunaiReady,
                          onTap: () {
                            if (widget.game.player.kunaiCooldown <= 0) {
                              widget.game.player.performThrowKunai();
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildActionButton(
                          iconAsset: CartoonAssets.uiSkillDash,
                          label: 'DASH [K]',
                          color: ComicTheme.energyCyan,
                          onTap: () {
                            if (widget.game.player.dashCooldown <= 0) {
                              widget.game.player.performDash();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Column 3 (Rightmost): Melee Slash + Jump
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          iconAsset: CartoonAssets.uiSkillSlash,
                          label: 'SLASH [J]',
                          color: ComicTheme.actionRed,
                          isLarge: true,
                          onTap: () {
                            if (widget.game.player.attackCooldown <= 0) {
                              widget.game.player.performAttack();
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildActionButton(
                          iconAsset: CartoonAssets.uiSkillJump,
                          label: 'JUMP',
                          color: ComicTheme.comicYellow,
                          isLarge: true,
                          onTap: () {
                            if (widget.game.player.isOnGround ||
                                widget.game.player.isTouchingWall) {
                              widget.game.player.performJump();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton({
    required String assetPath,
    required String label,
    required bool isPressed,
    required VoidCallback onPressStart,
    required VoidCallback onPressEnd,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPressStart(),
      onPointerUp: (_) => onPressEnd(),
      onPointerCancel: (_) => onPressEnd(),
      child: Container(
        width: 62,
        height: 62,
        padding: const EdgeInsets.all(4),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor:
              isPressed ? ComicTheme.halftoneGray : ComicTheme.paperWhite,
          isPressed: isPressed,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(assetPath, width: 32, height: 32),
              Text(
                label,
                maxLines: 1,
                style: ComicTheme.mangaHeader(
                  fontSize: 10,
                  color: ComicTheme.inkBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String iconAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
    bool isOnCooldown = false,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onTap(),
      child: Opacity(
        opacity: isOnCooldown ? 0.65 : 1.0,
        child: Container(
          width: isLarge ? 66 : 58,
          height: isLarge ? 66 : 58,
          padding: const EdgeInsets.all(4),
          decoration: ComicTheme.comicButtonDecoration(
            backgroundColor: color,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  iconAsset,
                  width: isLarge ? 34 : 28,
                  height: isLarge ? 34 : 28,
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: ComicTheme.mangaHeader(
                    fontSize: isLarge ? 10.5 : 9.5,
                    color: isOnCooldown
                        ? ComicTheme.actionRed
                        : ComicTheme.inkBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
