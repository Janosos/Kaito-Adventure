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
    this.hp = 100.0,
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
        'ougi': ougi,
        'placement': placement,
        'votedRematch': votedRematch,
      };

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> map) =>
      MultiplayerPlayer(
        id: map['id'] as String,
        nickname: map['name'] as String? ?? 'Shinobi',
        colorIndex: map['color'] as int? ?? 0,
        slot: map['slot'] as int? ?? 0,
        isHost: map['isHost'] as bool? ?? false,
        isAlive: map['isAlive'] as bool? ?? true,
        hp: (map['hp'] as num?)?.toDouble() ?? 100.0,
        ougi: (map['ougi'] as num?)?.toDouble() ?? 0.0,
        placement: map['placement'] as int? ?? 0,
        votedRematch: map['votedRematch'] as bool? ?? false,
      );
}

enum MatchRole { none, host, client }

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
  static const int maxPlayers = 5;

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

  // Rematch & Results State
  final ValueNotifier<int?> rematchCountdownNotifier =
      ValueNotifier<int?>(null);
  final ValueNotifier<List<MultiplayerPlayer>?> resultsPodiumNotifier =
      ValueNotifier<List<MultiplayerPlayer>?>(null);
  Timer? _rematchTimer;

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

  // Match state notifier
  final ValueNotifier<bool> inMatchNotifier = ValueNotifier<bool>(false);

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

    await disconnect();
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
              'players': roomPlayers.values.map((p) => p.toJson()).toList(),
            }));

            // 2. Broadcast updated lobby list to ALL clients
            _broadcastToClients({
              'type': 'lobby_update',
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
    }
  }

  void _handleClientPacket(String? senderId, Map<String, dynamic> map) {
    final type = map['type'] as String?;

    if (type == 'state') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        roomPlayers[pid]!.hp = (map['hp'] as num?)?.toDouble() ?? 100.0;
        roomPlayers[pid]!.ougi = (map['ougi'] as num?)?.toDouble() ?? 0.0;
      }
      // Re-broadcast state to all OTHER clients
      _broadcastToClients(map, excludeClientId: senderId);
      // Emit locally for Host's game world
      _matchDataController.add(map);
    } else if (type == 'spawn_kunai') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'hit') {
      _broadcastToClients(map, excludeClientId: senderId);
      _matchDataController.add(map);
    } else if (type == 'player_eliminated') {
      final pid = senderId ?? map['id'] as String?;
      if (pid != null && roomPlayers.containsKey(pid)) {
        final deadPlayer = roomPlayers[pid]!;
        if (deadPlayer.isAlive) {
          deadPlayer.isAlive = false;
          final aliveCount = roomPlayers.values.where((p) => p.isAlive).length;
          deadPlayer.placement = aliveCount + 1;

          final elimPacket = {
            'type': 'player_eliminated',
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
        roomPlayers[pid]!.votedRematch = true;
        _updateRoomPlayersNotifier();
        _broadcastRematchStatus();
        _checkRematchVoteCondition();
      }
    }
  }

  /// Host triggers match start for all connected players
  void hostStartMatch() {
    if (role != MatchRole.host || roomPlayers.length < 2) return;

    _rematchTimer?.cancel();
    _rematchTimer = null;
    rematchCountdownNotifier.value = null;
    resultsPodiumNotifier.value = null;

    // Reset combat state for all room players
    for (final p in roomPlayers.values) {
      p.isAlive = true;
      p.hp = 100.0;
      p.ougi = 0.0;
      p.placement = 0;
      p.votedRematch = false;
    }
    _updateRoomPlayersNotifier();

    final startPacket = {
      'type': 'match_start',
      'players': roomPlayers.values.map((p) => p.toJson()).toList(),
    };
    _broadcastToClients(startPacket);
    inMatchNotifier.value = true;
  }

  void _checkMatchEndCondition() {
    if (role != MatchRole.host || !inMatchNotifier.value) return;

    final alive = roomPlayers.values.where((p) => p.isAlive).toList();
    if (alive.length <= 1) {
      if (alive.length == 1) {
        alive.first.placement = 1;
      }

      // Sort podium by placement ascending (1st place first)
      final podium = roomPlayers.values.toList()
        ..sort((a, b) => a.placement.compareTo(b.placement));

      final resultsPacket = {
        'type': 'match_results',
        'podium': podium.map((p) => p.toJson()).toList(),
      };

      _broadcastToClients(resultsPacket);
      resultsPodiumNotifier.value = podium;
    }
  }

  void _broadcastRematchStatus() {
    final packet = {
      'type': 'rematch_update',
      'players': roomPlayers.values.map((p) => p.toJson()).toList(),
    };
    _broadcastToClients(packet);
  }

  void _checkRematchVoteCondition() {
    if (role != MatchRole.host) return;

    final readyCount =
        roomPlayers.values.where((p) => p.votedRematch).length;
    if (readyCount >= 2 && _rematchTimer == null) {
      // 3-second countdown to rematch
      int seconds = 3;
      rematchCountdownNotifier.value = seconds;
      _broadcastToClients({
        'type': 'rematch_countdown',
        'seconds': seconds,
      });

      _rematchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

      _clientSocket!.stream.listen(
        (data) {
          try {
            final text = data is String ? data : utf8.decode(data as List<int>);
            final map = jsonDecode(text) as Map<String, dynamic>;
            final type = map['type'] as String?;

            if (type == 'welcome') {
              myPlayerId = map['yourId'] as String;
              mySlot = map['slot'] as int? ?? 1;
              currentRoomName = map['roomName'] as String? ?? 'Dojo';
              final pList = (map['players'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              roomPlayers.clear();
              for (final p in pList) {
                roomPlayers[p.id] = p;
              }
              _updateRoomPlayersNotifier();
            } else if (type == 'lobby_update') {
              final pList = (map['players'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              roomPlayers.clear();
              for (final p in pList) {
                roomPlayers[p.id] = p;
              }
              _updateRoomPlayersNotifier();
            } else if (type == 'match_start') {
              final pList = (map['players'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              roomPlayers.clear();
              for (final p in pList) {
                roomPlayers[p.id] = p;
              }
              _updateRoomPlayersNotifier();
              resultsPodiumNotifier.value = null;
              rematchCountdownNotifier.value = null;
              inMatchNotifier.value = true;
            } else if (type == 'player_eliminated') {
              final pid = map['id'] as String?;
              if (pid != null && roomPlayers.containsKey(pid)) {
                roomPlayers[pid]!.isAlive = false;
                roomPlayers[pid]!.placement = map['placement'] as int? ?? 0;
                _updateRoomPlayersNotifier();
              }
              _matchDataController.add(map);
            } else if (type == 'match_results') {
              final podium = (map['podium'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              resultsPodiumNotifier.value = podium;
            } else if (type == 'rematch_update') {
              final pList = (map['players'] as List<dynamic>)
                  .map((e) =>
                      MultiplayerPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
              for (final p in pList) {
                if (roomPlayers.containsKey(p.id)) {
                  roomPlayers[p.id]!.votedRematch = p.votedRematch;
                }
              }
              _updateRoomPlayersNotifier();
            } else if (type == 'rematch_countdown') {
              rematchCountdownNotifier.value = map['seconds'] as int?;
            } else {
              _matchDataController.add(map);
            }
          } catch (_) {}
        },
        onDone: () => disconnect(),
        onError: (_) => disconnect(),
      );

      return true;
    } catch (e) {
      debugPrint('[LAN Client] Connection failed: $e');
      await disconnect();
      return false;
    }
  }

  // =========================================================================
  // IN-GAME NETWORK SEND METHODS
  // =========================================================================
  void sendRaw(Map<String, dynamic> data) {
    if (!isConnected) return;
    final jsonStr = jsonEncode(data);
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
    sendRaw({
      'type': 'state',
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

  void sendSpawnKunai({
    required double x,
    required double y,
    required double vx,
    required double vy,
  }) {
    sendRaw({
      'type': 'spawn_kunai',
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
      'targetId': targetId,
      'attackerId': myPlayerId,
      'dmg': damage,
      'kbX': knockbackX,
      'kbY': knockbackY,
      'hp': targetRemainingHp,
    });
  }

  void sendLocalPlayerEliminated() {
    if (role == MatchRole.host) {
      final hostPlayer = roomPlayers[myPlayerId];
      if (hostPlayer != null && hostPlayer.isAlive) {
        hostPlayer.isAlive = false;
        final aliveCount = roomPlayers.values.where((p) => p.isAlive).length;
        hostPlayer.placement = aliveCount + 1;

        final elimPacket = {
          'type': 'player_eliminated',
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
      sendRaw({
        'type': 'player_eliminated',
        'id': myPlayerId,
        'nickname': myNickname,
      });
    }
  }

  void voteRematch() {
    if (role == MatchRole.host) {
      roomPlayers[myPlayerId]?.votedRematch = true;
      _updateRoomPlayersNotifier();
      _broadcastRematchStatus();
      _checkRematchVoteCondition();
    } else {
      sendRaw({
        'type': 'rematch_vote',
        'id': myPlayerId,
      });
    }
  }

  void _updateRoomPlayersNotifier() {
    roomPlayersNotifier.value = roomPlayers.values.toList();
  }

  Future<void> disconnect() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _rematchTimer?.cancel();
    _rematchTimer = null;

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
    inMatchNotifier.value = false;
    rematchCountdownNotifier.value = null;
    resultsPodiumNotifier.value = null;
    roomPlayers.clear();
    _updateRoomPlayersNotifier();
  }
}
