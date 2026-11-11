import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  bool _isCreatingRoom = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final net = LanMultiplayerService.instance;
    _nicknameController = TextEditingController(text: net.myNickname);
    _ipController = TextEditingController(text: kIsWeb ? '127.0.0.1' : '');
    _roomNameController = TextEditingController(text: 'Dojo de ${net.myNickname}');

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
    LanMultiplayerService.instance.inMatchNotifier.removeListener(_onMatchStarted);
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
        _isCreatingRoom = false;
        _statusMessage =
            'En navegador Web sólo puedes unirte como cliente.\nCrea la sala en Windows o Android e ingresa su IP a la derecha.';
      });
      return;
    }

    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    setState(() {
      _isCreatingRoom = true;
      _statusMessage = 'Iniciando servidor local...';
    });

    final success = await LanMultiplayerService.instance.startHostRoom(
      roomName: _roomNameController.text,
    );

    if (mounted) {
      setState(() {
        if (success) {
          _statusMessage =
              '¡SALA CREADA!\nEsperando rival en la red WiFi...\nIP Local: ${LanMultiplayerService.instance.localIpAddress}:7777';
        } else {
          _isCreatingRoom = false;
          _statusMessage = 'Error al crear la sala en este puerto.';
        }
      });
    }
  }

  Future<void> _handleJoinRoom(String ip, [int port = LanMultiplayerService.kGamePort]) async {
    final targetIp = ip.trim();
    if (targetIp.isEmpty) return;

    AudioService.buttonHaptic();
    AudioService.playSfx(AudioService.sfxStart);
    setState(() {
      _statusMessage = 'Conectando con $targetIp...';
    });

    final ok = await LanMultiplayerService.instance.connectToRoom(targetIp, port);
    if (!ok && mounted) {
      setState(() {
        _statusMessage =
            'No se pudo conectar a la sala en $targetIp.\nVerifica que la app Host tenga la sala creada.';
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
        _isCreatingRoom = false;
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final net = LanMultiplayerService.instance;

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    child: Column(
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
                'CONÉCTATE CON OTRO JUGADOR EN LA MISMA RED WIFI • DUELO 1V1',
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
                    child: const Icon(Icons.casino, size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Kaito Color Customizer (8 Colors)
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
                        child: Container(
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
                                      color: item.primary.withValues(alpha: 0.6),
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
                    const Icon(Icons.wifi_find, color: Colors.cyanAccent, size: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        style: ComicTheme.titleText(size: 11, color: Colors.white),
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
                        if (!kIsWeb) ...[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Escaneando red local WiFi...',
                            style: ComicTheme.titleText(
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crea una sala en el otro celular o conéctate por IP directa.',
                            textAlign: TextAlign.center,
                            style: ComicTheme.bodyText(
                              size: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.language,
                            size: 32,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modo Navegador Web (Cliente)',
                            style: ComicTheme.titleText(
                              size: 14,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Los navegadores web no admiten escaneo UDP.\nIngresa la IP del Host a la derecha para unirte.',
                            textAlign: TextAlign.center,
                            style: ComicTheme.bodyText(
                              size: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final color = kMultiplayerColors[
                        room.hostColorIndex.clamp(0, kMultiplayerColors.length - 1)];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.primary, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  room.roomName,
                                  style: ComicTheme.titleText(
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Host: ${room.hostName} • ${room.ip}:${room.port}',
                                  style: ComicTheme.bodyText(
                                    size: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleJoinRoom(room.ip, room.port),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: ComicTheme.panelDecoration(
                                backgroundColor: ComicTheme.actionRed,
                                borderWidth: 2.5,
                                shadowOffset: 3,
                              ),
                              child: Text(
                                'UNIRSE',
                                style: ComicTheme.titleText(
                                  size: 13,
                                  color: Colors.white,
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
          Text(
            _isCreatingRoom ? 'SALA EN ESPERA' : 'CREAR O ENTRAR DIRECTO',
            style: ComicTheme.titleText(
              size: 14,
              color: ComicTheme.comicYellow,
            ),
          ),
          const SizedBox(height: 8),

          if (kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amberAccent, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'En Chrome/Web: Ingresa la IP que muestra Windows (ej. 192.168.1.179 o 127.0.0.1).',
                      style: ComicTheme.bodyText(size: 10, color: Colors.amberAccent),
                    ),
                  ),
                ],
              ),
            ),

          if (_isCreatingRoom) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage ?? 'Esperando a otro jugador...',
                      textAlign: TextAlign.center,
                      style: ComicTheme.titleText(
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _handleCancelRoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: ComicTheme.panelDecoration(
                          backgroundColor: Colors.grey.shade800,
                          borderWidth: 2.5,
                          shadowOffset: 3,
                        ),
                        child: Text(
                          'CANCELAR SALA',
                          style: ComicTheme.titleText(
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Room Name Input
            Text(
              'Nombre de la sala:',
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
        ],
      ),
    );
  }
}

