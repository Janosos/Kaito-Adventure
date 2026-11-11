import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

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
  final DateTime lastSeen;

  DiscoveredRoom({
    required this.roomName,
    required this.hostName,
    required this.hostColorIndex,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });
}

enum MatchRole { none, host, client }

class LanMultiplayerService {
  static final LanMultiplayerService instance = LanMultiplayerService._();
  LanMultiplayerService._();

  static const int kGamePort = 7777;
  static const int kDiscoveryPort = 7778;

  // Local Player Config
  String myNickname = 'Kaito_${Random().nextInt(900) + 100}';
  int myColorIndex = 0;

  // Remote Player Info
  String opponentNickname = 'Rival Shinobi';
  int opponentColorIndex = 1;

  // Connection State
  MatchRole role = MatchRole.none;
  bool isConnected = false;
  String? localIpAddress;

  // Server (Host) internals
  HttpServer? _server;
  WebSocket? _socket;
  RawDatagramSocket? _broadcastSocket;
  Timer? _beaconTimer;

  // Discovery (Client) internals
  RawDatagramSocket? _discoverySocket;
  final ValueNotifier<List<DiscoveredRoom>> discoveredRooms =
      ValueNotifier<List<DiscoveredRoom>>([]);

  // Stream controller for in-game match packets
  final StreamController<Map<String, dynamic>> _matchDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMatchData => _matchDataController.stream;

  // Match state notifier
  final ValueNotifier<bool> inMatchNotifier = ValueNotifier<bool>(false);

  Color get myColor => kMultiplayerColors[myColorIndex.clamp(0, kMultiplayerColors.length - 1)].primary;
  Color get opponentColor => kMultiplayerColors[opponentColorIndex.clamp(0, kMultiplayerColors.length - 1)].primary;

  Future<void> init() async {
    await refreshLocalIp();
  }

  Future<String> refreshLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
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
  // HOST: Create Room & Listen for Clients
  // =========================================================================
  Future<bool> startHostRoom({String? roomName}) async {
    await disconnect();
    await refreshLocalIp();

    final actualRoomName = roomName?.trim().isNotEmpty == true
        ? roomName!.trim()
        : 'Dojo de $myNickname';

    try {
      // 1. Start WebSocket Game Server
      _server = await HttpServer.bind(InternetAddress.anyIPv4, kGamePort);
      role = MatchRole.host;
      isConnected = false;

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          if (_socket != null) {
            // Already have a player (1v1 duel)
            ws.close(1008, 'Room Full');
            return;
          }
          _handleConnectedSocket(ws, isHostSide: true);
        }
      });

      // 2. Start UDP Broadcast Beacon on WiFi
      try {
        _broadcastSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
        );
        _broadcastSocket!.broadcastEnabled = true;

        _beaconTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
          final beaconData = jsonEncode({
            'type': 'kaito_beacon',
            'roomName': actualRoomName,
            'hostName': myNickname,
            'hostColor': myColorIndex,
            'ip': localIpAddress ?? '127.0.0.1',
            'port': kGamePort,
          });
          final bytes = utf8.encode(beaconData);
          _broadcastSocket?.send(
            bytes,
            InternetAddress('255.255.255.255'),
            kDiscoveryPort,
          );
        });
      } catch (e) {
        debugPrint('[LAN Host] UDP Beacon error (non-fatal): $e');
      }

      return true;
    } catch (e) {
      debugPrint('[LAN Host] Failed to start server: $e');
      await disconnect();
      return false;
    }
  }

  // =========================================================================
  // CLIENT: Discovery & Join Room
  // =========================================================================
  Future<void> startRoomDiscovery() async {
    stopRoomDiscovery();
    discoveredRooms.value = [];

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

                final existing = List<DiscoveredRoom>.from(discoveredRooms.value);
                final idx = existing.indexWhere((r) => r.ip == ip && r.port == port);
                final room = DiscoveredRoom(
                  roomName: roomName,
                  hostName: hostName,
                  hostColorIndex: hostColor,
                  ip: ip,
                  port: port,
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
      debugPrint('[LAN Discovery] Failed to bind discovery socket: $e');
    }
  }

  void stopRoomDiscovery() {
    _discoverySocket?.close();
    _discoverySocket = null;
  }

  Future<bool> connectToRoom(String ip, [int port = kGamePort]) async {
    await disconnect();
    role = MatchRole.client;
    try {
      final ws = await WebSocket.connect(
        'ws://$ip:$port',
      ).timeout(const Duration(seconds: 5));

      _handleConnectedSocket(ws, isHostSide: false);
      return true;
    } catch (e) {
      debugPrint('[LAN Client] Connection failed to $ip:$port: $e');
      await disconnect();
      return false;
    }
  }

  // =========================================================================
  // Internal Socket & Messaging
  // =========================================================================
  void _handleConnectedSocket(WebSocket ws, {required bool isHostSide}) {
    _socket = ws;
    isConnected = true;

    // Send Handshake
    sendRaw({
      'type': 'handshake',
      'name': myNickname,
      'color': myColorIndex,
    });

    _socket!.listen(
      (data) {
        try {
          final map = jsonDecode(data as String) as Map<String, dynamic>;
          final type = map['type'] as String?;

          if (type == 'handshake') {
            opponentNickname = map['name'] as String? ?? 'Rival';
            opponentColorIndex = map['color'] as int? ?? 1;

            if (isHostSide) {
              // Host triggers match start countdown
              sendRaw({
                'type': 'match_start',
                'hostName': myNickname,
                'hostColor': myColorIndex,
                'clientName': opponentNickname,
                'clientColor': opponentColorIndex,
              });
              inMatchNotifier.value = true;
            }
          } else if (type == 'match_start') {
            opponentNickname = map['hostName'] as String? ?? opponentNickname;
            opponentColorIndex = map['hostColor'] as int? ?? opponentColorIndex;
            inMatchNotifier.value = true;
          }

          _matchDataController.add(map);
        } catch (_) {}
      },
      onDone: () {
        debugPrint('[LAN] Socket closed');
        disconnect();
      },
      onError: (err) {
        debugPrint('[LAN] Socket error: $err');
        disconnect();
      },
    );
  }

  void sendRaw(Map<String, dynamic> data) {
    if (_socket != null && isConnected) {
      try {
        _socket!.add(jsonEncode(data));
      } catch (_) {}
    }
  }

  // High-frequency in-match sync methods
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

  void sendAttack({
    required String attackType, // 'slash', 'heavy', 'kunai', 'ougi'
    required double x,
    required double y,
    required int facing,
  }) {
    sendRaw({
      'type': 'attack',
      'atk': attackType,
      'x': x,
      'y': y,
      'f': facing,
    });
  }

  void sendHitDamage({
    required double damage,
    required double knockbackX,
    required double knockbackY,
    required double targetRemainingHp,
  }) {
    sendRaw({
      'type': 'hit',
      'dmg': damage,
      'kbX': knockbackX,
      'kbY': knockbackY,
      'hp': targetRemainingHp,
    });
  }

  void sendRingOut({required String defeatedNickname}) {
    sendRaw({
      'type': 'ring_out',
      'loser': defeatedNickname,
    });
  }

  Future<void> disconnect() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;

    _broadcastSocket?.close();
    _broadcastSocket = null;

    stopRoomDiscovery();

    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;

    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;

    role = MatchRole.none;
    isConnected = false;
    inMatchNotifier.value = false;
  }
}

