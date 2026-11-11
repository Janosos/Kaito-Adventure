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

  // Server (Host) internals (Native only)
  HttpServer? _server;
  LanSocket? _socket;
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

  Color get myColor =>
      kMultiplayerColors[myColorIndex.clamp(0, kMultiplayerColors.length - 1)]
          .primary;
  Color get opponentColor => kMultiplayerColors[
          opponentColorIndex.clamp(0, kMultiplayerColors.length - 1)]
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
  // HOST: Create Room & Listen for Clients (Native: Windows, Android, iOS)
  // =========================================================================
  Future<bool> startHostRoom({String? roomName}) async {
    if (kIsWeb) {
      debugPrint('[LAN Host] Hosting is not supported on web browsers.');
      return false;
    }

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
        // Enable CORS headers so Web Chrome clients can connect seamlessly
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
            'roomName': actualRoomName,
            'hostName': myNickname,
            'hostColor': myColorIndex,
            'ip': localIpAddress ?? '127.0.0.1',
            'port': kGamePort,
          }));
          await request.response.close();
          return;
        }

        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          if (_socket != null) {
            // Already have a player (1v1 duel)
            ws.close(1008, 'Room Full');
            return;
          }
          _handleConnectedSocket(IoWebSocket(ws), isHostSide: true);
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
  // CLIENT: Discovery & Join Room (Native & Web)
  // =========================================================================
  Future<void> startRoomDiscovery() async {
    stopRoomDiscovery();
    discoveredRooms.value = [];

    if (kIsWeb) {
      // Browsers sandbox blocks raw UDP sockets.
      // Web connects directly via host IP.
      return;
    }

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
      debugPrint('[LAN Client] Connecting via WebSocketChannel to $wsUri ...');

      final channel = WebSocketChannel.connect(wsUri);
      await channel.ready.timeout(const Duration(seconds: 5));

      _handleConnectedSocket(ChannelWebSocket(channel), isHostSide: false);
      return true;
    } catch (e) {
      debugPrint('[LAN Client] Connection failed to $cleanIp:$actualPort: $e');
      await disconnect();
      return false;
    }
  }

  // =========================================================================
  // Internal Socket & Messaging
  // =========================================================================
  void _handleConnectedSocket(LanSocket socket, {required bool isHostSide}) {
    _socket = socket;
    isConnected = true;

    // Send Handshake
    sendRaw({
      'type': 'handshake',
      'name': myNickname,
      'color': myColorIndex,
    });

    _socket!.stream.listen(
      (data) {
        try {
          final text = data is String ? data : utf8.decode(data as List<int>);
          final map = jsonDecode(text) as Map<String, dynamic>;
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
            opponentColorIndex =
                map['hostColor'] as int? ?? opponentColorIndex;
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
        _socket!.send(jsonEncode(data));
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

    if (!kIsWeb) {
      try {
        _broadcastSocket?.close();
      } catch (_) {}
      _broadcastSocket = null;
    }

    stopRoomDiscovery();

    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;

    if (!kIsWeb) {
      try {
        await _server?.close(force: true);
      } catch (_) {}
      _server = null;
    }

    role = MatchRole.none;
    isConnected = false;
    inMatchNotifier.value = false;
  }
}
