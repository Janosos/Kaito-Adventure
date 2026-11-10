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

    return SafeArea(
      child: RepaintBoundary(
        child: Stack(
          children: [
            // Bottom Left: Zero-Latency Multi-Touch 2D Cartoon D-Pad
            Positioned(
              left: 20,
              bottom: 24,
              child: Row(
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

            // Top Center: Keyboard Key Controls Hint
            Positioned(
              top: 12,
              left: 230,
              right: 230,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: ComicTheme.comicPanelDecoration(
                    backgroundColor: ComicTheme.paperWhite,
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
                  child: Text(
                    'KEYS: [A/D] MOVE  [SPACE] JUMP  [J] SLASH  [K] DASH  [L] KUNAI (5s)  [U] OUGI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ComicTheme.comicBody(
                      fontSize: 10.5,
                      color: ComicTheme.inkBlack,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Right: Zero-Latency Multi-Touch 2D Cartoon Skill Cluster
            Positioned(
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Kunai (with 5s Cooldown Badge) & Dash Column
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
                  const SizedBox(width: 12),

                  // Melee Slash, Ougi & Jump Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUltReady)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActionButton(
                            iconAsset: CartoonAssets.uiSkillOugi,
                            label: 'OUGI [U]',
                            color: ComicTheme.comicYellow,
                            isLarge: true,
                            onTap: () => widget.game.player.performUltimate(),
                          ),
                        ),
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
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor:
              isPressed ? ComicTheme.halftoneGray : ComicTheme.paperWhite,
          isPressed: isPressed,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 32, height: 32),
            Text(
              label,
              style: ComicTheme.mangaHeader(
                fontSize: 10,
                color: ComicTheme.inkBlack,
              ),
            ),
          ],
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
          width: isLarge ? 68 : 58,
          height: isLarge ? 68 : 58,
          decoration: ComicTheme.comicButtonDecoration(
            backgroundColor: color,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconAsset,
                width: isLarge ? 36 : 30,
                height: isLarge ? 36 : 30,
              ),
              Text(
                label,
                style: ComicTheme.mangaHeader(
                  fontSize: isLarge ? 11 : 9.5,
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
    );
  }
}
