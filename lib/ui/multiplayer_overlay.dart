import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Start WiFi discovery and listen to match start
    net.startRoomDiscovery();
    net.inMatchNotifier.addListener(_onMatchStarted);
    net.refreshLocalIp().then((_) {
      if (mounted) setState(() {});
    });
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
    LanMultiplayerService.instance.stopRoomDiscovery();
    _nicknameController.dispose();
    _ipController.dispose();
    _roomNameController.dispose();
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
    await LanMultiplayerService.instance.disconnect();
    await LanMultiplayerService.instance.startRoomDiscovery();
    if (mounted) {
      setState(() {
        _statusMessage = null;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Header Bar
        _buildHeader(net),
        const SizedBox(height: 10),

        // 2. Nickname & Kaito Custom Color Selector
        _buildCustomizerBar(net),
        const SizedBox(height: 10),

        // 3. Main Center Split: Left (Available Rooms) | Right (Create or Direct Connect)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Discovered Rooms List
              Expanded(
                flex: 6,
                child: _buildRoomsListCard(net),
              ),
              const SizedBox(width: 12),

              // Right: Host / Direct Connect Controls
              Expanded(
                flex: 5,
                child: _buildHostAndJoinCard(net),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingRoomLobby(LanMultiplayerService net) {
    final isHost = net.role == MatchRole.host;
    final fullIp = '${net.localIpAddress ?? "127.0.0.1"}:7777';

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
                          'IP DE LA SALA: $fullIp',
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
                            net.localIpAddress ?? '127.0.0.1'),
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
        const SizedBox(height: 12),

        // 2. 5 Player Slots Grid
        Expanded(
          child: ValueListenableBuilder<List<MultiplayerPlayer>>(
            valueListenable: net.roomPlayersNotifier,
            builder: (context, players, _) {
              return _buildSlotsGrid(players, net);
            },
          ),
        ),
        const SizedBox(height: 12),

        // 3. Bottom Action Bar
        _buildWaitingRoomBottomBar(net),
      ],
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
              const Text(
                'Red Local WiFi Activa',
                style: TextStyle(
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
                  color: pColor,
                  border: Border.all(color: Colors.black, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    'P${slot + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ComicTheme.actionRed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Icon(Icons.wifi, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MODO MULTIJUGADOR • SALAS WIFI LOCAL',
                style: ComicTheme.titleText(
                  size: 20,
                  color: ComicTheme.actionRed,
                ),
              ),
              Text(
                'CONÉCTATE CON HASTA 5 JUGADORES EN LA MISMA RED WIFI • DUELO & BATTLE ROYALE',
                style: ComicTheme.bodyText(
                  size: 11,
                  color: ComicTheme.inkBlack,
                ),
              ),
            ],
          ),
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                        size: 15,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 20),

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
