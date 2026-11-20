import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Predefined manga color palette for Kaito in multiplayer mode
class MultiplayerColor {
  final String name;
  final Color primary;
  final Color accent;

  const MultiplayerColor({
    required this.name,
    required this.primary,
    required this.accent,
  });

  /// Creates a selective ColorFilter matrix that recolors ONLY Kaito's red
  /// scarf, headband, cuffs, boots, and hilt while preserving black ink outlines,
  /// dark suit shadows, and white belt/eyes (eigenvector [1,1,1] = 1).
  static ColorFilter? createSkinColorFilter(Color targetColor, {int? colorIndex}) {
    if (colorIndex == 0 || targetColor.toARGB32() == 0xFFFF2A2A) {
      return null;
    }
    double cr = targetColor.r;
    double cg = targetColor.g;
    double cb = targetColor.b;
    // Ensure Kuro Stealth (#263238) renders as a distinct charcoal-steel accent
    if (colorIndex == 7 || (cr < 0.20 && cg < 0.25 && cb < 0.28)) {
      cr = 0.28;
      cg = 0.36;
      cb = 0.46;
    }
    return ColorFilter.matrix(<double>[
      cr, 1.0 - cr, 0.0, 0.0, 0.0,
      cg, 1.0 - cg, 0.0, 0.0, 0.0,
      cb, 0.0, 1.0 - cb, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ]);
  }
}

class PvPArenaStageInfo {
  final int index;
  final String name;
  final String subtitle;
  final String flameBgAsset;
  final String widgetBgAsset;
  final Color themeColor;

  const PvPArenaStageInfo({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.flameBgAsset,
    required this.widgetBgAsset,
    required this.themeColor,
  });
}

const List<PvPArenaStageInfo> kPvpStages = [
  PvPArenaStageInfo(
    index: 0,
    name: 'DOJO DEL ECLIPSE',
    subtitle: '1 Plataforma Base (Clásica)',
    flameBgAsset: 'illustrations/bg_level5_sanctum.png',
    widgetBgAsset: 'assets/images/illustrations/bg_level5_sanctum.png',
    themeColor: Color(0xFFFF2A2A),
  ),
  PvPArenaStageInfo(
    index: 1,
    name: 'AZOTEAS NEO-TOKYO',
    subtitle: '4 Plataformas (Tri-Plataforma Aérea)',
    flameBgAsset: 'illustrations/bg_level1_rooftops.jpg',
    widgetBgAsset: 'assets/images/illustrations/bg_level1_rooftops.jpg',
    themeColor: Color(0xFF00E5FF),
  ),
  PvPArenaStageInfo(
    index: 2,
    name: 'FORTALEZA CARMESÍ',
    subtitle: '5 Plataformas (Islas Flotantes)',
    flameBgAsset: 'illustrations/bg_level2_citadel.jpg',
    widgetBgAsset: 'assets/images/illustrations/bg_level2_citadel.jpg',
    themeColor: Color(0xFFFF6D00),
  ),
];

class MultiplayerMatchConfig {
  final int stageIndex; // 0, 1, 2
  final int timeLimitSeconds; // 0 = Sin límite, 90, 120, 180, 300
  final int maxHp; // 150, 300, 500, 750
  final int lives; // 1, 2, 3, 5

  const MultiplayerMatchConfig({
    this.stageIndex = 0,
    this.timeLimitSeconds = 180,
    this.maxHp = 300,
    this.lives = 3,
  });

  static const List<int> kTimeOptions = [0, 90, 120, 180, 300];
  static const List<int> kHpOptions = [150, 300, 500, 750];
  static const List<int> kLivesOptions = [1, 2, 3, 5];

  PvPArenaStageInfo get stage =>
      kPvpStages[stageIndex.clamp(0, kPvpStages.length - 1)];

  String get formattedTimeLimit {
    if (timeLimitSeconds <= 0) return '∞';
    final m = timeLimitSeconds ~/ 60;
    final s = (timeLimitSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  MultiplayerMatchConfig copyWith({
    int? stageIndex,
    int? timeLimitSeconds,
    int? maxHp,
    int? lives,
  }) {
    return MultiplayerMatchConfig(
      stageIndex: stageIndex ?? this.stageIndex,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      maxHp: maxHp ?? this.maxHp,
      lives: lives ?? this.lives,
    );
  }

  Map<String, dynamic> toJson() => {
        'stage': stageIndex,
        'time': timeLimitSeconds,
        'maxHp': maxHp,
        'lives': lives,
      };

  factory MultiplayerMatchConfig.fromJson(Map<String, dynamic>? map) {
    if (map == null) return const MultiplayerMatchConfig();
    return MultiplayerMatchConfig(
      stageIndex: (map['stage'] as int? ?? 0).clamp(0, kPvpStages.length - 1),
      timeLimitSeconds: map['time'] as int? ?? 180,
      maxHp: (map['maxHp'] as int? ?? 300).clamp(50, 2000),
      lives: (map['lives'] as int? ?? 3).clamp(1, 10),
    );
  }
}

const List<MultiplayerColor> kMultiplayerColors = [
  MultiplayerColor(
    name: 'Crimson Classic (Original)',
    primary: Color(0xFFFF2A2A),
    accent: Color(0xFFFFD600),
  ),
  MultiplayerColor(
    name: 'Raijin Cyan (Electric Neon)',
    primary: Color(0xFF00E5FF),
    accent: Color(0xFFFFFFFF),
  ),
  MultiplayerColor(
    name: 'Yami Violet (Shadow Void)',
    primary: Color(0xFFAB47BC),
    accent: Color(0xFFFF4081),
  ),
  MultiplayerColor(
    name: 'Dokuso Emerald (Venom Viper)',
    primary: Color(0xFF00E676),
    accent: Color(0xFFB9F6CA),
  ),
  MultiplayerColor(
    name: 'Hikari Gold (Solar Sunburst)',
    primary: Color(0xFFFFD600),
    accent: Color(0xFFFF6D00),
  ),
  MultiplayerColor(
    name: 'Fubuki Silver (Arctic Frost)',
    primary: Color(0xFFB2EBF2),
    accent: Color(0xFF00BCD4),
  ),
  MultiplayerColor(
    name: 'Magma Blaze (Volcanic Flame)',
    primary: Color(0xFFFF6D00),
    accent: Color(0xFFFFD600),
  ),
  MultiplayerColor(
    name: 'Kuro Stealth (Deep Ink Black)',
    primary: Color(0xFF263238),
    accent: Color(0xFFFF5252),
  ),
];

class DiscoveredRoom {
  final String roomName;
  final String hostName;
  final int hostColorIndex;
  final String ip;
  final int port;
  final int playerCount;
  final DateTime lastSeen;

  DiscoveredRoom({
    required this.roomName,
    required this.hostName,
    required this.hostColorIndex,
    required this.ip,
    required this.port,
    this.playerCount = 1,
    required this.lastSeen,
  });
}

class MultiplayerPlayer {
  final String id;
  String nickname;
  int colorIndex;
  int slot; // 0 (Host), 1, 2, 3, 4
  bool isHost;
  bool isAlive;
  double hp;
  double maxHp;
  int lives;
  int maxLives;
  double ougi;
  int placement;
  bool votedRematch;

  MultiplayerPlayer({
    required this.id,
    required this.nickname,
    required this.colorIndex,
    required this.slot,
    this.isHost = false,
    this.isAlive = true,
    this.hp = LanMultiplayerService.kPvpMaxHp,
    this.maxHp = LanMultiplayerService.kPvpMaxHp,
    this.lives = 3,
    this.maxLives = 3,
    this.ougi = 0.0,
    this.placement = 0,
    this.votedRematch = false,
  });

  Color get color =>
      kMultiplayerColors[colorIndex.clamp(0, kMultiplayerColors.length - 1)]
          .primary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': nickname,
        'color': colorIndex,
        'slot': slot,
        'isHost': isHost,
        'isAlive': isAlive,
        'hp': hp,
        'maxHp': maxHp,
        'lives': lives,
        'maxLives': maxLives,
        'ougi': ougi,
        'placement': placement,
        'votedRematch': votedRematch,
      };

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> map) {
    final parsedMaxHp =
        (map['maxHp'] as num?)?.toDouble() ?? LanMultiplayerService.kPvpMaxHp;
    final parsedMaxLives = map['maxLives'] as int? ?? 3;
    return MultiplayerPlayer(
      id: map['id'] as String,
      nickname: map['name'] as String? ?? 'Shinobi',
      colorIndex: map['color'] as int? ?? 0,
      slot: map['slot'] as int? ?? 0,
      isHost: map['isHost'] as bool? ?? false,
      isAlive: map['isAlive'] as bool? ?? true,
      hp: (map['hp'] as num?)?.toDouble() ?? parsedMaxHp,
      maxHp: parsedMaxHp,
      lives: map['lives'] as int? ?? parsedMaxLives,
      maxLives: parsedMaxLives,
      ougi: (map['ougi'] as num?)?.toDouble() ?? 0.0,
      placement: map['placement'] as int? ?? 0,
      votedRematch: map['votedRematch'] as bool? ?? false,
    );
  }
}

enum MatchRole { none, host, client }

enum MultiplayerMode { local, online }

class OnlineRoomSummary {
  final String roomId;
  final String roomName;
  final String hostName;
  final int hostColorIndex;
  final int playerCount;
  final int maxPlayers;
  final bool inMatch;
  final MultiplayerMatchConfig config;

  OnlineRoomSummary({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    required this.hostColorIndex,
    required this.playerCount,
    this.maxPlayers = 5,
    this.inMatch = false,
    required this.config,
  });

  factory OnlineRoomSummary.fromJson(Map<String, dynamic> map) {
    return OnlineRoomSummary(
      roomId: map['roomId'] as String? ?? 'room_1',
      roomName: map['roomName'] as String? ?? 'Dojo Online',
      hostName: map['hostName'] as String? ?? 'Shinobi',
      hostColorIndex: map['hostColor'] as int? ?? 0,
      playerCount: map['playerCount'] as int? ?? 1,
      maxPlayers: map['maxPlayers'] as int? ?? 5,
      inMatch: map['inMatch'] as bool? ?? false,
      config: MultiplayerMatchConfig.fromJson(
        map['config'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Unified socket interface for Native (dart:io) and Web (web_socket_channel)
abstract class LanSocket {
  Stream<dynamic> get stream;
  void send(String data);
  Future<void> close();
}

class IoWebSocket implements LanSocket {
  final WebSocket _ws;
  IoWebSocket(this._ws);
  @override
  Stream<dynamic> get stream => _ws;
  @override
  void send(String data) => _ws.add(data);
  @override
  Future<void> close() => _ws.close();
}

class ChannelWebSocket implements LanSocket {
  final WebSocketChannel _channel;
  ChannelWebSocket(this._channel);
  @override
  Stream<dynamic> get stream => _channel.stream;
  @override
  void send(String data) => _channel.sink.add(data);
  @override
  Future<void> close() => _channel.sink.close();
}

class LanMultiplayerService {
  static final LanMultiplayerService instance = LanMultiplayerService._();
  LanMultiplayerService._();

  static const int kGamePort = 7777;
  static const int kDiscoveryPort = 7778;
  static const int kOnlineServerPort = 7779;
  static const int kOnlineDiscoveryPort = 7780;
  static const String kGlobalDiscoveryTopic =
      'kaito_adventure/janosos/online_srv_v2';
  static const List<String> kGlobalDiscoveryBrokerWsUrls = [
    'wss://broker.emqx.io:8084/mqtt',
    'wss://broker.hivemq.com:8884/mqtt',
  ];
  static const int maxPlayers = 5;
  static const double kPvpMaxHp = 300.0;
  static const int kPvpMaxHpInt = 300;
  static const int kRematchCountdownSeconds = 10;
  static const Duration kVictoryCelebrationDuration =
      Duration(milliseconds: 3200);

  // Active Multiplayer Mode: Local WiFi vs Dedicated Online PC Server
  final ValueNotifier<MultiplayerMode> modeNotifier =
      ValueNotifier<MultiplayerMode>(MultiplayerMode.local);
  MultiplayerMode get mode => modeNotifier.value;
  bool get isOnlineMode => modeNotifier.value == MultiplayerMode.online;

  // Dedicated Online Server State
  String onlineServerAddress = '127.0.0.1:7779';
  String activeOnlineServerWsUri = 'ws://127.0.0.1:7779';
  String activeOnlineServerHost = '127.0.0.1';
  int activeOnlineServerPort = kOnlineServerPort;
  String onlineServerName = 'Servidor Oficial Kaito Online';
  int onlineConnectedClients = 0;
  String? currentOnlineRoomId;
  LanSocket? _onlineLobbySocket;

  final ValueNotifier<bool> isCheckingOnlineServer = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineServerActive = ValueNotifier<bool>(false);
  final ValueNotifier<List<OnlineRoomSummary>> onlineRoomsNotifier =
      ValueNotifier<List<OnlineRoomSummary>>([]);
  final ValueNotifier<String?> onlineErrorNotifier =
      ValueNotifier<String?>(null);

  // Local Player Config
  String myPlayerId = 'p_host';
  int mySlot = 0;
  String myNickname = 'Kaito_${Random().nextInt(900) + 100}';
  int myColorIndex = 0;

  // Connection State
  MatchRole role = MatchRole.none;
  bool isConnected = false;
  String? localIpAddress;
  String currentRoomName = 'Dojo Shinobi';

  // Room & Connected Players (Up to 5)
  final Map<String, MultiplayerPlayer> roomPlayers = {};
  final ValueNotifier<List<MultiplayerPlayer>> roomPlayersNotifier =
      ValueNotifier<List<MultiplayerPlayer>>([]);

  // Match Configuration (Stage, Timer, HP Bar, Lives)
  final ValueNotifier<MultiplayerMatchConfig> matchConfigNotifier =
      ValueNotifier<MultiplayerMatchConfig>(const MultiplayerMatchConfig());
  MultiplayerMatchConfig get matchConfig => matchConfigNotifier.value;
  double get configuredMaxHp => matchConfig.maxHp.toDouble();
  int get configuredMaxHpInt => matchConfig.maxHp;
  int get configuredLives => matchConfig.lives;

  // Remaining match time (seconds) synced for HUD
  final ValueNotifier<int?> remainingSecondsNotifier =
      ValueNotifier<int?>(null);

  // Rematch & Results State
  final ValueNotifier<int?> rematchCountdownNotifier =
      ValueNotifier<int?>(null);
  final ValueNotifier<MultiplayerPlayer?> victoryCelebrationNotifier =
      ValueNotifier<MultiplayerPlayer?>(null);
  final ValueNotifier<List<MultiplayerPlayer>?> resultsPodiumNotifier =
      ValueNotifier<List<MultiplayerPlayer>?>(null);
  Timer? _rematchTimer;
  Timer? _victoryDelayTimer;
  bool _matchEnded = false;

  // Host internals (Native only)
  HttpServer? _server;
  final Map<String, LanSocket> _clientSockets = {};
  int _clientIdCounter = 1;
  RawDatagramSocket? _broadcastSocket;
  Timer? _beaconTimer;

  // Client internals
  LanSocket? _clientSocket;
  RawDatagramSocket? _discoverySocket;
  final ValueNotifier<List<DiscoveredRoom>> discoveredRooms =
      ValueNotifier<List<DiscoveredRoom>>([]);

  // Stream controller for in-game match packets
  final StreamController<Map<String, dynamic>> _matchDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMatchData => _matchDataController.stream;

  // Match state notifier & monotonic session counter (triggers fresh rematches)
  final ValueNotifier<bool> inMatchNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> matchSessionIdNotifier = ValueNotifier<int>(0);

  Color get myColor =>
      kMultiplayerColors[myColorIndex.clamp(0, kMultiplayerColors.length - 1)]
          .primary;

  Future<void> init() async {
    await refreshLocalIp();
  }

  Future<String> refreshLocalIp() async {
    if (kIsWeb) {
      localIpAddress = '127.0.0.1';
      return localIpAddress!;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            localIpAddress = addr.address;
            return addr.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        localIpAddress = interfaces.first.addresses.first.address;
        return localIpAddress!;
      }
    } catch (_) {}
    localIpAddress = '127.0.0.1';
    return localIpAddress!;
  }

  // =========================================================================
  // HOST: Create Room & Manage up to 5 Players
  // =========================================================================
  Future<bool> startHostRoom({String? roomName}) async {
    if (kIsWeb) {
      debugPrint('[LAN Host] Hosting is not supported on web browsers.');
      return false;
    }

    final savedConfig = matchConfigNotifier.value;
    await disconnect();
    modeNotifier.value = MultiplayerMode.local;
    matchConfigNotifier.value = savedConfig;
    await refreshLocalIp();

    currentRoomName = roomName?.trim().isNotEmpty == true
        ? roomName!.trim()
        : 'Dojo de $myNickname';

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, kGamePort);
      role = MatchRole.host;
      isConnected = true;
      myPlayerId = 'p_host';
      mySlot = 0;

      // Register Host as Slot 0
      roomPlayers.clear();
      roomPlayers[myPlayerId] = MultiplayerPlayer(
        id: myPlayerId,
        nickname: myNickname,
        colorIndex: myColorIndex,
        slot: 0,
        isHost: true,
        hp: configuredMaxHp,
        maxHp: configuredMaxHp,
        lives: configuredLives,
        maxLives: configuredLives,
      );
      _updateRoomPlayersNotifier();

      _server!.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers
            .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/info' || request.uri.path == '/beacon') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'type': 'kaito_beacon',
            'roomName': currentRoomName,
            'hostName': myNickname,
            'hostColor': myColorIndex,
            'ip': localIpAddress ?? '127.0.0.1',
            'port': kGamePort,
            'playerCount': roomPlayers.length,
          }));
          await request.response.close();
          return;
        }

        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          if (roomPlayers.length >= maxPlayers) {
            ws.close(1008, 'Room Full (Max 5 Players)');
            return;
          }
          _handleNewClientConnection(IoWebSocket(ws));
        }
      });

      // UDP Beacon for Local WiFi Room Discovery
      try {
        _broadcastSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
        );
        _broadcastSocket!.broadcastEnabled = true;

        _beaconTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
          final beaconData = jsonEncode({
            'type': 'kaito_beacon',
            'roomName': currentRoomName,
            'hostName': myNickname,
            'hostColor': myColorIndex,
            'ip': localIpAddress ?? '127.0.0.1',
            'port': kGamePort,
            'playerCount': roomPlayers.length,
          });
          final bytes = utf8.encode(beaconData);
          _broadcastSocket?.send(
            bytes,
            InternetAddress('255.255.255.255'),
            kDiscoveryPort,
          );
        });
      } catch (e) {
        debugPrint('[LAN Host] UDP Beacon error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[LAN Host] Failed to bind server: $e');
      await disconnect();
      return false;
    }
  }

  void _handleNewClientConnection(LanSocket socket) {
    String? assignedId;

    socket.stream.listen(
      (data) {
        try {
          final text = data is String ? data : utf8.decode(data as List<int>);
          final map = jsonDecode(text) as Map<String, dynamic>;
          final type = map['type'] as String?;

          if (type == 'handshake') {
            if (roomPlayers.length >= maxPlayers) {
              socket.send(jsonEncode({'type': 'error', 'msg': 'Sala llena'}));
              socket.close();
              return;
            }

            assignedId = 'p_${_clientIdCounter++}';
            final clientName = map['name'] as String? ?? 'Shinobi';
            final clientColor = map['color'] as int? ?? 1;

            // Find lowest available slot among 1..4
            int slot = 1;
            final occupiedSlots = roomPlayers.values.map((p) => p.slot).toSet();
            for (int s = 1; s < maxPlayers; s++) {
              if (!occupiedSlots.contains(s)) {
                slot = s;
                break;
              }
            }

            final newPlayer = MultiplayerPlayer(
              id: assignedId!,
              nickname: clientName,
              colorIndex: clientColor,
              slot: slot,
              isHost: false,
              hp: configuredMaxHp,
              maxHp: configuredMaxHp,
              lives: configuredLives,
              maxLives: configuredLives,
            );

            _clientSockets[assignedId!] = socket;
            roomPlayers[assignedId!] = newPlayer;
            _updateRoomPlayersNotifier();

            // 1. Send Welcome packet to the connected client
            socket.send(jsonEncode({
              'type': 'welcome',
              'yourId': assignedId,
              'slot': slot,
              'roomName': currentRoomName,
              'config': matchConfig.toJson(),
              'players': roomPlayers.values.map((p) => p.toJson()).toList(),
            }));

            // 2. Broadcast updated lobby list to ALL clients
            _broadcastToClients({
              'type': 'lobby_update',
              'config': matchConfig.toJson(),
              'players': roomPlayers.values.map((p) => p.toJson()).toList(),
            });
          } else {
            // In-game packets or lobby actions from this client
            _handleClientPacket(assignedId, map);
          }
        } catch (_) {}
      },
      onDone: () {
        if (assignedId != null) {
          _removeClient(assignedId!);
        }
      },
      onError: (_) {
        if (assignedId != null) {
          _removeClient(assignedId!);
        }
      },
    );
  }

  void _removeClient(String clientId) {
    _clientSockets.remove(clientId);
    final removed = roomPlayers.remove(clientId);
    _updateRoomPlayersNotifier();

    if (removed != null) {
      _broadcastToClients({
        'type': 'lobby_update',
        'players': roomPlayers.values.map((p) => p.toJson()).toList(),
      });

      // If in match, check if only 1 player remains
      if (inMatchNotifier.value) {
        _checkMatchEndCondition();
      }
      // If on results/rematch screen, re-evaluate whether >= 2 ready players remain
      if (resultsPodiumNotifier.value != null || _rematchTimer != null) {
        _checkRematchVoteCondition();
      }
    }
  }

  @visibleForTesting
  void debugInjectClientPacket(String senderId, Map<String, dynamic> map) =>
      _handleClientPacket(senderId, map);

  void updateMatchConfig({
    int? stageIndex,
    int? timeLimitSeconds,
    int? maxHp,
    int? lives,
  }) {
    matchConfigNotifier.value = matchConfig.copyWith(
      stageIndex: stageIndex,
      timeLimitSeconds: timeLimitSeconds,
      maxHp: maxHp,
      lives: lives,
    );
    final hpVal = configuredMaxHp;
    final livesVal = configuredLives;
    for (final p in roomPlayers.values) {
      p.hp = hpVal;
      p.maxHp = hpVal;
      p.lives = livesVal;
      p.maxLives = livesVal;
    }
    _updateRoomPlayersNotifier();
    if (role == MatchRole.host && isConnected) {
      if (isOnlineMode) {
        sendRaw({
          'type': 'config_update',
          'config': matchConfig.toJson(),
        });
      } else {
        _broadcastToClients({
          'type': 'config_update',
          'config': matchConfig.toJson(),
          'players': roomPlayers.values.map((p) => p.toJson()).toList(),
        });
      }
    }
  }

  void _handleClientPacket(String? senderId, Map<String, dynamic> map) {
    final type = map['type'] as String?;
    final packetSession = map['sessionId'] as int?;
    if (packetSession != null &&
        packetSession != matchSessionIdNotifier.value &&
        type != 'rematch_vote') {
      // Discard stale packet from a previous match session
      return;
    }

    if (type == 'state') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        final rp = roomPlayers[pid]!;
        if (!rp.isAlive) {
          rp.hp = 0.0;
        } else {
          final incomingHp =
              (map['hp'] as num?)?.toDouble() ?? configuredMaxHp;
          // No health regeneration in multiplayer: HP only moves downward on the same life.
          if (incomingHp.isFinite && incomingHp < rp.hp) {
            rp.hp = incomingHp.clamp(0.0, rp.maxHp);
          }
        }
        rp.ougi = (map['ougi'] as num?)?.toDouble() ?? 0.0;
      }
      // Re-broadcast state to all OTHER clients
      _broadcastToClients(map, excludeClientId: senderId);
      // Emit locally for Host's game world
      _matchDataController.add(map);
    } else if (type == 'player_action') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'spawn_kunai') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'hit') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'ring_out_blast') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'player_stock_lost') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        final rp = roomPlayers[pid]!;
        final newLives = map['lives'] as int? ?? (rp.lives - 1);
        rp.lives = newLives.clamp(0, rp.maxLives);
        rp.hp = rp.maxHp;
        _updateRoomPlayersNotifier();
      }
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'player_eliminated') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        final deadPlayer = roomPlayers[pid]!;
        deadPlayer.hp = 0.0;
        deadPlayer.lives = 0;
        if (deadPlayer.isAlive) {
          deadPlayer.isAlive = false;
          final aliveCount = roomPlayers.values.where((p) => p.isAlive).length;
          deadPlayer.placement = aliveCount + 1;

          final elimPacket = {
            'type': 'player_eliminated',
            'sessionId': matchSessionIdNotifier.value,
            'id': pid,
            'nickname': deadPlayer.nickname,
            'placement': deadPlayer.placement,
          };
          _broadcastToClients(elimPacket);
          _matchDataController.add(elimPacket);
          _updateRoomPlayersNotifier();

          _checkMatchEndCondition();
        }
      }
    } else if (type == 'rematch_vote') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        final voted = map['voted'] as bool? ?? !roomPlayers[pid]!.votedRematch;
        roomPlayers[pid]!.votedRematch = voted;
        _updateRoomPlayersNotifier();
        _broadcastRematchStatus();
        _checkRematchVoteCondition();
      }
    }
  }

  /// Host triggers match start (or rematch) for all connected players
  void hostStartMatch() {
    if (role != MatchRole.host || roomPlayers.length < 2) return;
    if (isOnlineMode) {
      sendRaw({'type': 'host_start_match'});
      return;
    }

    _rematchTimer?.cancel();
    _rematchTimer = null;
    _victoryDelayTimer?.cancel();
    _victoryDelayTimer = null;
    _matchEnded = false;

    rematchCountdownNotifier.value = null;
    victoryCelebrationNotifier.value = null;
    resultsPodiumNotifier.value = null;
    remainingSecondsNotifier.value =
        matchConfig.timeLimitSeconds > 0 ? matchConfig.timeLimitSeconds : null;

    final maxHpVal = configuredMaxHp;
    final livesVal = configuredLives;

    // Reset combat state for all room players
    for (final p in roomPlayers.values) {
      p.isAlive = true;
      p.hp = maxHpVal;
      p.maxHp = maxHpVal;
      p.lives = livesVal;
      p.maxLives = livesVal;
      p.ougi = 0.0;
      p.placement = 0;
      p.votedRematch = false;
    }
    _updateRoomPlayersNotifier();

    final nextSessionId = matchSessionIdNotifier.value + 1;
    final startPacket = {
      'type': 'match_start',
      'sessionId': nextSessionId,
      'config': matchConfig.toJson(),
      'players': roomPlayers.values.map((p) => p.toJson()).toList(),
    };
    _broadcastToClients(startPacket);
    matchSessionIdNotifier.value = nextSessionId;
    inMatchNotifier.value = true;
  }

  /// Host resolves match when battle timer reaches 00:00
  void hostTriggerTimeUp() {
    if (role != MatchRole.host || !inMatchNotifier.value || _matchEnded) return;
    if (isOnlineMode) {
      sendRaw({
        'type': 'time_up',
        'sessionId': matchSessionIdNotifier.value,
      });
      return;
    }
    _matchEnded = true;

    // Rank alive players by remaining lives descending, then HP descending
    final alive = roomPlayers.values.where((p) => p.isAlive).toList()
      ..sort((a, b) {
        final lifeCmp = b.lives.compareTo(a.lives);
        if (lifeCmp != 0) return lifeCmp;
        return b.hp.compareTo(a.hp);
      });

    for (int i = 0; i < alive.length; i++) {
      alive[i].placement = i + 1;
      if (i > 0) {
        alive[i].isAlive = false;
      }
    }

    final podium = roomPlayers.values.toList()
      ..sort((a, b) {
        final pa = a.placement <= 0 ? 999 : a.placement;
        final pb = b.placement <= 0 ? 999 : b.placement;
        return pa.compareTo(pb);
      });
    if (podium.isNotEmpty && podium.first.placement != 1) {
      podium.first.placement = 1;
    }
    final winner = podium.firstOrNull;
    _updateRoomPlayersNotifier();

    final victoryPacket = {
      'type': 'match_victory',
      'winner': winner?.toJson(),
    };
    _broadcastToClients(victoryPacket);
    victoryCelebrationNotifier.value = winner;

    final resultsPacket = {
      'type': 'match_results',
      'podium': podium.map((p) => p.toJson()).toList(),
    };

    _victoryDelayTimer?.cancel();
    _victoryDelayTimer = Timer(kVictoryCelebrationDuration, () {
      _victoryDelayTimer = null;
      if (role != MatchRole.host || !inMatchNotifier.value) return;
      victoryCelebrationNotifier.value = null;
      _broadcastToClients(resultsPacket);
      resultsPodiumNotifier.value = podium;
    });
  }

  void _checkMatchEndCondition() {
    if (role != MatchRole.host || !inMatchNotifier.value || _matchEnded) return;

    final alive = roomPlayers.values.where((p) => p.isAlive).toList();
    if (alive.length <= 1) {
      _matchEnded = true;
      MultiplayerPlayer? winner;
      if (alive.length == 1) {
        alive.first.placement = 1;
        winner = alive.first;
      }

      // Sort podium by placement ascending (1st place first)
      final podium = roomPlayers.values.toList()
        ..sort((a, b) {
          final pa = a.placement <= 0 ? 999 : a.placement;
          final pb = b.placement <= 0 ? 999 : b.placement;
          return pa.compareTo(pb);
        });
      if (podium.isNotEmpty && podium.first.placement != 1) {
        podium.first.placement = 1;
      }
      winner ??= podium.firstOrNull;

      // Announce champion immediately for post-KO celebration before podium
      final victoryPacket = {
        'type': 'match_victory',
        'winner': winner?.toJson(),
      };
      _broadcastToClients(victoryPacket);
      victoryCelebrationNotifier.value = winner;

      final resultsPacket = {
        'type': 'match_results',
        'podium': podium.map((p) => p.toJson()).toList(),
      };

      _victoryDelayTimer?.cancel();
      _victoryDelayTimer = Timer(kVictoryCelebrationDuration, () {
        _victoryDelayTimer = null;
        if (role != MatchRole.host || !inMatchNotifier.value) return;
        victoryCelebrationNotifier.value = null;
        _broadcastToClients(resultsPacket);
        resultsPodiumNotifier.value = podium;
      });
    }
  }

  void _broadcastRematchStatus() {
    final packet = {
      'type': 'rematch_update',
      'players': roomPlayers.values.map((p) => p.toJson()).toList(),
    };
    _broadcastToClients(packet);
  }

  void _cancelRematchTimer() {
    _rematchTimer?.cancel();
    _rematchTimer = null;
    if (rematchCountdownNotifier.value != null) {
      rematchCountdownNotifier.value = null;
      _broadcastToClients({
        'type': 'rematch_countdown',
        'seconds': null,
      });
    }
  }

  void _checkRematchVoteCondition() {
    if (role != MatchRole.host) return;

    final readyCount =
        roomPlayers.values.where((p) => p.votedRematch).length;

    if (readyCount < 2 || roomPlayers.length < 2) {
      _cancelRematchTimer();
      return;
    }

    if (_rematchTimer == null) {
      int seconds = kRematchCountdownSeconds;
      rematchCountdownNotifier.value = seconds;
      _broadcastToClients({
        'type': 'rematch_countdown',
        'seconds': seconds,
      });

      _rematchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentReady =
            roomPlayers.values.where((p) => p.votedRematch).length;
        if (currentReady < 2 || roomPlayers.length < 2) {
          timer.cancel();
          _rematchTimer = null;
          rematchCountdownNotifier.value = null;
          _broadcastToClients({
            'type': 'rematch_countdown',
            'seconds': null,
          });
          return;
        }

        seconds--;
        if (seconds <= 0) {
          timer.cancel();
          _rematchTimer = null;
          hostStartMatch();
        } else {
          rematchCountdownNotifier.value = seconds;
          _broadcastToClients({
            'type': 'rematch_countdown',
            'seconds': seconds,
          });
        }
      });
    }
  }

  void _broadcastToClients(Map<String, dynamic> data,
      {String? excludeClientId}) {
    final jsonStr = jsonEncode(data);
    for (final entry in _clientSockets.entries) {
      if (entry.key != excludeClientId) {
        try {
          entry.value.send(jsonStr);
        } catch (_) {}
      }
    }
  }

  // =========================================================================
  // CLIENT: Discovery & Connect
  // =========================================================================
  Future<void> startRoomDiscovery() async {
    stopRoomDiscovery();
    discoveredRooms.value = [];

    if (kIsWeb) return;

    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kDiscoveryPort,
        reuseAddress: true,
      );
      _discoverySocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            try {
              final text = utf8.decode(datagram.data);
              final map = jsonDecode(text) as Map<String, dynamic>;
              if (map['type'] == 'kaito_beacon') {
                final ip = map['ip'] as String? ?? datagram.address.address;
                final port = map['port'] as int? ?? kGamePort;
                final roomName = map['roomName'] as String? ?? 'Sala WiFi';
                final hostName = map['hostName'] as String? ?? 'Host';
                final hostColor = map['hostColor'] as int? ?? 0;
                final pCount = map['playerCount'] as int? ?? 1;

                final existing =
                    List<DiscoveredRoom>.from(discoveredRooms.value);
                final idx =
                    existing.indexWhere((r) => r.ip == ip && r.port == port);
                final room = DiscoveredRoom(
                  roomName: roomName,
                  hostName: hostName,
                  hostColorIndex: hostColor,
                  ip: ip,
                  port: port,
                  playerCount: pCount,
                  lastSeen: DateTime.now(),
                );

                if (idx >= 0) {
                  existing[idx] = room;
                } else {
                  existing.add(room);
                }
                discoveredRooms.value = existing;
              }
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      debugPrint('[LAN Discovery] Error: $e');
    }
  }

  void stopRoomDiscovery() {
    if (!kIsWeb) {
      try {
        _discoverySocket?.close();
      } catch (_) {}
    }
    _discoverySocket = null;
  }

  Future<bool> connectToRoom(String ip, [int port = kGamePort]) async {
    await disconnect();
    modeNotifier.value = MultiplayerMode.local;
    role = MatchRole.client;

    String cleanIp = ip.trim();
    int actualPort = port;
    if (cleanIp.contains(':')) {
      final parts = cleanIp.split(':');
      cleanIp = parts[0].trim();
      actualPort = int.tryParse(parts[1].trim()) ?? port;
    }

    try {
      final wsUri = Uri.parse('ws://$cleanIp:$actualPort');
      final channel = WebSocketChannel.connect(wsUri);
      await channel.ready.timeout(const Duration(seconds: 5));

      _clientSocket = ChannelWebSocket(channel);
      isConnected = true;

      // Send Handshake
      _clientSocket!.send(jsonEncode({
        'type': 'handshake',
        'name': myNickname,
        'color': myColorIndex,
      }));

      _attachClientStreamListener();

      return true;
    } catch (e) {
      debugPrint('[LAN Client] Connection failed: $e');
      await disconnect();
      return false;
    }
  }

  // =========================================================================
  // ONLINE DEDICATED SERVER: Mode Switch, Status Check, Rooms & Join/Create
  // =========================================================================
  void setMultiplayerMode(MultiplayerMode nextMode) {
    if (modeNotifier.value == nextMode) return;
    modeNotifier.value = nextMode;
  }

  (String, int) _parseAddress(String raw, [int defaultPort = kOnlineServerPort]) {
    String clean = raw
        .trim()
        .replaceFirst(RegExp(r'^ws://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^wss://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^http://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^https://', caseSensitive: false), '');
    if (clean.contains('/')) {
      clean = clean.split('/').first.trim();
    }
    if (clean.isEmpty) {
      return ('127.0.0.1', defaultPort);
    }
    if (clean.contains(':')) {
      final parts = clean.split(':');
      final h = parts[0].trim().isEmpty ? '127.0.0.1' : parts[0].trim();
      final p = int.tryParse(parts[1].trim()) ?? defaultPort;
      return (h, p);
    }
    return (clean, defaultPort);
  }

  Future<void> _closeOnlineLobbySocket() async {
    final old = _onlineLobbySocket;
    _onlineLobbySocket = null;
    if (old != null) {
      try {
        await old.close();
      } catch (_) {}
    }
  }

  Future<(String, int)?> _discoverOnlineServerViaUdp() async {
    if (kIsWeb) return null;
    RawDatagramSocket? udp;
    final completer = Completer<(String, int)?>();
    try {
      udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udp.broadcastEnabled = true;

      udp.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = udp?.receive();
          if (dg != null && !completer.isCompleted) {
            try {
              final text = utf8.decode(dg.data);
              final map = jsonDecode(text) as Map<String, dynamic>;
              if (map['type'] == 'kaito_online_server_beacon') {
                final ip = map['ip'] as String? ?? dg.address.address;
                final port = map['port'] as int? ?? kOnlineServerPort;
                completer.complete((ip, port));
              }
            } catch (_) {}
          }
        }
      });

      final discoverPayload = utf8.encode(jsonEncode({
        'type': 'kaito_online_discover',
      }));
      try {
        udp.send(
          discoverPayload,
          InternetAddress('127.0.0.1'),
          kOnlineDiscoveryPort,
        );
      } catch (_) {}
      try {
        udp.send(
          discoverPayload,
          InternetAddress('255.255.255.255'),
          kOnlineDiscoveryPort,
        );
      } catch (_) {}

      return await completer.future.timeout(
        const Duration(milliseconds: 380),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      try {
        udp?.close();
      } catch (_) {}
    }
  }

  /// Queries the global MQTT-over-WebSocket retained discovery topic
  /// to automatically find the active public WSS tunnel of the PC running `INICIAR_SERVIDOR_ONLINE.bat`.
  Future<String?> _discoverGlobalOnlineServerWsUrl() async {
    for (final brokerUrl in kGlobalDiscoveryBrokerWsUrls) {
      final res = await _queryMqttBrokerForBeacon(brokerUrl);
      if (res != null) {
        return res.isNotEmpty ? res : null;
      }
    }
    return null;
  }

  Future<String?> _queryMqttBrokerForBeacon(String brokerWsUrl) async {
    WebSocketChannel? channel;
    StreamSubscription? sub;
    final completer = Completer<String?>();
    Timer? settleTimer;

    void finish([String? result]) {
      settleTimer?.cancel();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    try {
      channel = WebSocketChannel.connect(
        Uri.parse(brokerWsUrl),
        protocols: const ['mqtt'],
      );
      await channel.ready.timeout(const Duration(milliseconds: 2500));

      final clientIdBytes =
          utf8.encode('kaito_c_${Random().nextInt(899999) + 100000}');
      final topicBytes = utf8.encode(kGlobalDiscoveryTopic);

      // 1. MQTT CONNECT Packet (3.1.1, Clean Session)
      final connectPkt = Uint8List.fromList([
        0x10,
        12 + clientIdBytes.length,
        0x00,
        0x04,
        0x4D,
        0x51,
        0x54,
        0x54,
        0x04,
        0x02,
        0x00,
        0x1E,
        (clientIdBytes.length >> 8) & 0xFF,
        clientIdBytes.length & 0xFF,
        ...clientIdBytes,
      ]);

      // 2. MQTT SUBSCRIBE Packet (Packet ID = 1, QoS 0)
      final subPkt = Uint8List.fromList([
        0x82,
        5 + topicBytes.length,
        0x00,
        0x01,
        (topicBytes.length >> 8) & 0xFF,
        topicBytes.length & 0xFF,
        ...topicBytes,
        0x00,
      ]);

      sub = channel.stream.listen(
        (data) {
          try {
            final bytes =
                data is List<int> ? data : utf8.encode(data.toString());
            if (bytes.isEmpty) return;
            final packetType = bytes[0] & 0xF0;

            final text = utf8.decode(bytes, allowMalformed: true);
            final startIdx = text.indexOf('{"type":"kaito_online_beacon"');
            final endIdx = text.lastIndexOf('}');
            if (startIdx >= 0 && endIdx > startIdx) {
              final jsonStr = text.substring(startIdx, endIdx + 1);
              final map = jsonDecode(jsonStr) as Map<String, dynamic>;
              final active = map['active'] as bool? ?? false;
              final wsUrl = (map['wsUrl'] as String? ?? '').trim();
              finish(active && wsUrl.isNotEmpty ? wsUrl : '');
              return;
            }

            if (packetType == 0x20) {
              // CONNACK received -> send SUBSCRIBE
              channel?.sink.add(subPkt);
            } else if (packetType == 0x90) {
              // SUBACK received -> if no retained message arrives within 700ms, topic is empty
              settleTimer?.cancel();
              settleTimer =
                  Timer(const Duration(milliseconds: 700), () => finish(''));
            }
          } catch (_) {}
        },
        onDone: () => finish(null),
        onError: (_) => finish(null),
      );

      channel.sink.add(connectPkt);

      return await completer.future.timeout(
        const Duration(milliseconds: 2500),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      settleTimer?.cancel();
      try {
        channel?.sink.add(Uint8List.fromList([0xE0, 0x00]));
      } catch (_) {}
      try {
        await sub?.cancel();
      } catch (_) {}
      try {
        await channel?.sink.close();
      } catch (_) {}
    }
  }

  /// Checks if the portable PC Online Server (`INICIAR_SERVIDOR_ONLINE.bat`) is active
  /// (globally across the Internet via its automatic WSS tunnel, or locally on the same PC/LAN),
  /// and subscribes to live room list updates when found.
  Future<bool> refreshOnlineServer({String? customAddress}) async {
    await _closeOnlineLobbySocket();
    isCheckingOnlineServer.value = true;
    onlineErrorNotifier.value = null;

    final candidateWsUris = <String>[];
    void addWsCandidate(String uriStr) {
      final clean = uriStr.trim();
      if (clean.isEmpty) return;
      if (!candidateWsUris.contains(clean)) {
        candidateWsUris.add(clean);
      }
    }

    // 1. If a custom address was explicitly provided
    if (customAddress != null && customAddress.trim().isNotEmpty) {
      final raw = customAddress.trim();
      if (raw.startsWith('ws://') || raw.startsWith('wss://')) {
        addWsCandidate(raw);
      } else {
        final parsed = _parseAddress(raw);
        addWsCandidate('ws://${parsed.$1}:${parsed.$2}');
      }
    }

    // 2. Global automatic discovery via the PC Server's outbound WSS tunnel (works anywhere over Internet!)
    final globalTunnelWsUrl = await _discoverGlobalOnlineServerWsUrl();
    if (globalTunnelWsUrl != null && globalTunnelWsUrl.isNotEmpty) {
      addWsCandidate(globalTunnelWsUrl);
    }

    // 3. Same-PC & Local LAN fallback check
    if (!kIsWeb) {
      addWsCandidate('ws://127.0.0.1:$kOnlineServerPort');
      final udpDiscovered = await _discoverOnlineServerViaUdp();
      if (udpDiscovered != null) {
        addWsCandidate('ws://${udpDiscovered.$1}:${udpDiscovered.$2}');
      }
    } else {
      addWsCandidate('ws://127.0.0.1:$kOnlineServerPort');
    }

    for (final wsUriStr in candidateWsUris) {
      final ok = await _tryConnectOnlineLobbySocketUri(wsUriStr);
      if (ok) {
        activeOnlineServerWsUri = wsUriStr;
        final uri = Uri.tryParse(wsUriStr);
        activeOnlineServerHost = uri?.host ?? '127.0.0.1';
        activeOnlineServerPort =
            (uri != null && uri.hasPort) ? uri.port : kOnlineServerPort;
        onlineServerAddress = activeOnlineServerHost;
        isOnlineServerActive.value = true;
        isCheckingOnlineServer.value = false;
        return true;
      }
    }

    isOnlineServerActive.value = false;
    onlineRoomsNotifier.value = [];
    isCheckingOnlineServer.value = false;
    return false;
  }

  Future<bool> _tryConnectOnlineLobbySocketUri(String wsUriStr) async {
    LanSocket? socket;
    final firstPacketCompleter = Completer<bool>();
    final isLocalhost = wsUriStr.contains('127.0.0.1') ||
        wsUriStr.contains('localhost');
    final connectTimeout = Duration(milliseconds: isLocalhost ? 1200 : 5000);
    final packetTimeout = Duration(milliseconds: isLocalhost ? 1200 : 4000);
    try {
      final wsUri = Uri.parse(wsUriStr);
      final channel = WebSocketChannel.connect(wsUri);
      await channel.ready.timeout(connectTimeout);
      socket = ChannelWebSocket(channel);

      socket.stream.listen(
        (data) {
          try {
            final text = data is String ? data : utf8.decode(data as List<int>);
            final map = jsonDecode(text) as Map<String, dynamic>;
            final type = map['type'] as String?;
            if (type == 'online_rooms_list' || type == 'kaito_online_status') {
              _handleOnlineRoomsListPacket(map);
              if (!firstPacketCompleter.isCompleted) {
                firstPacketCompleter.complete(true);
              }
            }
          } catch (_) {}
        },
        onDone: () {
          if (_onlineLobbySocket == socket) {
            _onlineLobbySocket = null;
            if (!isConnected) {
              isOnlineServerActive.value = false;
              onlineRoomsNotifier.value = [];
            }
          }
          if (!firstPacketCompleter.isCompleted) {
            firstPacketCompleter.complete(false);
          }
        },
        onError: (_) {
          if (_onlineLobbySocket == socket) {
            _onlineLobbySocket = null;
            if (!isConnected) {
              isOnlineServerActive.value = false;
              onlineRoomsNotifier.value = [];
            }
          }
          if (!firstPacketCompleter.isCompleted) {
            firstPacketCompleter.complete(false);
          }
        },
      );

      socket.send(jsonEncode({'type': 'online_get_rooms'}));

      final confirmed = await firstPacketCompleter.future.timeout(
        packetTimeout,
        onTimeout: () => false,
      );

      if (confirmed) {
        _onlineLobbySocket = socket;
        return true;
      } else {
        await socket.close();
        return false;
      }
    } catch (_) {
      try {
        await socket?.close();
      } catch (_) {}
      return false;
    }
  }

  void _handleOnlineRoomsListPacket(Map<String, dynamic> map) {
    onlineServerName =
        map['serverName'] as String? ?? 'Servidor Oficial Kaito Online';
    onlineConnectedClients = map['connectedClients'] as int? ?? 0;
    final rawRooms = map['rooms'] as List<dynamic>? ?? const [];
    onlineRoomsNotifier.value = rawRooms
        .whereType<Map<String, dynamic>>()
        .map(OnlineRoomSummary.fromJson)
        .toList();
    isOnlineServerActive.value = true;
  }

  /// Creates a new multiplayer room on the dedicated PC Online Server
  Future<bool> createOnlineRoom({String? roomName}) async {
    currentRoomName = roomName?.trim().isNotEmpty == true
        ? roomName!.trim()
        : 'Dojo Online de $myNickname';

    return _connectToOnlineServerForRoom({
      'type': 'online_create_room',
      'roomName': currentRoomName,
      'name': myNickname,
      'color': myColorIndex,
      'config': matchConfig.toJson(),
    });
  }

  /// Joins an existing room (or quick-joins if roomId is null/empty) on the PC Online Server
  Future<bool> joinOnlineRoom({String? roomId}) async {
    return _connectToOnlineServerForRoom({
      'type': 'online_join_room',
      'roomId': roomId ?? '',
      'name': myNickname,
      'color': myColorIndex,
      'config': matchConfig.toJson(),
    });
  }

  Future<bool> _connectToOnlineServerForRoom(
      Map<String, dynamic> handshakePayload) async {
    final savedConfig = matchConfigNotifier.value;
    final savedWsUri = activeOnlineServerWsUri;
    final savedHost = activeOnlineServerHost;
    final savedPort = activeOnlineServerPort;
    final savedAddress = onlineServerAddress;

    await _closeOnlineLobbySocket();
    await disconnect(keepMode: true);

    modeNotifier.value = MultiplayerMode.online;
    matchConfigNotifier.value = savedConfig;
    activeOnlineServerWsUri = savedWsUri;
    activeOnlineServerHost = savedHost;
    activeOnlineServerPort = savedPort;
    onlineServerAddress = savedAddress;
    onlineErrorNotifier.value = null;

    final welcomeCompleter = Completer<bool>();

    try {
      final wsUri = Uri.parse(activeOnlineServerWsUri);
      final channel = WebSocketChannel.connect(wsUri);
      await channel.ready.timeout(const Duration(seconds: 4));

      _clientSocket = ChannelWebSocket(channel);
      isConnected = true;
      role = handshakePayload['type'] == 'online_create_room'
          ? MatchRole.host
          : MatchRole.client;

      _attachClientStreamListener(welcomeCompleter: welcomeCompleter);
      _clientSocket!.send(jsonEncode(handshakePayload));

      final ok = await welcomeCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );

      if (!ok) {
        final err = onlineErrorNotifier.value;
        await disconnect(keepMode: true);
        onlineErrorNotifier.value = err;
        await refreshOnlineServer();
        return false;
      }

      isOnlineServerActive.value = true;
      return true;
    } catch (e) {
      debugPrint('[Online Server] Failed to connect to room: $e');
      await disconnect(keepMode: true);
      isOnlineServerActive.value = false;
      onlineRoomsNotifier.value = [];
      onlineErrorNotifier.value =
          'No hay servidor online activado o se perdió la conexión.';
      return false;
    }
  }

  void _attachClientStreamListener({Completer<bool>? welcomeCompleter}) {
    _clientSocket?.stream.listen(
      (data) {
        try {
          final text = data is String ? data : utf8.decode(data as List<int>);
          final map = jsonDecode(text) as Map<String, dynamic>;
          final type = map['type'] as String?;

          if (type == 'welcome') {
            myPlayerId = map['yourId'] as String;
            mySlot = map['slot'] as int? ?? 1;
            currentOnlineRoomId = map['roomId'] as String?;
            currentRoomName = map['roomName'] as String? ?? 'Dojo';
            if (isOnlineMode) {
              final isMeHost = map['isHost'] as bool? ?? (mySlot == 0);
              role = isMeHost ? MatchRole.host : MatchRole.client;
            }
            if (map['config'] != null) {
              matchConfigNotifier.value = MultiplayerMatchConfig.fromJson(
                  map['config'] as Map<String, dynamic>);
            }
            final pList = (map['players'] as List<dynamic>)
                .map((e) =>
                    MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                .toList();
            roomPlayers.clear();
            for (final p in pList) {
              roomPlayers[p.id] = p;
            }
            _updateRoomPlayersNotifier();
            if (welcomeCompleter != null && !welcomeCompleter.isCompleted) {
              welcomeCompleter.complete(true);
            }
          } else if (type == 'error') {
            onlineErrorNotifier.value =
                map['msg'] as String? ?? 'No se pudo entrar a la sala.';
            if (welcomeCompleter != null && !welcomeCompleter.isCompleted) {
              welcomeCompleter.complete(false);
            }
          } else if (type == 'online_rooms_list') {
            _handleOnlineRoomsListPacket(map);
          } else if (type == 'lobby_update' || type == 'config_update') {
            if (map['config'] != null) {
              matchConfigNotifier.value = MultiplayerMatchConfig.fromJson(
                  map['config'] as Map<String, dynamic>);
            }
            if (map['players'] != null) {
              final pList = (map['players'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              roomPlayers.clear();
              for (final p in pList) {
                roomPlayers[p.id] = p;
              }
              if (isOnlineMode && roomPlayers.containsKey(myPlayerId)) {
                role = roomPlayers[myPlayerId]!.isHost
                    ? MatchRole.host
                    : MatchRole.client;
              }
              _updateRoomPlayersNotifier();
            }
          } else if (type == 'match_start') {
            if (map['config'] != null) {
              matchConfigNotifier.value = MultiplayerMatchConfig.fromJson(
                  map['config'] as Map<String, dynamic>);
            }
            final pList = (map['players'] as List<dynamic>)
                .map((e) =>
                    MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                .toList();
            roomPlayers.clear();
            for (final p in pList) {
              roomPlayers[p.id] = p;
            }
            if (isOnlineMode && roomPlayers.containsKey(myPlayerId)) {
              role = roomPlayers[myPlayerId]!.isHost
                  ? MatchRole.host
                  : MatchRole.client;
            }
            _updateRoomPlayersNotifier();
            victoryCelebrationNotifier.value = null;
            resultsPodiumNotifier.value = null;
            rematchCountdownNotifier.value = null;
            remainingSecondsNotifier.value = matchConfig.timeLimitSeconds > 0
                ? matchConfig.timeLimitSeconds
                : null;
            final incomingSession = map['sessionId'] as int?;
            if (incomingSession != null &&
                incomingSession > matchSessionIdNotifier.value) {
              matchSessionIdNotifier.value = incomingSession;
            } else {
              matchSessionIdNotifier.value =
                  matchSessionIdNotifier.value + 1;
            }
            inMatchNotifier.value = true;
          } else if (type == 'match_victory') {
            final wMap = map['winner'] as Map<String, dynamic>?;
            victoryCelebrationNotifier.value =
                wMap != null ? MultiplayerPlayer.fromJson(wMap) : null;
          } else if (type == 'player_stock_lost') {
            final pid = map['id'] as String?;
            if (pid != null && roomPlayers.containsKey(pid)) {
              final rp = roomPlayers[pid]!;
              rp.lives =
                  (map['lives'] as int? ?? (rp.lives - 1)).clamp(0, rp.maxLives);
              rp.hp = rp.maxHp;
              _updateRoomPlayersNotifier();
            }
            _matchDataController.add(map);
          } else if (type == 'player_eliminated') {
            final pid = map['id'] as String?;
            if (pid != null && roomPlayers.containsKey(pid)) {
              roomPlayers[pid]!.isAlive = false;
              roomPlayers[pid]!.hp = 0.0;
              roomPlayers[pid]!.lives = 0;
              roomPlayers[pid]!.placement = map['placement'] as int? ?? 0;
              _updateRoomPlayersNotifier();
            }
            _matchDataController.add(map);
          } else if (type == 'match_results') {
            final podium = (map['podium'] as List<dynamic>)
                .map((e) =>
                    MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                .toList();
            victoryCelebrationNotifier.value = null;
            resultsPodiumNotifier.value = podium;
          } else if (type == 'rematch_update') {
            final pList = (map['players'] as List<dynamic>)
                .map((e) =>
                    MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                .toList();
            final incomingIds = pList.map((e) => e.id).toSet();
            roomPlayers.removeWhere((k, _) => !incomingIds.contains(k));
            for (final p in pList) {
              roomPlayers[p.id] = p;
            }
            _updateRoomPlayersNotifier();
          } else if (type == 'rematch_countdown') {
            rematchCountdownNotifier.value = map['seconds'] as int?;
          } else {
            final packetSession = map['sessionId'] as int?;
            if (packetSession == null ||
                packetSession == matchSessionIdNotifier.value) {
              _matchDataController.add(map);
            }
          }
        } catch (_) {}
      },
      onDone: () {
        if (welcomeCompleter != null && !welcomeCompleter.isCompleted) {
          welcomeCompleter.complete(false);
        }
        final wasOnline = isOnlineMode;
        disconnect(keepMode: true).then((_) {
          if (wasOnline) {
            refreshOnlineServer();
          }
        });
      },
      onError: (_) {
        if (welcomeCompleter != null && !welcomeCompleter.isCompleted) {
          welcomeCompleter.complete(false);
        }
        final wasOnline = isOnlineMode;
        disconnect(keepMode: true).then((_) {
          if (wasOnline) {
            refreshOnlineServer();
          }
        });
      },
    );
  }

  // =========================================================================
  // IN-GAME NETWORK SEND METHODS
  // =========================================================================
  void sendRaw(Map<String, dynamic> data) {
    if (!isConnected) return;
    final jsonStr = jsonEncode(data);
    if (isOnlineMode) {
      try {
        _clientSocket?.send(jsonStr);
      } catch (_) {}
      return;
    }
    if (role == MatchRole.host) {
      _broadcastToClients(data);
    } else if (role == MatchRole.client && _clientSocket != null) {
      try {
        _clientSocket!.send(jsonStr);
      } catch (_) {}
    }
  }

  void sendPlayerState({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required int facing,
    required String action,
    required double hp,
    required double ougi,
  }) {
    if (role == MatchRole.host) {
      final me = roomPlayers[myPlayerId];
      if (me != null) {
        if (!me.isAlive) {
          me.hp = 0.0;
        } else if (hp.isFinite && hp < me.hp) {
          me.hp = hp.clamp(0.0, me.maxHp);
        }
        me.ougi = ougi;
      }
    }
    sendRaw({
      'type': 'state',
      'sessionId': matchSessionIdNotifier.value,
      'id': myPlayerId,
      'x': x,
      'y': y,
      'vx': vx,
      'vy': vy,
      'f': facing,
      'act': action,
      'hp': hp,
      'ougi': ougi,
    });
  }

  void sendPlayerAction({
    required String actionType,
    int comboIndex = 0,
    required double x,
    required double y,
    required int facing,
  }) {
    sendRaw({
      'type': 'player_action',
      'sessionId': matchSessionIdNotifier.value,
      'id': myPlayerId,
      'actType': actionType,
      'combo': comboIndex,
      'x': x,
      'y': y,
      'f': facing,
    });
  }

  void sendSpawnKunai({
    required double x,
    required double y,
    required double vx,
    required double vy,
  }) {
    sendRaw({
      'type': 'spawn_kunai',
      'sessionId': matchSessionIdNotifier.value,
      'throwerId': myPlayerId,
      'x': x,
      'y': y,
      'vx': vx,
      'vy': vy,
    });
  }

  void sendHitDamage({
    required String targetId,
    required double damage,
    required double knockbackX,
    required double knockbackY,
    required double targetRemainingHp,
  }) {
    sendRaw({
      'type': 'hit',
      'sessionId': matchSessionIdNotifier.value,
      'targetId': targetId,
      'attackerId': myPlayerId,
      'dmg': damage,
      'kbX': knockbackX,
      'kbY': knockbackY,
      'hp': targetRemainingHp,
    });
  }

  void sendRingOutBlast({
    required double x,
    required int colorIndex,
  }) {
    final packet = {
      'type': 'ring_out_blast',
      'sessionId': matchSessionIdNotifier.value,
      'id': myPlayerId,
      'x': x,
      'color': colorIndex,
    };
    sendRaw(packet);
  }

  void sendLocalPlayerStockLost(int remainingLives) {
    final me = roomPlayers[myPlayerId];
    if (me != null) {
      me.lives = remainingLives;
      me.hp = configuredMaxHp;
      _updateRoomPlayersNotifier();
    }
    final packet = {
      'type': 'player_stock_lost',
      'sessionId': matchSessionIdNotifier.value,
      'id': myPlayerId,
      'lives': remainingLives,
      'hp': configuredMaxHp,
    };
    if (!isOnlineMode && role == MatchRole.host) {
      _broadcastToClients(packet);
      _matchDataController.add(packet);
    } else {
      sendRaw(packet);
    }
  }

  void sendLocalPlayerEliminated() {
    if (!isOnlineMode && role == MatchRole.host) {
      final hostPlayer = roomPlayers[myPlayerId];
      if (hostPlayer != null) {
        hostPlayer.hp = 0.0;
        hostPlayer.lives = 0;
      }
      if (hostPlayer != null && hostPlayer.isAlive) {
        hostPlayer.isAlive = false;
        final aliveCount = roomPlayers.values.where((p) => p.isAlive).length;
        hostPlayer.placement = aliveCount + 1;

        final elimPacket = {
          'type': 'player_eliminated',
          'sessionId': matchSessionIdNotifier.value,
          'id': myPlayerId,
          'nickname': myNickname,
          'placement': hostPlayer.placement,
        };
        _broadcastToClients(elimPacket);
        _matchDataController.add(elimPacket);
        _updateRoomPlayersNotifier();
        _checkMatchEndCondition();
      }
    } else {
      final me = roomPlayers[myPlayerId];
      if (me != null) {
        me.hp = 0.0;
        me.lives = 0;
        me.isAlive = false;
        _updateRoomPlayersNotifier();
      }
      sendRaw({
        'type': 'player_eliminated',
        'sessionId': matchSessionIdNotifier.value,
        'id': myPlayerId,
        'nickname': myNickname,
      });
    }
  }

  void toggleRematchVote() {
    final current = roomPlayers[myPlayerId]?.votedRematch ?? false;
    setRematchVote(!current);
  }

  void voteRematch() => setRematchVote(true);

  void cancelRematchVote() => setRematchVote(false);

  void setRematchVote(bool ready) {
    if (!isOnlineMode && role == MatchRole.host) {
      final p = roomPlayers[myPlayerId];
      if (p != null) {
        p.votedRematch = ready;
        _updateRoomPlayersNotifier();
        _broadcastRematchStatus();
        _checkRematchVoteCondition();
      }
    } else {
      roomPlayers[myPlayerId]?.votedRematch = ready;
      _updateRoomPlayersNotifier();
      sendRaw({
        'type': 'rematch_vote',
        'id': myPlayerId,
        'voted': ready,
      });
    }
  }

  void _updateRoomPlayersNotifier() {
    roomPlayersNotifier.value = roomPlayers.values.toList();
  }

  Future<void> disconnect({bool keepMode = false}) async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _rematchTimer?.cancel();
    _rematchTimer = null;
    _victoryDelayTimer?.cancel();
    _victoryDelayTimer = null;
    _matchEnded = false;

    if (!keepMode) {
      await _closeOnlineLobbySocket();
    }

    if (!kIsWeb) {
      try {
        _broadcastSocket?.close();
      } catch (_) {}
      _broadcastSocket = null;
    }

    stopRoomDiscovery();

    for (final s in _clientSockets.values) {
      try {
        await s.close();
      } catch (_) {}
    }
    _clientSockets.clear();

    try {
      await _clientSocket?.close();
    } catch (_) {}
    _clientSocket = null;

    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;

    role = MatchRole.none;
    isConnected = false;
    currentOnlineRoomId = null;
    inMatchNotifier.value = false;
    matchSessionIdNotifier.value = 0;
    rematchCountdownNotifier.value = null;
    victoryCelebrationNotifier.value = null;
    resultsPodiumNotifier.value = null;
    remainingSecondsNotifier.value = null;
    matchConfigNotifier.value = const MultiplayerMatchConfig();
    roomPlayers.clear();
    _updateRoomPlayersNotifier();
  }
}
