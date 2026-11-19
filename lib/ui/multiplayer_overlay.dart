import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/cartoon_assets.dart';
import '../game/manga_game.dart';
import '../game/services/audio_service.dart';
import '../game/services/lan_multiplayer_service.dart';
import 'app_localizations.dart';
import 'comic_theme.dart';

class MultiplayerOverlay extends StatefulWidget {
  final MangaGame game;

  const MultiplayerOverlay({super.key, required this.game});

  @override
  State<MultiplayerOverlay> createState() => _MultiplayerOverlayState();
}

class _MultiplayerOverlayState extends State<MultiplayerOverlay> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _ipController;
  late final TextEditingController _roomNameController;
  late final TextEditingController _onlineServerController;

  String? _statusMessage;
  bool _copiedIpFeedback = false;

  @override
  void initState() {
    super.initState();
    final net = LanMultiplayerService.instance;
    _nicknameController = TextEditingController(text: net.myNickname);
    _ipController = TextEditingController(text: kIsWeb ? '127.0.0.1' : '');
    _roomNameController =
        TextEditingController(text: 'Dojo de ${net.myNickname}');
    _onlineServerController =
        TextEditingController(text: net.onlineServerAddress);

    net.inMatchNotifier.addListener(_onMatchStarted);
    net.modeNotifier.addListener(_onModeChanged);
    net.refreshLocalIp().then((_) {
      if (mounted) setState(() {});
    });

    if (net.isOnlineMode) {
      _handleRefreshOnlineServer(playSfx: false);
    } else {
      net.startRoomDiscovery();
    }
  }

  void _onModeChanged() {
    if (!mounted) return;
    final net = LanMultiplayerService.instance;
    setState(() {
      _statusMessage = null;
      _onlineServerController.text = net.onlineServerAddress;
    });
    if (net.isOnlineMode) {
      net.stopRoomDiscovery();
      _handleRefreshOnlineServer(playSfx: false);
    } else {
      net.startRoomDiscovery();
    }
  }

  void _onMatchStarted() {
    if (LanMultiplayerService.instance.inMatchNotifier.value) {
      widget.game.startPvPMatch();
    }
  }

  @override
  void dispose() {
    LanMultiplayerService.instance.inMatchNotifier
        .removeListener(_onMatchStarted);
    LanMultiplayerService.instance.modeNotifier.removeListener(_onModeChanged);
    LanMultiplayerService.instance.stopRoomDiscovery();
    _nicknameController.dispose();
    _ipController.dispose();
    _roomNameController.dispose();
    _onlineServerController.dispose();
    super.dispose();
  }

  void _randomizeNickname() {
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxClick);
    const prefixes = [
      'Kaito',
      'Shadow',
      'Raijin',
      'Shinobi',
      'Viper',
      'Frost',
      'Blaze',
      'Ghost',
      'Oni'
    ];
    final randomName =
        '${prefixes[(DateTime.now().millisecondsSinceEpoch % prefixes.length)]}_${DateTime.now().millisecond}';
    setState(() {
      _nicknameController.text = randomName;
      LanMultiplayerService.instance.myNickname = randomName;
    });
  }

  Future<void> _handleCreateRoom() async {
    if (kIsWeb) {
      AudioService.buttonHaptic();
      AudioService.playSfx(AudioService.sfxClick);
      setState(() {
        _statusMessage =
            'En navegador Web sólo puedes unirte como cliente.\nCrea la sala en Windows o Android e ingresa su IP a la derecha.';
      });
      return;
    }

    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    setState(() {
      _statusMessage = 'Iniciando servidor local...';
    });

    final success = await LanMultiplayerService.instance.startHostRoom(
      roomName: _roomNameController.text,
    );

    if (mounted) {
      setState(() {
        if (!success) {
          _statusMessage = 'Error al crear la sala en este puerto.';
        } else {
          _statusMessage = null;
        }
      });
    }
  }

  Future<void> _handleJoinRoom(String ip,
      [int port = LanMultiplayerService.kGamePort]) async {
    final targetIp = ip.trim();
    if (targetIp.isEmpty) return;

    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    setState(() {
      _statusMessage = 'Conectando con $targetIp...';
    });

    final ok =
        await LanMultiplayerService.instance.connectToRoom(targetIp, port);
    if (!ok && mounted) {
      setState(() {
        _statusMessage =
            'No se pudo conectar a la sala en $targetIp.\nVerifica que la app Host tenga la sala creada.';
      });
    } else if (mounted) {
      setState(() {
        _statusMessage = null;
      });
    }
  }

  Future<void> _handleCancelRoom() async {
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxClick);
    final net = LanMultiplayerService.instance;
    final wasOnline = net.isOnlineMode;
    await net.disconnect(keepMode: true);
    if (wasOnline) {
      await net.refreshOnlineServer();
    } else {
      await net.startRoomDiscovery();
    }
    if (mounted) {
      setState(() {
        _statusMessage = null;
      });
    }
  }

  Future<void> _handleRefreshOnlineServer({bool playSfx = true}) async {
    if (playSfx) {
      AudioService.buttonHaptic();
      AudioService.playSfx(AudioService.sfxClick);
    }
    final net = LanMultiplayerService.instance;
    setState(() {
      _statusMessage = null;
    });
    final customAddr = _onlineServerController.text.trim();
    final ok = await net.refreshOnlineServer(
      customAddress: customAddr.isNotEmpty ? customAddr : null,
    );
    if (mounted) {
      setState(() {
        _onlineServerController.text = net.onlineServerAddress;
        if (!ok) {
          _statusMessage = null;
        }
      });
    }
  }

  Future<void> _handleCreateOnlineRoom() async {
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    final net = LanMultiplayerService.instance;
    setState(() {
      _statusMessage = 'Creando sala en el Servidor Online...';
    });
    final ok = await net.createOnlineRoom(
      roomName: _roomNameController.text,
    );
    if (mounted) {
      setState(() {
        _statusMessage = ok
            ? null
            : (net.onlineErrorNotifier.value ??
                'No se pudo crear la sala. Verifica que el Servidor Online esté activo.');
      });
    }
  }

  Future<void> _handleJoinOnlineRoom({String? roomId}) async {
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    final net = LanMultiplayerService.instance;
    setState(() {
      _statusMessage = 'Uniéndose a la sala online...';
    });
    final ok = await net.joinOnlineRoom(roomId: roomId);
    if (mounted) {
      setState(() {
        _statusMessage = ok
            ? null
            : (net.onlineErrorNotifier.value ??
                'No se pudo unir a la sala online.');
      });
    }
  }

  void _copyIpToClipboard(String ip) {
    Clipboard.setData(ClipboardData(text: ip));
    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxClick);
    setState(() {
      _copiedIpFeedback = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedIpFeedback = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final net = LanMultiplayerService.instance;
    final inWaitingRoom = net.isConnected && net.role != MatchRole.none;

    return Material(
      color: Colors.black.withValues(alpha: 0.90),
      child: Stack(
        children: [
          // Dynamic Manga Background Speedlines
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MangaSpeedLinesPainter(
                  lineCount: 36,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 900,
                    height: 520,
                    padding: const EdgeInsets.all(16),
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: ComicTheme.paperWhite,
                      borderWidth: 4.5,
                      shadowOffset: 8,
                    ),
                    child: inWaitingRoom
                        ? _buildWaitingRoomLobby(net)
                        : _buildRoomSetupView(net),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSetupView(LanMultiplayerService net) {
    return ValueListenableBuilder<MultiplayerMode>(
      valueListenable: net.modeNotifier,
      builder: (context, mode, _) {
        final isOnline = mode == MultiplayerMode.online;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Header Bar with Mode Switcher (WiFi Local | Online Server)
            _buildHeader(net),
            const SizedBox(height: 10),

            // 2. Nickname & Kaito Custom Color Selector
            _buildCustomizerBar(net),
            const SizedBox(height: 10),

            // 3. Main Center Content: Online Server View vs Local WiFi View
            Expanded(
              child: isOnline
                  ? _buildOnlineServerSection(net)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: Discovered WiFi Rooms List
                        Expanded(
                          flex: 6,
                          child: _buildRoomsListCard(net),
                        ),
                        const SizedBox(width: 12),

                        // Right: Local Host / Direct Connect Controls
                        Expanded(
                          flex: 5,
                          child: _buildHostAndJoinCard(net),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaitingRoomLobby(LanMultiplayerService net) {
    final isHost = net.role == MatchRole.host;
    final isOnline = net.isOnlineMode;
    final fullIp = isOnline
        ? net.onlineServerAddress
        : '${net.localIpAddress ?? "127.0.0.1"}:7777';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Bar of Waiting Room
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isHost ? ComicTheme.comicYellow : ComicTheme.energyCyan,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Icon(
                isHost ? Icons.shield : Icons.wifi,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    net.currentRoomName.toUpperCase(),
                    style: ComicTheme.titleText(
                      size: 20,
                      color: ComicTheme.actionRed,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isOnline
                              ? 'SERVIDOR ONLINE: $fullIp (${net.currentOnlineRoomId ?? "SALA ACTIVA"})'
                              : 'IP DE LA SALA: $fullIp',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _copyIpToClipboard(
                          isOnline
                              ? net.onlineServerAddress
                              : (net.localIpAddress ?? '127.0.0.1'),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _copiedIpFeedback
                                ? const Color(0xFF00E676)
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: Text(
                            _copiedIpFeedback ? '¡COPIADO!' : 'COPIAR IP',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Text(
                'SALA DE ESPERA (2 A 5 JUGADORES)',
                style: ComicTheme.titleText(
                  size: 11,
                  color: ComicTheme.comicYellow,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1.5 Match Configuration Bar (Stage, Timer, HP Bar, Lives)
        _buildMatchConfigPanel(net),
        const SizedBox(height: 8),

        // 2. 5 Player Slots Grid
        Expanded(
          child: ValueListenableBuilder<List<MultiplayerPlayer>>(
            valueListenable: net.roomPlayersNotifier,
            builder: (context, players, _) {
              return _buildSlotsGrid(players, net);
            },
          ),
        ),
        const SizedBox(height: 8),

        // 3. Bottom Action Bar
        _buildWaitingRoomBottomBar(net),
      ],
    );
  }

  Widget _buildMatchConfigPanel(LanMultiplayerService net) {
    final isHost = net.role != MatchRole.client;

    return ValueListenableBuilder<MultiplayerMatchConfig>(
      valueListenable: net.matchConfigNotifier,
      builder: (context, cfg, _) {
        final stage = cfg.stage;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: ComicTheme.panelDecoration(
            backgroundColor: const Color(0xFF14141E),
            borderWidth: 2.5,
            shadowOffset: 3,
          ),
          child: Row(
            children: [
              // 1. Stage / Arena Selector
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: isHost
                      ? () {
                          AudioService.buttonHaptic();
                          AudioService.playSfx(AudioService.sfxClick);
                          final nextStage =
                              (cfg.stageIndex + 1) % kPvpStages.length;
                          net.updateMatchConfig(stageIndex: nextStage);
                        }
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stage.themeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: stage.themeColor, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            stage.widgetBgAsset,
                            width: 40,
                            height: 26,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ESCENARIO: ${stage.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ComicTheme.titleText(
                                  size: 11,
                                  color: ComicTheme.comicYellow,
                                ),
                              ),
                              Text(
                                stage.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isHost)
                          const Icon(
                            Icons.swap_horiz,
                            color: ComicTheme.comicYellow,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Match Timer Selector
              Expanded(
                flex: 2,
                child: _buildConfigChip(
                  icon: Icons.timer_outlined,
                  label: 'TIEMPO',
                  value: cfg.formattedTimeLimit,
                  accent: ComicTheme.energyCyan,
                  enabled: isHost,
                  onTap: () {
                    const opts = MultiplayerMatchConfig.kTimeOptions;
                    final idx = opts.indexOf(cfg.timeLimitSeconds);
                    final next = opts[(idx + 1) % opts.length];
                    net.updateMatchConfig(timeLimitSeconds: next);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3. Max HP Bar Selector
              Expanded(
                flex: 2,
                child: _buildConfigChip(
                  icon: Icons.bolt,
                  label: 'VIDA BARRA',
                  value: '${cfg.maxHp} HP',
                  accent: const Color(0xFF00E676),
                  enabled: isHost,
                  onTap: () {
                    const opts = MultiplayerMatchConfig.kHpOptions;
                    final idx = opts.indexOf(cfg.maxHp);
                    final next = opts[(idx + 1) % opts.length];
                    net.updateMatchConfig(maxHp: next);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 4. Remaining Lives / Stocks Selector
              Expanded(
                flex: 2,
                child: _buildConfigChip(
                  icon: Icons.favorite,
                  label: 'VIDAS',
                  value: '${cfg.lives} ${cfg.lives == 1 ? "VIDA" : "VIDAS"}',
                  accent: ComicTheme.actionRed,
                  enabled: isHost,
                  onTap: () {
                    const opts = MultiplayerMatchConfig.kLivesOptions;
                    final idx = opts.indexOf(cfg.lives);
                    final next = opts[(idx + 1) % opts.length];
                    net.updateMatchConfig(lives: next);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              AudioService.buttonHaptic();
              AudioService.playSfx(AudioService.sfxClick);
              onTap();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent, width: 1.6),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ComicTheme.titleText(
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(
                Icons.unfold_more,
                color: Colors.white54,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsGrid(
      List<MultiplayerPlayer> players, LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'JUGADORES EN LA SALA (${players.length} / 5)',
                style: ComicTheme.titleText(
                  size: 14,
                  color: ComicTheme.comicYellow,
                ),
              ),
              Text(
                net.isOnlineMode
                    ? '● Servidor Online Activo (${net.onlineServerAddress})'
                    : 'Red Local WiFi Activa',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                for (int slot = 0; slot < 5; slot++) ...[
                  if (slot > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _buildSlotCard(slot, players, net),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(
      int slot, List<MultiplayerPlayer> players, LanMultiplayerService net) {
    final player = players.where((p) => p.slot == slot).firstOrNull;
    final isOccupied = player != null;
    final isLocal = player?.id == net.myPlayerId;

    if (!isOccupied) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: Text(
                  'P${slot + 1}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'RANURA ${slot + 1}',
              style: const TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Esperando...',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    final pColor = player.color;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocal ? ComicTheme.comicYellow : pColor,
          width: isLocal ? 3.0 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: pColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Slot circle + avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                  border: Border.all(color: pColor, width: 2.5),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ColorFiltered(
                      colorFilter: MultiplayerColor.createSkinColorFilter(
                            pColor,
                            colorIndex: player.colorIndex,
                          ) ??
                          const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                      child: Image.asset(
                        CartoonAssets.kaitoVictory,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
              if (player.isHost)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: ComicTheme.comicYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: player.isHost
                  ? ComicTheme.comicYellow
                  : ComicTheme.energyCyan,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              player.isHost ? 'ANFITRIÓN' : 'CLIENTE',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Nickname
          Text(
            player.nickname + (isLocal ? ' (TÚ)' : ''),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ComicTheme.titleText(
              size: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Ready Tag
          const Text(
            '✓ CONECTADO',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingRoomBottomBar(LanMultiplayerService net) {
    final isHost = net.role == MatchRole.host;

    return ValueListenableBuilder<List<MultiplayerPlayer>>(
      valueListenable: net.roomPlayersNotifier,
      builder: (context, players, _) {
        final canStart = players.length >= 2;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel / Leave Room
            GestureDetector(
              onTap: _handleCancelRoom,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: ComicTheme.panelDecoration(
                  backgroundColor: const Color(0xFF333344),
                  borderWidth: 2.5,
                  shadowOffset: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isHost ? 'CERRAR SALA' : 'ABANDONAR SALA',
                      style: ComicTheme.titleText(
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Host: Start Match Button | Client: Waiting Message
            if (isHost)
              GestureDetector(
                onTap: canStart
                    ? () {
                        AudioService.buttonHaptic();
                        AudioService.playSfx(AudioService.sfxStart);
                        net.hostStartMatch();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: ComicTheme.panelDecoration(
                    backgroundColor: canStart
                        ? ComicTheme.comicYellow
                        : Colors.grey.shade700,
                    borderWidth: 3.0,
                    shadowOffset: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_kabaddi,
                        color: canStart ? Colors.black : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canStart
                            ? 'INICIAR PARTIDA (${players.length}/5)'
                            : 'ESPERANDO AL MENOS 1 RIVAL (${players.length}/5)',
                        style: ComicTheme.titleText(
                          size: 14,
                          color: canStart ? Colors.black : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: ComicTheme.energyCyan.withValues(alpha: 0.6),
                      width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ComicTheme.energyCyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Esperando a que el Anfitrión inicie la partida... (${players.length}/5)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(LanMultiplayerService net) {
    final isOnline = net.isOnlineMode;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF00838F) : ComicTheme.actionRed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(
            isOnline ? Icons.public : Icons.wifi,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnline
                    ? 'MODO MULTIJUGADOR ONLINE • SERVIDOR PC'
                    : 'MODO MULTIJUGADOR • SALAS WIFI LOCAL',
                style: ComicTheme.titleText(
                  size: 19,
                  color:
                      isOnline ? const Color(0xFF006064) : ComicTheme.actionRed,
                ),
              ),
              Text(
                isOnline
                    ? 'CONECTADO AL SERVIDOR PORTABLE DE PC • SALAS ONLINE DE 2 A 5 SHINOBIS'
                    : 'CONÉCTATE CON HASTA 5 JUGADORES EN LA MISMA RED WIFI • DUELO & BATTLE ROYALE',
                style: ComicTheme.bodyText(
                  size: 10.5,
                  color: ComicTheme.inkBlack,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Mode Switcher Tabs: [ WIFI LOCAL ] | [ MULTIPLAYER ONLINE ]
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: ComicTheme.mangaPanelBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (isOnline) {
                    AudioService.buttonHaptic();
                    AudioService.playSfx(AudioService.sfxClick);
                    net.setMultiplayerMode(MultiplayerMode.local);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: !isOnline
                        ? ComicTheme.comicYellow
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi,
                        size: 14,
                        color: !isOnline ? Colors.black : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'WIFI LOCAL',
                        style: ComicTheme.titleText(
                          size: 11.5,
                          color: !isOnline ? Colors.black : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  if (!isOnline) {
                    AudioService.buttonHaptic();
                    AudioService.playSfx(AudioService.sfxClick);
                    net.setMultiplayerMode(MultiplayerMode.online);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        isOnline ? ComicTheme.energyCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: 14,
                        color: isOnline ? Colors.black : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ONLINE',
                        style: ComicTheme.titleText(
                          size: 11.5,
                          color: isOnline ? Colors.black : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        GestureDetector(
          onTap: () {
            AudioService.buttonHaptic();
            AudioService.playSfx(AudioService.sfxClick);
            widget.game.closeMultiplayerLobby();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ComicTheme.panelDecoration(
              backgroundColor: ComicTheme.inkBlack,
              borderWidth: 2.5,
              shadowOffset: 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.tr('btn_back'),
                  style: ComicTheme.titleText(size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DEDICATED PC ONLINE SERVER LOBBY VIEWS
  // ===========================================================================
  Widget _buildOnlineServerSection(LanMultiplayerService net) {
    return ValueListenableBuilder<bool>(
      valueListenable: net.isCheckingOnlineServer,
      builder: (context, isChecking, _) {
        if (isChecking) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: ComicTheme.panelDecoration(
              backgroundColor: ComicTheme.mangaPanelBg,
              borderWidth: 3.5,
              shadowOffset: 4,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: ComicTheme.energyCyan,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BUSCANDO SERVIDOR ONLINE ACTIVO...',
                    style: ComicTheme.titleText(
                      size: 18,
                      color: ComicTheme.energyCyan,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Verificando conexión con el servidor en ${net.onlineServerAddress} (Puerto TCP 7779 / UDP 7780)...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: net.isOnlineServerActive,
          builder: (context, isServerActive, _) {
            if (!isServerActive) {
              return _buildNoOnlineServerActiveView(net);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Active Online Rooms List on the Server
                Expanded(
                  flex: 6,
                  child: _buildOnlineRoomsListCard(net),
                ),
                const SizedBox(width: 12),

                // Right: Create Online Room & Quick Join on the Server
                Expanded(
                  flex: 5,
                  child: _buildOnlineCreateAndQuickJoinCard(net),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNoOnlineServerActiveView(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ComicTheme.actionRed.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ComicTheme.actionRed, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.redAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '● SERVIDOR ONLINE DESCONECTADO',
                  style: ComicTheme.titleText(
                    size: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'NO HAY SERVIDOR ONLINE ACTIVADO',
            textAlign: TextAlign.center,
            style: ComicTheme.titleText(
              size: 26,
              color: ComicTheme.comicYellow,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No se encontró ningún servidor online activo en este momento.\n'
            'Para activar el Multijugador Online, abre la carpeta portable "servidor_online" en tu PC,\n'
            'ejecuta el archivo "INICIAR_SERVIDOR_ONLINE.bat" y pulsa el botón REFRESCAR.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Server IP / Port input + Big Refresh Button
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns, color: ComicTheme.energyCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SERVIDOR (IP:PUERTO):',
                    style: ComicTheme.titleText(
                      size: 12,
                      color: ComicTheme.energyCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: TextField(
                        controller: _onlineServerController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        decoration: const InputDecoration(
                          hintText: '127.0.0.1:7779 o IP del Servidor PC',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleRefreshOnlineServer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: ComicTheme.panelDecoration(
                        backgroundColor: ComicTheme.comicYellow,
                        borderWidth: 2.5,
                        shadowOffset: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'REFRESCAR',
                            style: ComicTheme.titleText(
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineRoomsListCard(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E676), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00E676),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SERVIDOR ONLINE ACTIVO (${net.onlineServerAddress})',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _handleRefreshOnlineServer,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'REFRESCAR',
                        style: ComicTheme.titleText(
                            size: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ValueListenableBuilder<List<OnlineRoomSummary>>(
              valueListenable: net.onlineRoomsNotifier,
              builder: (context, rooms, _) {
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_done,
                          size: 38,
                          color: ComicTheme.energyCyan,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'CONECTADO A ${net.onlineServerName.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: ComicTheme.titleText(
                            size: 13,
                            color: ComicTheme.comicYellow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No hay salas online creadas en este momento.\n'
                          '¡Crea una nueva Sala Online en el panel derecho o pulsa Partida Rápida!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final room = rooms[idx];
                    final hostColor = kMultiplayerColors[room.hostColorIndex
                            .clamp(0, kMultiplayerColors.length - 1)]
                        .primary;
                    final isFull = room.playerCount >= room.maxPlayers;
                    final canJoin = !room.inMatch && !isFull;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: hostColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.roomName,
                                  style: ComicTheme.titleText(
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Host: ${room.hostName} • ${room.config.stage.name} • '
                                  '${room.config.maxHp} HP • ${room.config.lives} Vidas (${room.playerCount}/${room.maxPlayers})',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: canJoin
                                ? () => _handleJoinOnlineRoom(
                                      roomId: room.roomId,
                                    )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: ComicTheme.panelDecoration(
                                backgroundColor: canJoin
                                    ? const Color(0xFF00E676)
                                    : Colors.grey.shade700,
                                borderWidth: 2,
                                shadowOffset: 2,
                              ),
                              child: Text(
                                room.inMatch
                                    ? 'EN COMBATE'
                                    : (isFull ? 'SALA LLENA' : 'UNIRSE'),
                                style: ComicTheme.titleText(
                                  size: 11.5,
                                  color:
                                      canJoin ? Colors.black : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCreateAndQuickJoinCard(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public,
                color: ComicTheme.energyCyan,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CREAR SALA ONLINE O PARTIDA RÁPIDA',
                  overflow: TextOverflow.ellipsis,
                  style: ComicTheme.titleText(
                    size: 13,
                    color: ComicTheme.energyCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Nombre de la Sala Online:',
            style: ComicTheme.bodyText(size: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: TextField(
              controller: _roomNameController,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Create Online Room & Quick Join Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _handleCreateOnlineRoom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: ComicTheme.comicYellow,
                      borderWidth: 3,
                      shadowOffset: 3,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'CREAR SALA ONLINE',
                            style: ComicTheme.titleText(
                              size: 12.5,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleJoinOnlineRoom(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: ComicTheme.energyCyan,
                      borderWidth: 3,
                      shadowOffset: 3,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PARTIDA RÁPIDA',
                            style: ComicTheme.titleText(
                              size: 12.5,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pre-Room Quick Stage & Rules Selector
          ValueListenableBuilder<MultiplayerMatchConfig>(
            valueListenable: net.matchConfigNotifier,
            builder: (context, cfg, _) {
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      net.updateMatchConfig(
                        stageIndex: (cfg.stageIndex + 1) % kPvpStages.length,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.comicYellow),
                      ),
                      child: Text(
                        '🗺️ ${cfg.stage.name}',
                        style: const TextStyle(
                          color: ComicTheme.comicYellow,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kTimeOptions;
                      final idx = opts.indexOf(cfg.timeLimitSeconds);
                      net.updateMatchConfig(
                        timeLimitSeconds: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.energyCyan),
                      ),
                      child: Text(
                        '⏱️ ${cfg.formattedTimeLimit}',
                        style: const TextStyle(
                          color: ComicTheme.energyCyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kHpOptions;
                      final idx = opts.indexOf(cfg.maxHp);
                      net.updateMatchConfig(
                        maxHp: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00E676)),
                      ),
                      child: Text(
                        '⚡ ${cfg.maxHp} HP',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kLivesOptions;
                      final idx = opts.indexOf(cfg.lives);
                      net.updateMatchConfig(
                        lives: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.actionRed),
                      ),
                      child: Text(
                        '❤️ ${cfg.lives} Vidas',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const Divider(color: Colors.white24, height: 14),

          // Change Online Server IP:Port
          Text(
            'Dirección del Servidor Online (IP:Puerto):',
            style: ComicTheme.bodyText(size: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: TextField(
                    controller: _onlineServerController,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: '127.0.0.1:7779',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleRefreshOnlineServer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: ComicTheme.panelDecoration(
                    backgroundColor: const Color(0xFF00E676),
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
                  child: Text(
                    'CAMBIAR IP',
                    style: ComicTheme.titleText(
                      size: 11.5,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ComicTheme.titleText(
                size: 10.5,
                color: Colors.amberAccent,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCustomizerBar(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ComicTheme.mangaPanelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ComicTheme.inkBlack, width: 3),
      ),
      child: Row(
        children: [
          // Nickname Editor
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Text(
                  'NICKNAME:',
                  style: ComicTheme.titleText(
                    size: 13,
                    color: ComicTheme.comicYellow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: TextField(
                      controller: _nicknameController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        net.myNickname = val.trim().isNotEmpty
                            ? val.trim()
                            : 'Kaito';
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _randomizeNickname,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: ComicTheme.panelDecoration(
                      backgroundColor: ComicTheme.energyCyan,
                      borderWidth: 2,
                      shadowOffset: 2,
                    ),
                    child: const Center(
                      child: Icon(Icons.shuffle, size: 18, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Kaito Palette Picker
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Text(
                  'COLOR KAITO:',
                  style: ComicTheme.titleText(
                    size: 13,
                    color: ComicTheme.comicYellow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(kMultiplayerColors.length, (idx) {
                      final item = kMultiplayerColors[idx];
                      final isSelected = net.myColorIndex == idx;
                      return GestureDetector(
                        onTap: () {
                          AudioService.buttonHaptic();
                          AudioService.playSfx(AudioService.sfxClick);
                          setState(() {
                            net.myColorIndex = idx;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: item.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.black,
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          item.primary.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsListCard(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.wifi_find,
                        color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SALAS WIFI DISPONIBLES',
                        overflow: TextOverflow.ellipsis,
                        style: ComicTheme.titleText(
                          size: 13,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  AudioService.buttonHaptic();
                  AudioService.playSfx(AudioService.sfxClick);
                  net.startRoomDiscovery();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'BUSCAR',
                        style: ComicTheme.titleText(
                            size: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ValueListenableBuilder<List<DiscoveredRoom>>(
              valueListenable: net.discoveredRooms,
              builder: (context, rooms, _) {
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.radar,
                            size: 38, color: Colors.white24),
                        const SizedBox(height: 6),
                        Text(
                          kIsWeb
                              ? 'En navegador Web únete ingresando la IP directa a la derecha.'
                              : 'Buscando salas en la misma red WiFi...\nAsegúrate de que otro dispositivo haya creado una sala.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final room = rooms[idx];
                    final hostColor = kMultiplayerColors[room.hostColorIndex
                            .clamp(0, kMultiplayerColors.length - 1)]
                        .primary;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: hostColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.roomName,
                                  style: ComicTheme.titleText(
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Host: ${room.hostName} • ${room.ip}:${room.port} (${room.playerCount}/5)',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleJoinRoom(room.ip, room.port),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: ComicTheme.panelDecoration(
                                backgroundColor: const Color(0xFF00E676),
                                borderWidth: 2,
                                shadowOffset: 2,
                              ),
                              child: Text(
                                'UNIRSE',
                                style: ComicTheme.titleText(
                                  size: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostAndJoinCard(LanMultiplayerService net) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ComicTheme.panelDecoration(
        backgroundColor: ComicTheme.mangaPanelBg,
        borderWidth: 3.5,
        shadowOffset: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.add_to_queue,
                  color: ComicTheme.comicYellow, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CREAR SALA O CONEXIÓN DIRECTA',
                  overflow: TextOverflow.ellipsis,
                  style: ComicTheme.titleText(
                    size: 13,
                    color: ComicTheme.comicYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Room Name Field
          Text(
            'Nombre del Dojo / Sala:',
            style: ComicTheme.bodyText(size: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: TextField(
              controller: _roomNameController,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Big Create Room Button
          GestureDetector(
            onTap: _handleCreateRoom,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: ComicTheme.panelDecoration(
                backgroundColor: ComicTheme.comicYellow,
                borderWidth: 3,
                shadowOffset: 4,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'CREAR SALA LOCAL',
                      style: ComicTheme.titleText(
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Pre-Room Quick Stage & Rules Selector
          ValueListenableBuilder<MultiplayerMatchConfig>(
            valueListenable: net.matchConfigNotifier,
            builder: (context, cfg, _) {
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      net.updateMatchConfig(
                        stageIndex: (cfg.stageIndex + 1) % kPvpStages.length,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.comicYellow),
                      ),
                      child: Text(
                        '🗺️ ${cfg.stage.name}',
                        style: const TextStyle(
                          color: ComicTheme.comicYellow,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kTimeOptions;
                      final idx = opts.indexOf(cfg.timeLimitSeconds);
                      net.updateMatchConfig(
                        timeLimitSeconds: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.energyCyan),
                      ),
                      child: Text(
                        '⏱️ ${cfg.formattedTimeLimit}',
                        style: const TextStyle(
                          color: ComicTheme.energyCyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kHpOptions;
                      final idx = opts.indexOf(cfg.maxHp);
                      net.updateMatchConfig(
                        maxHp: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00E676)),
                      ),
                      child: Text(
                        '⚡ ${cfg.maxHp} HP',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AudioService.buttonHaptic();
                      AudioService.playSfx(AudioService.sfxClick);
                      const opts = MultiplayerMatchConfig.kLivesOptions;
                      final idx = opts.indexOf(cfg.lives);
                      net.updateMatchConfig(
                        lives: opts[(idx + 1) % opts.length],
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ComicTheme.actionRed),
                      ),
                      child: Text(
                        '❤️ ${cfg.lives} Vidas',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const Divider(color: Colors.white24, height: 14),

          // Manual IP Connection
          Text(
            'O unirse por IP manual:',
            style: ComicTheme.bodyText(size: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ej. 192.168.1.15',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final ip = _ipController.text.trim();
                  if (ip.isNotEmpty) {
                    _handleJoinRoom(ip);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: ComicTheme.panelDecoration(
                    backgroundColor: ComicTheme.energyCyan,
                    borderWidth: 2.5,
                    shadowOffset: 3,
                  ),
                  child: Text(
                    'CONECTAR',
                    style: ComicTheme.titleText(
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: ComicTheme.titleText(
                size: 11,
                color: Colors.amberAccent,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
