import 'dart:math' as math;
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
  // Dynamic Touch-to-Appear Floating Joystick State (Left Side)
  int? _joystickPointerId;
  Offset _joystickOrigin = Offset.zero;
  Offset _joystickCurrent = Offset.zero;
  bool get _isJoystickActive => _joystickPointerId != null;

  // Pressed visual state for translucent right-side skill buttons
  final Set<String> _pressedButtons = <String>{};

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

  void _onJoystickDown(PointerDownEvent event, double maxRadius, Size areaSize) {
    if (_joystickPointerId != null) return;
    final clampedOrigin = Offset(
      event.localPosition.dx.clamp(maxRadius + 12.0, areaSize.width - maxRadius - 12.0),
      event.localPosition.dy.clamp(maxRadius + 12.0, areaSize.height - maxRadius - 12.0),
    );
    setState(() {
      _joystickPointerId = event.pointer;
      _joystickOrigin = clampedOrigin;
      _joystickCurrent = event.localPosition;
    });
    _updateJoystickMove(maxRadius);
  }

  void _onJoystickMove(PointerMoveEvent event, double maxRadius) {
    if (event.pointer != _joystickPointerId) return;
    setState(() {
      _joystickCurrent = event.localPosition;
    });
    _updateJoystickMove(maxRadius);
  }

  void _onJoystickUpOrCancel(PointerEvent event) {
    if (event.pointer != _joystickPointerId) return;
    setState(() {
      _joystickPointerId = null;
    });
    widget.game.player.moveInput = 0.0;
  }

  void _updateJoystickMove(double maxRadius) {
    final dx = _joystickCurrent.dx - _joystickOrigin.dx;
    final deadZone = maxRadius * 0.16;
    if (dx.abs() <= deadZone) {
      widget.game.player.moveInput = 0.0;
    } else {
      // Crisp analog-to-digital ramp so Kaito reaches full speed smoothly and quickly
      final sign = dx.sign;
      final normalized =
          ((dx.abs() - deadZone) / (maxRadius * 0.45)).clamp(0.35, 1.0);
      widget.game.player.moveInput = sign * normalized;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.game.player;
    final isUltReady = player.spirit >= 100.0;
    final kunaiCd = player.kunaiCooldown;
    final isKunaiReady = kunaiCd <= 0.01;
    final screenSize = MediaQuery.of(context).size;
    final double uiScale = (screenSize.height / 520.0).clamp(0.64, 0.95);
    final bool isCompact = screenSize.height < 440;
    final double edgePad = isCompact ? 8.0 : 14.0;
    final double bottomPad = isCompact ? 6.0 : 12.0;
    final double maxRadius = 46.0 * uiScale;
    final double leftZoneWidth = screenSize.width * 0.48;

    // Calculate clamped knob delta for rendering
    Offset knobDelta = Offset.zero;
    if (_isJoystickActive) {
      final rawDelta = _joystickCurrent - _joystickOrigin;
      final dist = rawDelta.distance;
      if (dist > maxRadius && dist > 0) {
        knobDelta = Offset(
          rawDelta.dx / dist * maxRadius,
          rawDelta.dy / dist * maxRadius,
        );
      } else {
        knobDelta = rawDelta;
      }
    }

    return SafeArea(
      child: RepaintBoundary(
        child: Stack(
          children: [
            // 1. Left Half Touch Zone: Floating 2D Cartoon Joystick
            // Completely invisible when not touching; appears at exact finger position on touch!
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: leftZoneWidth,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final zoneSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) => _onJoystickDown(e, maxRadius, zoneSize),
                    onPointerMove: (e) => _onJoystickMove(e, maxRadius),
                    onPointerUp: _onJoystickUpOrCancel,
                    onPointerCancel: _onJoystickUpOrCancel,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (_isJoystickActive)
                          Positioned(
                            left: _joystickOrigin.dx - maxRadius * 1.35,
                            top: _joystickOrigin.dy - maxRadius * 1.35,
                            child: IgnorePointer(
                              child: SizedBox(
                                width: maxRadius * 2.7,
                                height: maxRadius * 2.7,
                                child: CustomPaint(
                                  painter: _CartoonFloatingJoystickPainter(
                                    knobOffset: knobDelta,
                                    maxRadius: maxRadius,
                                  ),
                                  child: Center(
                                    child: Transform.translate(
                                      offset: knobDelta,
                                      child: Container(
                                        width: maxRadius * 0.92,
                                        height: maxRadius * 0.92,
                                        padding: EdgeInsets.all(5 * uiScale),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ComicTheme.comicYellow
                                              .withValues(alpha: 0.82),
                                          border: Border.all(
                                            color: ComicTheme.inkBlack,
                                            width: 2.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          CartoonAssets.uiKaitoHead,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. Bottom Right: Compact, Semi-Transparent 2D Cartoon Skill Cluster
            // Low opacity when idle (0.55) so the game world behind the buttons is always clearly visible!
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
                        id: 'ougi',
                        iconAsset: CartoonAssets.uiSkillOugi,
                        label: 'OUGI',
                        color: ComicTheme.comicYellow,
                        isLarge: true,
                        onTap: () => widget.game.player.performUltimate(),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Column 2 (Middle): Kunai (5s Cooldown) + Dash
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          id: 'kunai',
                          iconAsset: CartoonAssets.uiSkillKunai,
                          label: isKunaiReady
                              ? 'KUNAI'
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
                        const SizedBox(height: 8),
                        _buildActionButton(
                          id: 'dash',
                          iconAsset: CartoonAssets.uiSkillDash,
                          label: 'DASH',
                          color: ComicTheme.energyCyan,
                          onTap: () {
                            if (widget.game.player.dashCooldown <= 0) {
                              widget.game.player.performDash();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    // Column 3 (Rightmost): Melee Slash + Jump
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          id: 'slash',
                          iconAsset: CartoonAssets.uiSkillSlash,
                          label: 'SLASH',
                          color: ComicTheme.actionRed,
                          isLarge: true,
                          onTap: () {
                            if (widget.game.player.attackCooldown <= 0) {
                              widget.game.player.performAttack();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          id: 'jump',
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

  Widget _buildActionButton({
    required String id,
    required String iconAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
    bool isOnCooldown = false,
  }) {
    final isPressed = _pressedButtons.contains(id);
    final double btnSize = isLarge ? 58.0 : 50.0;
    final double baseOpacity = isOnCooldown
        ? 0.38
        : (isPressed ? 0.90 : 0.56);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _pressedButtons.add(id));
        onTap();
      },
      onPointerUp: (_) => setState(() => _pressedButtons.remove(id)),
      onPointerCancel: (_) => setState(() => _pressedButtons.remove(id)),
      child: Opacity(
        opacity: baseOpacity,
        child: Container(
          width: btnSize,
          height: btnSize,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: ComicTheme.inkBlack,
              width: 2.5,
            ),
            boxShadow: isPressed
                ? null
                : const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  iconAsset,
                  width: isLarge ? 28 : 24,
                  height: isLarge ? 28 : 24,
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: ComicTheme.mangaHeader(
                    fontSize: isLarge ? 9.5 : 8.5,
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

class _CartoonFloatingJoystickPainter extends CustomPainter {
  final Offset knobOffset;
  final double maxRadius;

  const _CartoonFloatingJoystickPainter({
    required this.knobOffset,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Translucent 2D Cartoon Base Circle
    final bgPaint = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // 2. Inner Guide Ring
    final innerRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius * 0.62, innerRingPaint);

    // 3. Outer Bold Cartoon Ring Outline
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, maxRadius, borderPaint);

    final inkOutlinePaint = Paint()
      ..color = ComicTheme.inkBlack.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius + 1.5, inkOutlinePaint);

    // 4. Directional Active Glow Arc when dragging left or right
    if (knobOffset.dx.abs() > maxRadius * 0.16) {
      final isRight = knobOffset.dx > 0;
      final arcPaint = Paint()
        ..color = ComicTheme.energyCyan.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.5;
      final startAngle = isRight ? -math.pi / 4 : (3 * math.pi / 4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxRadius),
        startAngle,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    // 5. Left / Right Cartoon Directional Chevrons inside the Ring
    final chevronPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Left chevron
    final leftPath = Path()
      ..moveTo(center.dx - maxRadius * 0.82, center.dy)
      ..lineTo(center.dx - maxRadius * 0.66, center.dy - 7)
      ..lineTo(center.dx - maxRadius * 0.66, center.dy + 7)
      ..close();
    canvas.drawPath(leftPath, chevronPaint);

    // Right chevron
    final rightPath = Path()
      ..moveTo(center.dx + maxRadius * 0.82, center.dy)
      ..lineTo(center.dx + maxRadius * 0.66, center.dy - 7)
      ..lineTo(center.dx + maxRadius * 0.66, center.dy + 7)
      ..close();
    canvas.drawPath(rightPath, chevronPaint);

    // 6. Stem line connecting center to thumb knob
    if (knobOffset.distance > 2.0) {
      final stemPaint = Paint()
        ..color = ComicTheme.energyCyan.withValues(alpha: 0.65)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, center + knobOffset, stemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CartoonFloatingJoystickPainter oldDelegate) {
    return oldDelegate.knobOffset != knobOffset ||
        oldDelegate.maxRadius != maxRadius;
  }
}
