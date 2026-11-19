using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

namespace KaitoOnlineServer
{
    public class MatchConfig
    {
        public int stage;
        public int time;
        public int maxHp;
        public int lives;

        public MatchConfig()
        {
            stage = 0;
            time = 180;
            maxHp = 300;
            lives = 3;
        }

        public Dictionary<string, object> ToDict()
        {
            Dictionary<string, object> d = new Dictionary<string, object>();
            d["stage"] = stage;
            d["time"] = time;
            d["maxHp"] = maxHp;
            d["lives"] = lives;
            return d;
        }

        public static MatchConfig FromDict(Dictionary<string, object> map)
        {
            MatchConfig cfg = new MatchConfig();
            if (map == null) return cfg;
            if (map.ContainsKey("stage")) cfg.stage = Clamp(ToInt(map["stage"], 0), 0, 2);
            if (map.ContainsKey("time")) cfg.time = ToInt(map["time"], 180);
            if (map.ContainsKey("maxHp")) cfg.maxHp = Clamp(ToInt(map["maxHp"], 300), 50, 2000);
            if (map.ContainsKey("lives")) cfg.lives = Clamp(ToInt(map["lives"], 3), 1, 10);
            return cfg;
        }

        private static int ToInt(object val, int fallback)
        {
            if (val == null) return fallback;
            try { return Convert.ToInt32(val); } catch { return fallback; }
        }

        private static int Clamp(int v, int min, int max)
        {
            if (v < min) return min;
            if (v > max) return max;
            return v;
        }
    }

    public class OnlinePlayer
    {
        public string id;
        public string nickname;
        public int colorIndex;
        public int slot;
        public bool isHost;
        public bool isAlive;
        public double hp;
        public double maxHp;
        public int lives;
        public int maxLives;
        public double ougi;
        public int placement;
        public bool votedRematch;
        public ClientConnection connection;

        public OnlinePlayer()
        {
            id = "p_1";
            nickname = "Shinobi";
            colorIndex = 0;
            slot = 0;
            isHost = false;
            isAlive = true;
            hp = 300.0;
            maxHp = 300.0;
            lives = 3;
            maxLives = 3;
            ougi = 0.0;
            placement = 0;
            votedRematch = false;
        }

        public Dictionary<string, object> ToDict()
        {
            Dictionary<string, object> d = new Dictionary<string, object>();
            d["id"] = id;
            d["name"] = nickname;
            d["color"] = colorIndex;
            d["slot"] = slot;
            d["isHost"] = isHost;
            d["isAlive"] = isAlive;
            d["hp"] = hp;
            d["maxHp"] = maxHp;
            d["lives"] = lives;
            d["maxLives"] = maxLives;
            d["ougi"] = ougi;
            d["placement"] = placement;
            d["votedRematch"] = votedRematch;
            return d;
        }
    }

    public class OnlineRoom
    {
        public string roomId;
        public string roomName;
        public MatchConfig config;
        public Dictionary<string, OnlinePlayer> players;
        public int sessionId;
        public bool inMatch;
        public bool matchEnded;
        public Timer victoryDelayTimer;
        public Timer rematchTimer;
        public int rematchSeconds;
        public DateTime createdAt;

        public OnlineRoom(string id, string name, MatchConfig cfg)
        {
            roomId = id;
            roomName = name;
            config = cfg != null ? cfg : new MatchConfig();
            players = new Dictionary<string, OnlinePlayer>();
            sessionId = 0;
            inMatch = false;
            matchEnded = false;
            rematchSeconds = 0;
            createdAt = DateTime.UtcNow;
        }

        public OnlinePlayer GetHostPlayer()
        {
            foreach (OnlinePlayer p in players.Values)
            {
                if (p.isHost) return p;
            }
            foreach (OnlinePlayer p in players.Values)
            {
                return p;
            }
            return null;
        }

        public List<Dictionary<string, object>> GetPlayersDictList()
        {
            List<OnlinePlayer> sorted = new List<OnlinePlayer>(players.Values);
            sorted.Sort(delegate(OnlinePlayer a, OnlinePlayer b) { return a.slot.CompareTo(b.slot); });
            List<Dictionary<string, object>> list = new List<Dictionary<string, object>>();
            foreach (OnlinePlayer p in sorted)
            {
                list.Add(p.ToDict());
            }
            return list;
        }

        public Dictionary<string, object> ToSummaryDict()
        {
            OnlinePlayer host = GetHostPlayer();
            Dictionary<string, object> d = new Dictionary<string, object>();
            d["roomId"] = roomId;
            d["roomName"] = roomName;
            d["hostName"] = host != null ? host.nickname : "Shinobi";
            d["hostColor"] = host != null ? host.colorIndex : 0;
            d["playerCount"] = players.Count;
            d["maxPlayers"] = 5;
            d["inMatch"] = inMatch;
            d["config"] = config.ToDict();
            return d;
        }

        public void StopTimers()
        {
            if (victoryDelayTimer != null)
            {
                try { victoryDelayTimer.Dispose(); } catch { }
                victoryDelayTimer = null;
            }
            if (rematchTimer != null)
            {
                try { rematchTimer.Dispose(); } catch { }
                rematchTimer = null;
            }
        }
    }

    public class ClientConnection
    {
        public string connectionId;
        public TcpClient tcpClient;
        public NetworkStream stream;
        public string remoteEndpoint;
        public OnlineRoom currentRoom;
        public OnlinePlayer currentPlayer;
        public bool isWebSocket;
        public bool isClosed;
        private readonly object _sendLock = new object();

        public ClientConnection(string id, TcpClient client)
        {
            connectionId = id;
            tcpClient = client;
            stream = client.GetStream();
            remoteEndpoint = client.Client.RemoteEndPoint != null
                ? client.Client.RemoteEndPoint.ToString()
                : "unknown";
            isWebSocket = false;
            isClosed = false;
        }

        public void SendWebSocketText(string jsonText)
        {
            if (isClosed || !isWebSocket) return;
            try
            {
                byte[] payload = Encoding.UTF8.GetBytes(jsonText);
                byte[] frame;
                if (payload.Length < 126)
                {
                    frame = new byte[2 + payload.Length];
                    frame[0] = 0x81; // FIN + Text Frame
                    frame[1] = (byte)payload.Length;
                    Buffer.BlockCopy(payload, 0, frame, 2, payload.Length);
                }
                else if (payload.Length <= 65535)
                {
                    frame = new byte[4 + payload.Length];
                    frame[0] = 0x81;
                    frame[1] = 126;
                    frame[2] = (byte)((payload.Length >> 8) & 0xFF);
                    frame[3] = (byte)(payload.Length & 0xFF);
                    Buffer.BlockCopy(payload, 0, frame, 4, payload.Length);
                }
                else
                {
                    frame = new byte[10 + payload.Length];
                    frame[0] = 0x81;
                    frame[1] = 127;
                    long len = payload.Length;
                    for (int i = 0; i < 8; i++)
                    {
                        frame[9 - i] = (byte)(len & 0xFF);
                        len >>= 8;
                    }
                    Buffer.BlockCopy(payload, 0, frame, 10, payload.Length);
                }

                lock (_sendLock)
                {
                    if (!isClosed)
                    {
                        stream.Write(frame, 0, frame.Length);
                        stream.Flush();
                    }
                }
            }
            catch
            {
                Close();
            }
        }

        public void SendPong(byte[] pingPayload)
        {
            if (isClosed || !isWebSocket) return;
            try
            {
                int len = pingPayload != null ? Math.Min(pingPayload.Length, 125) : 0;
                byte[] frame = new byte[2 + len];
                frame[0] = 0x8A; // FIN + Pong
                frame[1] = (byte)len;
                if (len > 0)
                {
                    Buffer.BlockCopy(pingPayload, 0, frame, 2, len);
                }
                lock (_sendLock)
                {
                    if (!isClosed)
                    {
                        stream.Write(frame, 0, frame.Length);
                        stream.Flush();
                    }
                }
            }
            catch
            {
                Close();
            }
        }

        public void Close()
        {
            if (isClosed) return;
            isClosed = true;
            try { stream.Close(); } catch { }
            try { tcpClient.Close(); } catch { }
        }
    }

    class Program
    {
        public static int TcpPort = 7779;
        public static int UdpDiscoveryPort = 7780;
        public const int MaxPlayersPerRoom = 5;
        public const int RematchCountdownSeconds = 10;
        public const int VictoryCelebrationMs = 3200;
        public static string ServerName = "Servidor Oficial Kaito Online";

        private static readonly object ServerLock = new object();
        private static readonly Dictionary<string, OnlineRoom> Rooms = new Dictionary<string, OnlineRoom>();
        private static readonly Dictionary<string, ClientConnection> Clients = new Dictionary<string, ClientConnection>();
        private static int _nextRoomCounter = 1;
        private static int _nextPlayerCounter = 1;
        private static int _nextConnCounter = 1;
        private static bool _running = true;
        private static TcpListener _tcpListener;
        private static UdpClient _udpListener;

        static void Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;
            Console.Title = "KAITO ADVENTURE: INK SHINOBI - SERVIDOR MULTIPLAYER ONLINE";

            if (args != null && args.Length > 0)
            {
                int parsedPort;
                if (int.TryParse(args[0], out parsedPort) && parsedPort > 1024 && parsedPort < 65535)
                {
                    TcpPort = parsedPort;
                }
            }

            PrintBanner();

            try
            {
                _tcpListener = new TcpListener(IPAddress.Any, TcpPort);
                _tcpListener.Start();
            }
            catch (Exception ex)
            {
                LogError("No se pudo iniciar el servidor en el puerto TCP " + TcpPort + ": " + ex.Message);
                LogInfo("Verifica que no haya otra ventana del servidor abierta en el mismo puerto.");
                Console.WriteLine("\nPresiona cualquier tecla para salir...");
                Console.ReadKey(true);
                return;
            }

            StartUdpDiscoveryService();

            Thread acceptThread = new Thread(AcceptClientsLoop);
            acceptThread.IsBackground = true;
            acceptThread.Start();

            LogSuccess("Servidor Online ACTIVO y escuchando en el puerto TCP " + TcpPort + " y UDP " + UdpDiscoveryPort + ".");
            LogInfo("Abre el juego Kaito Adventure -> Modo Multijugador Online -> Pulsa REFRESCAR.");
            Console.WriteLine("--------------------------------------------------------------------------------");
            Console.WriteLine("Comandos en consola: [S] Ver Salas y Jugadores | [C] Limpiar | [Q] Apagar");
            Console.WriteLine("--------------------------------------------------------------------------------\n");

            while (_running)
            {
                try
                {
                    if (Console.KeyAvailable)
                    {
                        ConsoleKeyInfo key = Console.ReadKey(true);
                        if (key.Key == ConsoleKey.Q)
                        {
                            LogInfo("Apagando el Servidor Online...");
                            _running = false;
                            break;
                        }
                        else if (key.Key == ConsoleKey.S)
                        {
                            PrintServerStatus();
                        }
                        else if (key.Key == ConsoleKey.C)
                        {
                            Console.Clear();
                            PrintBanner();
                            PrintServerStatus();
                        }
                    }
                    Thread.Sleep(100);
                }
                catch
                {
                    Thread.Sleep(500);
                }
            }

            try { _tcpListener.Stop(); } catch { }
            try { if (_udpListener != null) _udpListener.Close(); } catch { }
        }

        private static void PrintBanner()
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("================================================================================");
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("      KAITO ADVENTURE: INK SHINOBI - SERVIDOR DEDICADO MULTIPLAYER ONLINE");
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("================================================================================");
            Console.ResetColor();

            List<string> ips = GetLocalIPv4Addresses();
            string primaryIp = ips.Count > 0 ? ips[0] : "127.0.0.1";

            Console.WriteLine("  Estado del Servidor : ACTIVO (ONLINE)");
            Console.WriteLine("  Puerto TCP / WS     : " + TcpPort);
            Console.WriteLine("  Puerto UDP Radar    : " + UdpDiscoveryPort);
            Console.WriteLine("  Capacidad por Sala  : 2 a 5 Jugadores (Salas Multiples Simultaneas)");
            Console.WriteLine("--------------------------------------------------------------------------------");
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("  DIRECCIONES IP PARA CONECTARSE DESDE EL JUEGO:");
            Console.ResetColor();
            Console.WriteLine("  - En esta misma PC          : 127.0.0.1:" + TcpPort + " (Deteccion automatica)");
            foreach (string ip in ips)
            {
                Console.WriteLine("  - Red Local / VPN Detectada : " + ip + ":" + TcpPort);
            }
            Console.WriteLine("================================================================================\n");
        }

        private static void PrintServerStatus()
        {
            lock (ServerLock)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("\n--- ESTADO ACTUAL DEL SERVIDOR ONLINE ---");
                Console.ResetColor();
                Console.WriteLine("  Conexiones activas : " + Clients.Count);
                Console.WriteLine("  Salas Online       : " + Rooms.Count);
                foreach (OnlineRoom r in Rooms.Values)
                {
                    Console.WriteLine("  * [" + r.roomId + "] \"" + r.roomName + "\" (" + r.players.Count + "/5) - " + (r.inMatch ? "EN COMBATE" : "EN SALA DE ESPERA"));
                    foreach (OnlinePlayer p in r.players.Values)
                    {
                        Console.WriteLine("      - Slot " + (p.slot + 1) + ": " + p.nickname + (p.isHost ? " [ANFITRION]" : "") + " (HP: " + p.hp + "/" + p.maxHp + ", Vidas: " + p.lives + ")");
                    }
                }
                Console.WriteLine("-----------------------------------------\n");
            }
        }

        private static List<string> GetLocalIPv4Addresses()
        {
            List<string> list = new List<string>();
            try
            {
                NetworkInterface[] interfaces = NetworkInterface.GetAllNetworkInterfaces();
                foreach (NetworkInterface ni in interfaces)
                {
                    if (ni.OperationalStatus != OperationalStatus.Up) continue;
                    if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback) continue;
                    IPInterfaceProperties props = ni.GetIPProperties();
                    foreach (UnicastIPAddressInformation addr in props.UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(addr.Address))
                        {
                            string ipStr = addr.Address.ToString();
                            if (!ipStr.StartsWith("169.254.") && !list.Contains(ipStr))
                            {
                                list.Add(ipStr);
                            }
                        }
                    }
                }
            }
            catch { }
            if (list.Count == 0)
            {
                list.Add("127.0.0.1");
            }
            return list;
        }

        private static void StartUdpDiscoveryService()
        {
            try
            {
                _udpListener = new UdpClient(UdpDiscoveryPort);
                _udpListener.EnableBroadcast = true;

                // Thread 1: Listen for discovery requests from Kaito Adventure clients
                Thread udpListenThread = new Thread(delegate()
                {
                    IPEndPoint remoteEp = new IPEndPoint(IPAddress.Any, 0);
                    while (_running)
                    {
                        try
                        {
                            byte[] data = _udpListener.Receive(ref remoteEp);
                            string text = Encoding.UTF8.GetString(data);
                            if (text.Contains("kaito_online_discover"))
                            {
                                byte[] reply = BuildUdpBeaconBytes();
                                _udpListener.Send(reply, reply.Length, remoteEp);
                            }
                        }
                        catch
                        {
                            if (!_running) break;
                            Thread.Sleep(200);
                        }
                    }
                });
                udpListenThread.IsBackground = true;
                udpListenThread.Start();

                // Thread 2: Periodic UDP broadcast every 1.5s so clients on the network discover the online server automatically
                Thread udpBeaconThread = new Thread(delegate()
                {
                    IPEndPoint broadcastEp = new IPEndPoint(IPAddress.Broadcast, UdpDiscoveryPort);
                    while (_running)
                    {
                        try
                        {
                            byte[] beacon = BuildUdpBeaconBytes();
                            _udpListener.Send(beacon, beacon.Length, broadcastEp);
                        }
                        catch { }
                        Thread.Sleep(1500);
                    }
                });
                udpBeaconThread.IsBackground = true;
                udpBeaconThread.Start();
            }
            catch (Exception ex)
            {
                LogInfo("Aviso UDP Radar (" + UdpDiscoveryPort + "): " + ex.Message);
            }
        }

        private static byte[] BuildUdpBeaconBytes()
        {
            List<string> ips = GetLocalIPv4Addresses();
            string primaryIp = ips.Count > 0 ? ips[0] : "127.0.0.1";
            int roomCount = 0;
            int clientCount = 0;
            lock (ServerLock)
            {
                roomCount = Rooms.Count;
                clientCount = Clients.Count;
            }
            Dictionary<string, object> payload = new Dictionary<string, object>();
            payload["type"] = "kaito_online_server_beacon";
            payload["serverName"] = ServerName;
            payload["ip"] = primaryIp;
            payload["port"] = TcpPort;
            payload["roomCount"] = roomCount;
            payload["playerCount"] = clientCount;
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            return Encoding.UTF8.GetBytes(serializer.Serialize(payload));
        }

        private static void AcceptClientsLoop()
        {
            while (_running)
            {
                try
                {
                    TcpClient tcpClient = _tcpListener.AcceptTcpClient();
                    tcpClient.NoDelay = true;
                    string connId = "c_" + (_nextConnCounter++);
                    ClientConnection conn = new ClientConnection(connId, tcpClient);
                    Thread clientThread = new Thread(delegate() { HandleClientConnection(conn); });
                    clientThread.IsBackground = true;
                    clientThread.Start();
                }
                catch
                {
                    if (!_running) break;
                }
            }
        }

        private static void HandleClientConnection(ClientConnection conn)
        {
            try
            {
                // Read initial HTTP request headers
                string headerText = ReadHttpHeaders(conn.stream);
                if (string.IsNullOrEmpty(headerText))
                {
                    conn.Close();
                    return;
                }

                string[] lines = headerText.Split(new string[] { "\r\n" }, StringSplitOptions.None);
                string requestLine = lines.Length > 0 ? lines[0] : "";
                string[] reqParts = requestLine.Split(' ');
                string method = reqParts.Length > 0 ? reqParts[0].ToUpperInvariant() : "GET";
                string path = reqParts.Length > 1 ? reqParts[1] : "/";

                Dictionary<string, string> headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                for (int i = 1; i < lines.Length; i++)
                {
                    int colon = lines[i].IndexOf(':');
                    if (colon > 0)
                    {
                        string k = lines[i].Substring(0, colon).Trim();
                        string v = lines[i].Substring(colon + 1).Trim();
                        headers[k] = v;
                    }
                }

                // Handle CORS preflight OPTIONS
                if (method == "OPTIONS")
                {
                    WriteHttpResponse(conn.stream, "200 OK", "text/plain", "");
                    conn.Close();
                    return;
                }

                // Check if this is a WebSocket Upgrade request
                string wsKey = headers.ContainsKey("Sec-WebSocket-Key") ? headers["Sec-WebSocket-Key"] : null;
                if (!string.IsNullOrEmpty(wsKey))
                {
                    string acceptKey = ComputeWebSocketAcceptKey(wsKey);
                    string handshakeResponse =
                        "HTTP/1.1 101 Switching Protocols\r\n" +
                        "Upgrade: websocket\r\n" +
                        "Connection: Upgrade\r\n" +
                        "Access-Control-Allow-Origin: *\r\n" +
                        "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n";
                    byte[] respBytes = Encoding.UTF8.GetBytes(handshakeResponse);
                    conn.stream.Write(respBytes, 0, respBytes.Length);
                    conn.stream.Flush();
                    conn.isWebSocket = true;

                    lock (ServerLock)
                    {
                        Clients[conn.connectionId] = conn;
                    }

                    // Send initial rooms list upon WebSocket connect
                    SendRoomsListToClient(conn);

                    // Enter WebSocket Frame loop
                    WebSocketReceiveLoop(conn);
                }
                else
                {
                    // Standard HTTP Status / Rooms Check (GET /status, /rooms, /info, /)
                    string statusJson = BuildStatusJson();
                    WriteHttpResponse(conn.stream, "200 OK", "application/json; charset=utf-8", statusJson);
                    conn.Close();
                }
            }
            catch
            {
                // Ignore disconnect errors
            }
            finally
            {
                HandleClientDisconnect(conn);
            }
        }

        private static string ReadHttpHeaders(NetworkStream stream)
        {
            List<byte> buffer = new List<byte>();
            byte[] single = new byte[1];
            stream.ReadTimeout = 5000;
            while (buffer.Count < 16384)
            {
                int read = stream.Read(single, 0, 1);
                if (read <= 0) break;
                buffer.Add(single[0]);
                int count = buffer.Count;
                if (count >= 4 &&
                    buffer[count - 4] == '\r' &&
                    buffer[count - 3] == '\n' &&
                    buffer[count - 2] == '\r' &&
                    buffer[count - 1] == '\n')
                {
                    break;
                }
            }
            stream.ReadTimeout = Timeout.Infinite;
            return Encoding.UTF8.GetString(buffer.ToArray());
        }

        private static void WriteHttpResponse(NetworkStream stream, string status, string contentType, string body)
        {
            byte[] bodyBytes = Encoding.UTF8.GetBytes(body != null ? body : "");
            string headers =
                "HTTP/1.1 " + status + "\r\n" +
                "Content-Type: " + contentType + "\r\n" +
                "Access-Control-Allow-Origin: *\r\n" +
                "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
                "Access-Control-Allow-Headers: *\r\n" +
                "Access-Control-Allow-Private-Network: true\r\n" +
                "Content-Length: " + bodyBytes.Length + "\r\n" +
                "Connection: close\r\n\r\n";
            byte[] headerBytes = Encoding.UTF8.GetBytes(headers);
            stream.Write(headerBytes, 0, headerBytes.Length);
            if (bodyBytes.Length > 0)
            {
                stream.Write(bodyBytes, 0, bodyBytes.Length);
            }
            stream.Flush();
        }

        private static string ComputeWebSocketAcceptKey(string secWebSocketKey)
        {
            string combined = secWebSocketKey.Trim() + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
            byte[] hash = SHA1.Create().ComputeHash(Encoding.ASCII.GetBytes(combined));
            return Convert.ToBase64String(hash);
        }

        private static void WebSocketReceiveLoop(ClientConnection conn)
        {
            NetworkStream stream = conn.stream;
            while (_running && !conn.isClosed)
            {
                int b0 = stream.ReadByte();
                if (b0 == -1) break;
                int b1 = stream.ReadByte();
                if (b1 == -1) break;

                int opcode = b0 & 0x0F;
                bool masked = (b1 & 0x80) != 0;
                long payloadLen = b1 & 0x7F;

                if (payloadLen == 126)
                {
                    byte[] ext = ReadExactBytes(stream, 2);
                    if (ext == null) break;
                    payloadLen = (ext[0] << 8) | ext[1];
                }
                else if (payloadLen == 127)
                {
                    byte[] ext = ReadExactBytes(stream, 8);
                    if (ext == null) break;
                    payloadLen = 0;
                    for (int i = 0; i < 8; i++)
                    {
                        payloadLen = (payloadLen << 8) | ext[i];
                    }
                }

                if (payloadLen > 1048576 || payloadLen < 0)
                {
                    break;
                }

                byte[] maskKey = null;
                if (masked)
                {
                    maskKey = ReadExactBytes(stream, 4);
                    if (maskKey == null) break;
                }

                byte[] payload = ReadExactBytes(stream, (int)payloadLen);
                if (payload == null) break;

                if (masked && maskKey != null)
                {
                    for (int i = 0; i < payload.Length; i++)
                    {
                        payload[i] = (byte)(payload[i] ^ maskKey[i % 4]);
                    }
                }

                if (opcode == 0x08) // Close frame
                {
                    break;
                }
                else if (opcode == 0x09) // Ping frame
                {
                    conn.SendPong(payload);
                }
                else if (opcode == 0x01 || opcode == 0x02) // Text or Binary JSON packet
                {
                    string jsonText = Encoding.UTF8.GetString(payload);
                    ProcessIncomingPacket(conn, jsonText);
                }
            }
        }

        private static byte[] ReadExactBytes(NetworkStream stream, int length)
        {
            byte[] data = new byte[length];
            int offset = 0;
            while (offset < length)
            {
                int read = stream.Read(data, offset, length - offset);
                if (read <= 0) return null;
                offset += read;
            }
            return data;
        }

        private static void ProcessIncomingPacket(ClientConnection conn, string jsonText)
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            Dictionary<string, object> map;
            try
            {
                map = serializer.Deserialize<Dictionary<string, object>>(jsonText);
            }
            catch
            {
                return;
            }
            if (map == null || !map.ContainsKey("type")) return;

            string type = Convert.ToString(map["type"]);

            if (type == "online_get_rooms" || type == "online_ping")
            {
                SendRoomsListToClient(conn);
                return;
            }

            if (type == "online_create_room")
            {
                HandleCreateOnlineRoom(conn, map);
                return;
            }

            if (type == "online_join_room" || type == "handshake")
            {
                HandleJoinOnlineRoom(conn, map);
                return;
            }

            if (type == "online_leave_room")
            {
                RemovePlayerFromCurrentRoom(conn);
                SendRoomsListToClient(conn);
                return;
            }

            // Packets inside an active room
            OnlineRoom room = conn.currentRoom;
            OnlinePlayer sender = conn.currentPlayer;
            if (room == null || sender == null) return;

            if (type == "config_update")
            {
                lock (ServerLock)
                {
                    if (!sender.isHost) return;
                    Dictionary<string, object> cfgMap = map.ContainsKey("config")
                        ? map["config"] as Dictionary<string, object>
                        : null;
                    if (cfgMap != null)
                    {
                        room.config = MatchConfig.FromDict(cfgMap);
                        foreach (OnlinePlayer p in room.players.Values)
                        {
                            p.hp = room.config.maxHp;
                            p.maxHp = room.config.maxHp;
                            p.lives = room.config.lives;
                            p.maxLives = room.config.lives;
                        }
                    }
                    Dictionary<string, object> packet = new Dictionary<string, object>();
                    packet["type"] = "config_update";
                    packet["config"] = room.config.ToDict();
                    packet["players"] = room.GetPlayersDictList();
                    BroadcastToRoom(room, serializer.Serialize(packet), null);
                    BroadcastRoomsListToLobby();
                }
                return;
            }

            if (type == "host_start_match")
            {
                lock (ServerLock)
                {
                    if (!sender.isHost || room.players.Count < 2) return;
                    StartRoomMatchLocked(room);
                }
                return;
            }

            // Check sessionId for in-match packets
            if (map.ContainsKey("sessionId") && type != "rematch_vote")
            {
                int packetSession = ToInt(map["sessionId"], room.sessionId);
                if (packetSession != room.sessionId)
                {
                    return;
                }
            }

            if (type == "state")
            {
                lock (ServerLock)
                {
                    if (!sender.isAlive)
                    {
                        sender.hp = 0.0;
                    }
                    else if (map.ContainsKey("hp"))
                    {
                        double incomingHp = ToDouble(map["hp"], sender.hp);
                        if (incomingHp < sender.hp)
                        {
                            sender.hp = Math.Max(0.0, Math.Min(sender.maxHp, incomingHp));
                        }
                    }
                    if (map.ContainsKey("ougi"))
                    {
                        sender.ougi = ToDouble(map["ougi"], sender.ougi);
                    }
                }
                BroadcastToRoom(room, jsonText, sender.id);
            }
            else if (type == "player_action" || type == "spawn_kunai" || type == "hit" || type == "ring_out_blast")
            {
                BroadcastToRoom(room, jsonText, sender.id);
            }
            else if (type == "player_stock_lost")
            {
                lock (ServerLock)
                {
                    int newLives = map.ContainsKey("lives") ? ToInt(map["lives"], sender.lives - 1) : (sender.lives - 1);
                    sender.lives = Math.Max(0, Math.Min(sender.maxLives, newLives));
                    sender.hp = sender.maxHp;
                }
                BroadcastToRoom(room, jsonText, sender.id);
            }
            else if (type == "player_eliminated")
            {
                lock (ServerLock)
                {
                    sender.hp = 0.0;
                    sender.lives = 0;
                    if (sender.isAlive)
                    {
                        sender.isAlive = false;
                        int aliveCount = 0;
                        foreach (OnlinePlayer p in room.players.Values)
                        {
                            if (p.isAlive) aliveCount++;
                        }
                        sender.placement = aliveCount + 1;

                        LogInfo("[" + room.roomName + "] " + sender.nickname + " fue eliminado (" + sender.placement + "° lugar).");

                        Dictionary<string, object> elimPacket = new Dictionary<string, object>();
                        elimPacket["type"] = "player_eliminated";
                        elimPacket["sessionId"] = room.sessionId;
                        elimPacket["id"] = sender.id;
                        elimPacket["nickname"] = sender.nickname;
                        elimPacket["placement"] = sender.placement;

                        BroadcastToRoom(room, serializer.Serialize(elimPacket), null);
                        CheckRoomMatchEndLocked(room);
                    }
                }
            }
            else if (type == "time_up")
            {
                lock (ServerLock)
                {
                    if (!room.inMatch || room.matchEnded) return;
                    TriggerTimeUpLocked(room);
                }
            }
            else if (type == "rematch_vote")
            {
                lock (ServerLock)
                {
                    bool voted = map.ContainsKey("voted") ? Convert.ToBoolean(map["voted"]) : !sender.votedRematch;
                    sender.votedRematch = voted;

                    Dictionary<string, object> remPacket = new Dictionary<string, object>();
                    remPacket["type"] = "rematch_update";
                    remPacket["players"] = room.GetPlayersDictList();
                    BroadcastToRoom(room, serializer.Serialize(remPacket), null);

                    CheckRoomRematchConditionLocked(room);
                }
            }
        }

        private static void HandleCreateOnlineRoom(ClientConnection conn, Dictionary<string, object> map)
        {
            RemovePlayerFromCurrentRoom(conn);
            JavaScriptSerializer serializer = new JavaScriptSerializer();

            lock (ServerLock)
            {
                string roomId = "room_" + (_nextRoomCounter++);
                string rawRoomName = map.ContainsKey("roomName") ? Convert.ToString(map["roomName"]).Trim() : "";
                string playerName = map.ContainsKey("name") ? Convert.ToString(map["name"]).Trim() : "Kaito";
                if (string.IsNullOrEmpty(playerName)) playerName = "Kaito";
                if (string.IsNullOrEmpty(rawRoomName)) rawRoomName = "Dojo Online de " + playerName;

                int colorIdx = map.ContainsKey("color") ? ToInt(map["color"], 0) : 0;
                Dictionary<string, object> cfgMap = map.ContainsKey("config")
                    ? map["config"] as Dictionary<string, object>
                    : null;
                MatchConfig cfg = MatchConfig.FromDict(cfgMap);

                OnlineRoom room = new OnlineRoom(roomId, rawRoomName, cfg);
                string pid = "p_" + (_nextPlayerCounter++);

                OnlinePlayer hostPlayer = new OnlinePlayer();
                hostPlayer.id = pid;
                hostPlayer.nickname = playerName;
                hostPlayer.colorIndex = colorIdx;
                hostPlayer.slot = 0;
                hostPlayer.isHost = true;
                hostPlayer.isAlive = true;
                hostPlayer.hp = cfg.maxHp;
                hostPlayer.maxHp = cfg.maxHp;
                hostPlayer.lives = cfg.lives;
                hostPlayer.maxLives = cfg.lives;
                hostPlayer.connection = conn;

                room.players[pid] = hostPlayer;
                Rooms[roomId] = room;
                conn.currentRoom = room;
                conn.currentPlayer = hostPlayer;

                LogSuccess("Nueva Sala Online creada: \"" + room.roomName + "\" [" + roomId + "] por " + playerName);

                Dictionary<string, object> welcome = new Dictionary<string, object>();
                welcome["type"] = "welcome";
                welcome["roomId"] = room.roomId;
                welcome["yourId"] = pid;
                welcome["slot"] = 0;
                welcome["isHost"] = true;
                welcome["roomName"] = room.roomName;
                welcome["config"] = room.config.ToDict();
                welcome["players"] = room.GetPlayersDictList();

                conn.SendWebSocketText(serializer.Serialize(welcome));
                BroadcastRoomsListToLobby();
            }
        }

        private static void HandleJoinOnlineRoom(ClientConnection conn, Dictionary<string, object> map)
        {
            RemovePlayerFromCurrentRoom(conn);
            JavaScriptSerializer serializer = new JavaScriptSerializer();

            lock (ServerLock)
            {
                string requestedRoomId = map.ContainsKey("roomId") ? Convert.ToString(map["roomId"]).Trim() : "";
                OnlineRoom targetRoom = null;

                if (!string.IsNullOrEmpty(requestedRoomId) && Rooms.ContainsKey(requestedRoomId))
                {
                    targetRoom = Rooms[requestedRoomId];
                }
                else
                {
                    // Quick join or direct connect: pick first available waiting room, or create one if none exist
                    foreach (OnlineRoom r in Rooms.Values)
                    {
                        if (!r.inMatch && r.players.Count < MaxPlayersPerRoom)
                        {
                            targetRoom = r;
                            break;
                        }
                    }
                    if (targetRoom == null && string.IsNullOrEmpty(requestedRoomId))
                    {
                        HandleCreateOnlineRoom(conn, map);
                        return;
                    }
                }

                if (targetRoom == null)
                {
                    Dictionary<string, object> err = new Dictionary<string, object>();
                    err["type"] = "error";
                    err["msg"] = "La sala seleccionada ya no existe.";
                    conn.SendWebSocketText(serializer.Serialize(err));
                    SendRoomsListToClient(conn);
                    return;
                }

                if (targetRoom.players.Count >= MaxPlayersPerRoom)
                {
                    Dictionary<string, object> err = new Dictionary<string, object>();
                    err["type"] = "error";
                    err["msg"] = "La sala está llena (Máximo 5 jugadores).";
                    conn.SendWebSocketText(serializer.Serialize(err));
                    return;
                }

                if (targetRoom.inMatch)
                {
                    Dictionary<string, object> err = new Dictionary<string, object>();
                    err["type"] = "error";
                    err["msg"] = "La partida en esta sala ya está en curso.";
                    conn.SendWebSocketText(serializer.Serialize(err));
                    return;
                }

                string playerName = map.ContainsKey("name") ? Convert.ToString(map["name"]).Trim() : "Shinobi";
                if (string.IsNullOrEmpty(playerName)) playerName = "Shinobi";
                int colorIdx = map.ContainsKey("color") ? ToInt(map["color"], 1) : 1;

                // Find lowest available slot 0..4
                HashSet<int> usedSlots = new HashSet<int>();
                foreach (OnlinePlayer existing in targetRoom.players.Values)
                {
                    usedSlots.Add(existing.slot);
                }
                int assignedSlot = 0;
                for (int s = 0; s < MaxPlayersPerRoom; s++)
                {
                    if (!usedSlots.Contains(s))
                    {
                        assignedSlot = s;
                        break;
                    }
                }

                string pid = "p_" + (_nextPlayerCounter++);
                bool isFirstPlayer = targetRoom.players.Count == 0;

                OnlinePlayer newPlayer = new OnlinePlayer();
                newPlayer.id = pid;
                newPlayer.nickname = playerName;
                newPlayer.colorIndex = colorIdx;
                newPlayer.slot = assignedSlot;
                newPlayer.isHost = isFirstPlayer;
                newPlayer.isAlive = true;
                newPlayer.hp = targetRoom.config.maxHp;
                newPlayer.maxHp = targetRoom.config.maxHp;
                newPlayer.lives = targetRoom.config.lives;
                newPlayer.maxLives = targetRoom.config.lives;
                newPlayer.connection = conn;

                targetRoom.players[pid] = newPlayer;
                conn.currentRoom = targetRoom;
                conn.currentPlayer = newPlayer;

                LogInfo("Jugador \"" + playerName + "\" se unio a \"" + targetRoom.roomName + "\" (" + targetRoom.players.Count + "/5) [Slot " + (assignedSlot + 1) + "]");

                List<Dictionary<string, object>> playersList = targetRoom.GetPlayersDictList();

                Dictionary<string, object> welcome = new Dictionary<string, object>();
                welcome["type"] = "welcome";
                welcome["roomId"] = targetRoom.roomId;
                welcome["yourId"] = pid;
                welcome["slot"] = assignedSlot;
                welcome["isHost"] = newPlayer.isHost;
                welcome["roomName"] = targetRoom.roomName;
                welcome["config"] = targetRoom.config.ToDict();
                welcome["players"] = playersList;
                conn.SendWebSocketText(serializer.Serialize(welcome));

                Dictionary<string, object> lobbyUpdate = new Dictionary<string, object>();
                lobbyUpdate["type"] = "lobby_update";
                lobbyUpdate["config"] = targetRoom.config.ToDict();
                lobbyUpdate["players"] = playersList;
                BroadcastToRoom(targetRoom, serializer.Serialize(lobbyUpdate), pid);

                BroadcastRoomsListToLobby();
            }
        }

        private static void StartRoomMatchLocked(OnlineRoom room)
        {
            room.StopTimers();
            room.inMatch = true;
            room.matchEnded = false;
            room.sessionId = room.sessionId + 1;

            foreach (OnlinePlayer p in room.players.Values)
            {
                p.isAlive = true;
                p.hp = room.config.maxHp;
                p.maxHp = room.config.maxHp;
                p.lives = room.config.lives;
                p.maxLives = room.config.lives;
                p.ougi = 0.0;
                p.placement = 0;
                p.votedRematch = false;
            }

            LogSuccess("¡Combate iniciado en la sala \"" + room.roomName + "\"! (" + room.players.Count + " Shinobis, Sesion #" + room.sessionId + ")");

            JavaScriptSerializer serializer = new JavaScriptSerializer();
            Dictionary<string, object> startPacket = new Dictionary<string, object>();
            startPacket["type"] = "match_start";
            startPacket["sessionId"] = room.sessionId;
            startPacket["config"] = room.config.ToDict();
            startPacket["players"] = room.GetPlayersDictList();

            BroadcastToRoom(room, serializer.Serialize(startPacket), null);
            BroadcastRoomsListToLobby();
        }

        private static void TriggerTimeUpLocked(OnlineRoom room)
        {
            if (room.matchEnded) return;
            room.matchEnded = true;

            List<OnlinePlayer> alive = new List<OnlinePlayer>();
            foreach (OnlinePlayer p in room.players.Values)
            {
                if (p.isAlive) alive.Add(p);
            }

            alive.Sort(delegate(OnlinePlayer a, OnlinePlayer b)
            {
                int lifeCmp = b.lives.CompareTo(a.lives);
                if (lifeCmp != 0) return lifeCmp;
                return b.hp.CompareTo(a.hp);
            });

            for (int i = 0; i < alive.Count; i++)
            {
                alive[i].placement = i + 1;
                if (i > 0) alive[i].isAlive = false;
            }

            AnnounceRoomVictoryAndPodiumLocked(room);
        }

        private static void CheckRoomMatchEndLocked(OnlineRoom room)
        {
            if (!room.inMatch || room.matchEnded) return;

            List<OnlinePlayer> alive = new List<OnlinePlayer>();
            foreach (OnlinePlayer p in room.players.Values)
            {
                if (p.isAlive) alive.Add(p);
            }

            if (alive.Count <= 1)
            {
                room.matchEnded = true;
                if (alive.Count == 1)
                {
                    alive[0].placement = 1;
                }
                AnnounceRoomVictoryAndPodiumLocked(room);
            }
        }

        private static void AnnounceRoomVictoryAndPodiumLocked(OnlineRoom room)
        {
            List<OnlinePlayer> podium = new List<OnlinePlayer>(room.players.Values);
            podium.Sort(delegate(OnlinePlayer a, OnlinePlayer b)
            {
                int pa = a.placement <= 0 ? 999 : a.placement;
                int pb = b.placement <= 0 ? 999 : b.placement;
                return pa.CompareTo(pb);
            });

            if (podium.Count > 0 && podium[0].placement != 1)
            {
                podium[0].placement = 1;
            }

            OnlinePlayer winner = podium.Count > 0 ? podium[0] : null;
            if (winner != null)
            {
                LogSuccess("[" + room.roomName + "] ¡CAMPEÓN DE LA PARTIDA: " + winner.nickname + "!");
            }

            JavaScriptSerializer serializer = new JavaScriptSerializer();

            Dictionary<string, object> victoryPacket = new Dictionary<string, object>();
            victoryPacket["type"] = "match_victory";
            victoryPacket["winner"] = winner != null ? winner.ToDict() : null;
            BroadcastToRoom(room, serializer.Serialize(victoryPacket), null);

            List<Dictionary<string, object>> podiumDicts = new List<Dictionary<string, object>>();
            foreach (OnlinePlayer p in podium)
            {
                podiumDicts.Add(p.ToDict());
            }

            Dictionary<string, object> resultsPacket = new Dictionary<string, object>();
            resultsPacket["type"] = "match_results";
            resultsPacket["podium"] = podiumDicts;
            string resultsJson = serializer.Serialize(resultsPacket);

            if (room.victoryDelayTimer != null)
            {
                try { room.victoryDelayTimer.Dispose(); } catch { }
            }

            room.victoryDelayTimer = new Timer(delegate(object state)
            {
                lock (ServerLock)
                {
                    if (!Rooms.ContainsKey(room.roomId)) return;
                    room.inMatch = false;
                    BroadcastToRoom(room, resultsJson, null);
                    BroadcastRoomsListToLobby();
                }
            }, null, VictoryCelebrationMs, Timeout.Infinite);
        }

        private static void CheckRoomRematchConditionLocked(OnlineRoom room)
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            int readyCount = 0;
            foreach (OnlinePlayer p in room.players.Values)
            {
                if (p.votedRematch) readyCount++;
            }

            if (readyCount < 2 || room.players.Count < 2)
            {
                if (room.rematchTimer != null)
                {
                    try { room.rematchTimer.Dispose(); } catch { }
                    room.rematchTimer = null;
                    Dictionary<string, object> cancelPkt = new Dictionary<string, object>();
                    cancelPkt["type"] = "rematch_countdown";
                    cancelPkt["seconds"] = null;
                    BroadcastToRoom(room, serializer.Serialize(cancelPkt), null);
                }
                return;
            }

            if (room.rematchTimer == null)
            {
                room.rematchSeconds = RematchCountdownSeconds;
                Dictionary<string, object> startCountdown = new Dictionary<string, object>();
                startCountdown["type"] = "rematch_countdown";
                startCountdown["seconds"] = room.rematchSeconds;
                BroadcastToRoom(room, serializer.Serialize(startCountdown), null);

                room.rematchTimer = new Timer(delegate(object state)
                {
                    lock (ServerLock)
                    {
                        if (!Rooms.ContainsKey(room.roomId)) return;
                        int currentReady = 0;
                        foreach (OnlinePlayer p in room.players.Values)
                        {
                            if (p.votedRematch) currentReady++;
                        }
                        if (currentReady < 2 || room.players.Count < 2)
                        {
                            if (room.rematchTimer != null)
                            {
                                try { room.rematchTimer.Dispose(); } catch { }
                                room.rematchTimer = null;
                            }
                            Dictionary<string, object> cancelPkt = new Dictionary<string, object>();
                            cancelPkt["type"] = "rematch_countdown";
                            cancelPkt["seconds"] = null;
                            BroadcastToRoom(room, serializer.Serialize(cancelPkt), null);
                            return;
                        }

                        room.rematchSeconds--;
                        if (room.rematchSeconds <= 0)
                        {
                            if (room.rematchTimer != null)
                            {
                                try { room.rematchTimer.Dispose(); } catch { }
                                room.rematchTimer = null;
                            }
                            StartRoomMatchLocked(room);
                        }
                        else
                        {
                            Dictionary<string, object> tickPkt = new Dictionary<string, object>();
                            tickPkt["type"] = "rematch_countdown";
                            tickPkt["seconds"] = room.rematchSeconds;
                            BroadcastToRoom(room, serializer.Serialize(tickPkt), null);
                        }
                    }
                }, null, 1000, 1000);
            }
        }

        private static void HandleClientDisconnect(ClientConnection conn)
        {
            conn.Close();
            lock (ServerLock)
            {
                Clients.Remove(conn.connectionId);
            }
            RemovePlayerFromCurrentRoom(conn);
        }

        private static void RemovePlayerFromCurrentRoom(ClientConnection conn)
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            lock (ServerLock)
            {
                OnlineRoom room = conn.currentRoom;
                OnlinePlayer player = conn.currentPlayer;
                conn.currentRoom = null;
                conn.currentPlayer = null;

                if (room == null || player == null) return;

                if (room.players.ContainsKey(player.id))
                {
                    room.players.Remove(player.id);
                    LogInfo("Jugador \"" + player.nickname + "\" salio de la sala \"" + room.roomName + "\".");
                }

                if (room.players.Count == 0)
                {
                    room.StopTimers();
                    Rooms.Remove(room.roomId);
                    LogInfo("Sala \"" + room.roomName + "\" cerrada (0 jugadores).");
                    BroadcastRoomsListToLobby();
                    return;
                }

                // If host left, promote lowest slot remaining player to Host
                bool hasHost = false;
                foreach (OnlinePlayer p in room.players.Values)
                {
                    if (p.isHost) { hasHost = true; break; }
                }
                if (!hasHost)
                {
                    OnlinePlayer nextHost = null;
                    foreach (OnlinePlayer p in room.players.Values)
                    {
                        if (nextHost == null || p.slot < nextHost.slot)
                        {
                            nextHost = p;
                        }
                    }
                    if (nextHost != null)
                    {
                        nextHost.isHost = true;
                        LogInfo("[" + room.roomName + "] \"" + nextHost.nickname + "\" es el nuevo Anfitrion de la sala.");
                    }
                }

                Dictionary<string, object> lobbyUpdate = new Dictionary<string, object>();
                lobbyUpdate["type"] = "lobby_update";
                lobbyUpdate["config"] = room.config.ToDict();
                lobbyUpdate["players"] = room.GetPlayersDictList();
                BroadcastToRoom(room, serializer.Serialize(lobbyUpdate), null);

                if (room.inMatch && !room.matchEnded)
                {
                    CheckRoomMatchEndLocked(room);
                }
                else if (room.matchEnded && room.players.Count < 2)
                {
                    room.inMatch = false;
                    room.matchEnded = false;
                }
                if (room.rematchTimer != null)
                {
                    CheckRoomRematchConditionLocked(room);
                }

                BroadcastRoomsListToLobby();
            }
        }

        private static void BroadcastToRoom(OnlineRoom room, string jsonText, string excludePlayerId)
        {
            List<OnlinePlayer> targets;
            lock (ServerLock)
            {
                targets = new List<OnlinePlayer>(room.players.Values);
            }
            foreach (OnlinePlayer p in targets)
            {
                if (excludePlayerId != null && p.id == excludePlayerId) continue;
                if (p.connection != null && !p.connection.isClosed)
                {
                    p.connection.SendWebSocketText(jsonText);
                }
            }
        }

        private static string BuildStatusJson()
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            List<string> ips = GetLocalIPv4Addresses();
            string primaryIp = ips.Count > 0 ? ips[0] : "127.0.0.1";

            lock (ServerLock)
            {
                List<Dictionary<string, object>> roomSummaries = new List<Dictionary<string, object>>();
                foreach (OnlineRoom r in Rooms.Values)
                {
                    roomSummaries.Add(r.ToSummaryDict());
                }

                Dictionary<string, object> status = new Dictionary<string, object>();
                status["type"] = "kaito_online_status";
                status["online"] = true;
                status["serverName"] = ServerName;
                status["ip"] = primaryIp;
                status["port"] = TcpPort;
                status["connectedClients"] = Clients.Count;
                status["roomCount"] = Rooms.Count;
                status["rooms"] = roomSummaries;
                return serializer.Serialize(status);
            }
        }

        private static string BuildRoomsListPacketJson()
        {
            JavaScriptSerializer serializer = new JavaScriptSerializer();
            lock (ServerLock)
            {
                List<Dictionary<string, object>> roomSummaries = new List<Dictionary<string, object>>();
                foreach (OnlineRoom r in Rooms.Values)
                {
                    roomSummaries.Add(r.ToSummaryDict());
                }

                Dictionary<string, object> pkt = new Dictionary<string, object>();
                pkt["type"] = "online_rooms_list";
                pkt["serverName"] = ServerName;
                pkt["port"] = TcpPort;
                pkt["connectedClients"] = Clients.Count;
                pkt["roomCount"] = Rooms.Count;
                pkt["rooms"] = roomSummaries;
                return serializer.Serialize(pkt);
            }
        }

        private static void SendRoomsListToClient(ClientConnection conn)
        {
            string json = BuildRoomsListPacketJson();
            conn.SendWebSocketText(json);
        }

        private static void BroadcastRoomsListToLobby()
        {
            string json = BuildRoomsListPacketJson();
            List<ClientConnection> lobbyClients = new List<ClientConnection>();
            lock (ServerLock)
            {
                foreach (ClientConnection c in Clients.Values)
                {
                    if (!c.isClosed && c.currentRoom == null)
                    {
                        lobbyClients.Add(c);
                    }
                }
            }
            foreach (ClientConnection c in lobbyClients)
            {
                c.SendWebSocketText(json);
            }
        }

        private static int ToInt(object val, int fallback)
        {
            if (val == null) return fallback;
            try { return Convert.ToInt32(val); } catch { return fallback; }
        }

        private static double ToDouble(object val, double fallback)
        {
            if (val == null) return fallback;
            try { return Convert.ToDouble(val); } catch { return fallback; }
        }

        private static void LogInfo(string msg)
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.Write("[" + DateTime.Now.ToString("HH:mm:ss") + "] [INFO] ");
            Console.ResetColor();
            Console.WriteLine(msg);
        }

        private static void LogSuccess(string msg)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write("[" + DateTime.Now.ToString("HH:mm:ss") + "] [OK]   ");
            Console.ResetColor();
            Console.WriteLine(msg);
        }

        private static void LogError(string msg)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.Write("[" + DateTime.Now.ToString("HH:mm:ss") + "] [ERR]  ");
            Console.ResetColor();
            Console.WriteLine(msg);
        }
    }
}
