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

class _VirtualJoystickOverlayState extends State<VirtualJoystickOverlay> {
  bool _leftPressed = false;
  bool _rightPressed = false;

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

    return SafeArea(
      child: Stack(
        children: [
          // Bottom Left: 2D Cartoon D-Pad Left & Right
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
            top: 14,
            left: 240,
            right: 240,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: ComicTheme.comicPanelDecoration(
                  backgroundColor: ComicTheme.paperWhite,
                  borderWidth: 2,
                  shadowOffset: 2,
                ),
                child: Text(
                  'KEYS: [A/D] MOVE  [SPACE] JUMP  [J] SLASH  [K] DASH  [L] KUNAI  [U] OUGI',
                  style: ComicTheme.comicBody(
                      fontSize: 11, color: ComicTheme.inkBlack),
                ),
              ),
            ),
          ),

          // Bottom Right: 2D Cartoon Skill Action Cluster
          Positioned(
            right: 20,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Kunai & Dash Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      iconAsset: CartoonAssets.uiSkillKunai,
                      label: 'KUNAI [L]',
                      color: Colors.white,
                      onTap: () => widget.game.player.performThrowKunai(),
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
                      onTap: () => widget.game.player.performJump(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: () => onPressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 60,
        height: 60,
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
                  fontSize: 10, color: ComicTheme.inkBlack),
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
  }) {
    return GestureDetector(
      onTap: onTap,
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
                color: ComicTheme.inkBlack,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
