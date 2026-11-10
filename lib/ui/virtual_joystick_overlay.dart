import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import 'app_localizations.dart';
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

  // Pressed visual state for right-side 2D cartoon skill buttons
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

  void _onJoystickDown(
    PointerDownEvent event,
    double maxRadius,
    Size areaSize,
  ) {
    if (AppLocalizations.isEditingHudLayout.value) return;
    if (_joystickPointerId != null) return;
    final clampedOrigin = Offset(
      event.localPosition.dx.clamp(
        maxRadius + 12.0,
        math.max(maxRadius + 12.0, areaSize.width - maxRadius - 12.0),
      ),
      event.localPosition.dy.clamp(
        maxRadius + 12.0,
        math.max(maxRadius + 12.0, areaSize.height - maxRadius - 12.0),
      ),
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
      // Dynamic floating origin follow: if thumb drags beyond maxRadius,
      // shift origin along so reversing direction is always instant!
      final delta = _joystickCurrent - _joystickOrigin;
      final dist = delta.distance;
      if (dist > maxRadius && dist > 0) {
        _joystickOrigin = _joystickCurrent -
            Offset(
              delta.dx / dist * maxRadius,
              delta.dy / dist * maxRadius,
            );
      }
    });
    _updateJoystickMove(maxRadius);
  }

  void _onJoystickUpOrCancel(PointerEvent event) {
    if (event.pointer != _joystickPointerId) return;
    setState(() {
      _joystickPointerId = null;
    });
    widget.game.player.touchMoveInput = 0.0;
  }

  void _updateJoystickMove(double maxRadius) {
    final dx = _joystickCurrent.dx - _joystickOrigin.dx;
    const double deadZone = 6.0;
    if (dx.abs() <= deadZone) {
      widget.game.player.touchMoveInput = 0.0;
    } else {
      // Immediate full-speed continuous movement (-1.0 or +1.0) while held!
      widget.game.player.touchMoveInput = dx > 0 ? 1.0 : -1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudControlsConfig>(
      valueListenable: AppLocalizations.hudConfig,
      builder: (context, config, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppLocalizations.isEditingHudLayout,
          builder: (context, isEditing, _) {
            final player = widget.game.player;
            final isUltReady = player.spirit >= 100.0;
            final kunaiCd = player.kunaiCooldown;
            final isKunaiReady = kunaiCd <= 0.01;
            final screenSize = MediaQuery.of(context).size;
            final double uiScale =
                (screenSize.height / 500.0).clamp(0.68, 1.0);
            final double maxRadius = 46.0 * uiScale * config.buttonScale;
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaW = constraints.maxWidth > 0
                        ? constraints.maxWidth
                        : screenSize.width;
                    final areaH = constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : screenSize.height;

                    return Stack(
                      children: [
                        // Optional dark grid backdrop while in Drag-and-Drop Button Position Editor
                        if (isEditing)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.52),
                            ),
                          ),

                        // 1. Left Half Touch Zone: Floating 2D Cartoon Joystick
                        if (!isEditing)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: leftZoneWidth,
                            child: LayoutBuilder(
                              builder: (context, leftConstraints) {
                                final zoneSize = Size(
                                  leftConstraints.maxWidth,
                                  leftConstraints.maxHeight,
                                );
                                return Listener(
                                  behavior: HitTestBehavior.translucent,
                                  onPointerDown: (e) => _onJoystickDown(
                                    e,
                                    maxRadius,
                                    zoneSize,
                                  ),
                                  onPointerMove: (e) =>
                                      _onJoystickMove(e, maxRadius),
                                  onPointerUp: _onJoystickUpOrCancel,
                                  onPointerCancel: _onJoystickUpOrCancel,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (_isJoystickActive)
                                        Positioned(
                                          left: _joystickOrigin.dx -
                                              maxRadius * 1.35,
                                          top: _joystickOrigin.dy -
                                              maxRadius * 1.35,
                                          child: IgnorePointer(
                                            child: Opacity(
                                              opacity: config.buttonOpacity,
                                              child: SizedBox(
                                                width: maxRadius * 2.7,
                                                height: maxRadius * 2.7,
                                                child: CustomPaint(
                                                  painter:
                                                      _CartoonFloatingJoystickPainter(
                                                    knobOffset: knobDelta,
                                                    maxRadius: maxRadius,
                                                  ),
                                                  child: Center(
                                                    child: Transform.translate(
                                                      offset: knobDelta,
                                                      child: Container(
                                                        width:
                                                            maxRadius * 0.92,
                                                        height:
                                                            maxRadius * 0.92,
                                                        padding: EdgeInsets.all(
                                                          5 * uiScale,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: ComicTheme
                                                              .comicYellow,
                                                          border: Border.all(
                                                            color: ComicTheme
                                                                .inkBlack,
                                                            width: 2.5,
                                                          ),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                              color: ComicTheme
                                                                  .inkBlack,
                                                              offset:
                                                                  Offset(2, 2),
                                                              blurRadius: 0,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Image.asset(
                                                          CartoonAssets
                                                              .uiKaitoHead,
                                                          fit: BoxFit.contain,
                                                        ),
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

                        // 2. Customizable 2D Cartoon Action Buttons (Restored Classic Manga Panel Design!)
                        // Each button uses its persisted position, scale, and opacity!
                        if (isUltReady || isEditing)
                          _buildPositionedCartoonButton(
                            id: 'ougi',
                            iconAsset: CartoonAssets.uiSkillOugi,
                            label: 'OUGI [U]',
                            color: ComicTheme.comicYellow,
                            isLarge: true,
                            isOnCooldown: false,
                            config: config,
                            uiScale: uiScale,
                            areaW: areaW,
                            areaH: areaH,
                            isEditing: isEditing,
                            onTap: () => widget.game.player.performUltimate(),
                          ),

                        _buildPositionedCartoonButton(
                          id: 'kunai',
                          iconAsset: CartoonAssets.uiSkillKunai,
                          label: isKunaiReady || isEditing
                              ? 'KUNAI [L]'
                              : '${kunaiCd.toStringAsFixed(1)}s',
                          color: isKunaiReady || isEditing
                              ? ComicTheme.paperWhite
                              : ComicTheme.halftoneGray,
                          isLarge: false,
                          isOnCooldown: !isKunaiReady && !isEditing,
                          config: config,
                          uiScale: uiScale,
                          areaW: areaW,
                          areaH: areaH,
                          isEditing: isEditing,
                          onTap: () {
                            if (widget.game.player.kunaiCooldown <= 0) {
                              widget.game.player.performThrowKunai();
                              setState(() {});
                            }
                          },
                        ),

                        _buildPositionedCartoonButton(
                          id: 'dash',
                          iconAsset: CartoonAssets.uiSkillDash,
                          label: 'DASH [K]',
                          color: ComicTheme.energyCyan,
                          isLarge: false,
                          isOnCooldown: false,
                          config: config,
                          uiScale: uiScale,
                          areaW: areaW,
                          areaH: areaH,
                          isEditing: isEditing,
                          onTap: () {
                            if (widget.game.player.dashCooldown <= 0) {
                              widget.game.player.performDash();
                            }
                          },
                        ),

                        _buildPositionedCartoonButton(
                          id: 'slash',
                          iconAsset: CartoonAssets.uiSkillSlash,
                          label: 'SLASH [J]',
                          color: ComicTheme.actionRed,
                          isLarge: true,
                          isOnCooldown: false,
                          config: config,
                          uiScale: uiScale,
                          areaW: areaW,
                          areaH: areaH,
                          isEditing: isEditing,
                          onTap: () {
                            if (widget.game.player.attackCooldown <= 0) {
                              widget.game.player.performAttack();
                            }
                          },
                        ),

                        _buildPositionedCartoonButton(
                          id: 'jump',
                          iconAsset: CartoonAssets.uiSkillJump,
                          label: 'JUMP',
                          color: ComicTheme.comicYellow,
                          isLarge: true,
                          isOnCooldown: false,
                          config: config,
                          uiScale: uiScale,
                          areaW: areaW,
                          areaH: areaH,
                          isEditing: isEditing,
                          onTap: () {
                            if (widget.game.player.isOnGround ||
                                widget.game.player.isTouchingWall) {
                              widget.game.player.performJump();
                            }
                          },
                        ),

                        // 3. Top Control Toolbar when in Drag-and-Drop Button Layout Editor Mode
                        if (isEditing)
                          Positioned(
                            top: 8,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildEditorToolbar(config),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPositionedCartoonButton({
    required String id,
    required String iconAsset,
    required String label,
    required Color color,
    required bool isLarge,
    required bool isOnCooldown,
    required HudControlsConfig config,
    required double uiScale,
    required double areaW,
    required double areaH,
    required bool isEditing,
    required VoidCallback onTap,
  }) {
    final normPos = config.posFor(id);
    final double baseDim = isLarge ? 66.0 : 58.0;
    final double scaledDim =
        (baseDim * uiScale * config.buttonScale).clamp(38.0, 130.0);

    final double centerX = (normPos.dx * areaW)
        .clamp(scaledDim * 0.5 + 6.0, math.max(scaledDim * 0.5 + 6.0, areaW - scaledDim * 0.5 - 6.0));
    final double centerY = (normPos.dy * areaH)
        .clamp(scaledDim * 0.5 + 6.0, math.max(scaledDim * 0.5 + 6.0, areaH - scaledDim * 0.5 - 6.0));

    final isPressed = _pressedButtons.contains(id);
    final double effectiveOpacity = isOnCooldown
        ? (config.buttonOpacity * 0.60).clamp(0.20, 1.0)
        : (isPressed
            ? (config.buttonOpacity + 0.12).clamp(0.25, 1.0)
            : config.buttonOpacity);

    // Classic 2D Cartoon Manga Panel Button (ComicTheme.comicButtonDecoration)
    final Widget buttonCard = Opacity(
      opacity: effectiveOpacity,
      child: Container(
        width: scaledDim,
        height: scaledDim,
        padding: const EdgeInsets.all(4),
        decoration: ComicTheme.comicButtonDecoration(
          backgroundColor: color,
          borderColor: isEditing ? Colors.white : ComicTheme.inkBlack,
          isPressed: isPressed,
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
    );

    if (isEditing) {
      return Positioned(
        left: centerX - scaledDim * 0.5,
        top: centerY - scaledDim * 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            final newCenterX = centerX + details.delta.dx;
            final newCenterY = centerY + details.delta.dy;
            AppLocalizations.updateButtonPosition(
              id,
              Offset(newCenterX / areaW, newCenterY / areaH),
            );
          },
          child: buttonCard,
        ),
      );
    }

    return Positioned(
      left: centerX - scaledDim * 0.5,
      top: centerY - scaledDim * 0.5,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _pressedButtons.add(id));
          onTap();
        },
        onPointerUp: (_) => setState(() => _pressedButtons.remove(id)),
        onPointerCancel: (_) => setState(() => _pressedButtons.remove(id)),
        child: buttonCard,
      ),
    );
  }

  Widget _buildEditorToolbar(HudControlsConfig config) {
    final sizePct = (config.buttonScale * 100).round();
    final opacityPct = (config.buttonOpacity * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.paperWhite,
        borderWidth: 4,
        shadowOffset: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.tr('editor_banner_title'),
            style: ComicTheme.titleText(
              size: 18,
              color: ComicTheme.actionRed,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Size adjuster
              _buildMiniStepControl(
                label: '${AppLocalizations.tr('btn_size_label')}: $sizePct%',
                onMinus: () => AppLocalizations.updateButtonScale(
                  config.buttonScale - 0.10,
                ),
                onPlus: () => AppLocalizations.updateButtonScale(
                  config.buttonScale + 0.10,
                ),
              ),
              const SizedBox(width: 14),
              // Opacity adjuster
              _buildMiniStepControl(
                label:
                    '${AppLocalizations.tr('btn_opacity_label')}: $opacityPct%',
                onMinus: () => AppLocalizations.updateButtonOpacity(
                  config.buttonOpacity - 0.10,
                ),
                onPlus: () => AppLocalizations.updateButtonOpacity(
                  config.buttonOpacity + 0.10,
                ),
              ),
              const SizedBox(width: 14),
              // Reset Default Button
              GestureDetector(
                onTap: AppLocalizations.resetHudLayout,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: ComicTheme.energyCyan,
                  ),
                  child: Text(
                    AppLocalizations.tr('btn_reset_layout'),
                    style: ComicTheme.titleText(
                      size: 14,
                      color: ComicTheme.inkBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Save & Done Button
              GestureDetector(
                onTap: widget.game.closeHudLayoutEditor,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: ComicTheme.comicButtonDecoration(
                    backgroundColor: ComicTheme.comicYellow,
                  ),
                  child: Text(
                    AppLocalizations.tr('btn_save_layout'),
                    style: ComicTheme.titleText(
                      size: 15,
                      color: ComicTheme.inkBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepControl({
    required String label,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ComicTheme.mangaPanelBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ComicTheme.inkBlack, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onMinus,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ComicTheme.actionRed,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ComicTheme.inkBlack, width: 1.5),
              ),
              child: Text(
                '-',
                style: ComicTheme.titleText(size: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: ComicTheme.titleText(
              size: 13,
              color: ComicTheme.comicYellow,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPlus,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ComicTheme.inkBlack, width: 1.5),
              ),
              child: Text(
                '+',
                style: ComicTheme.titleText(
                  size: 16,
                  color: ComicTheme.inkBlack,
                ),
              ),
            ),
          ),
        ],
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
