// ============================================================================
//  KAITO ADVENTURE: INK SHINOBI - SERVIDOR MULTIPLAYER ONLINE (ULTRA LOW-LATENCY)
//
//  Optimizaciones clave contra lag y retraso acumulado en peleas intensas:
//   1. Doble cola por cliente con Prioridad Estricta:
//      - Cola de Eventos (_eventQueue): hit, player_action, spawn_kunai, ring_out_blast,
//        eliminaciones y control de sala salen SIEMPRE PRIMERO con 0 ms de espera.
//      - Ranuras O(1) de Estado (_latestStates[0..4]): las posiciones "state" nunca
//        hacen fila ni asignan memoria; cada ranura guarda solo el ultimo frame por slot.
//   2. Coalescencia y Pacing en el Servidor (MinStateIntervalMs = 28 ms / ~35 Hz):
//      Como el puente SSH corre en localhost (127.0.0.1), escribir sin control llenaba
//      la ventana interna de 2 MB de ssh.exe durante lluvias de ataques, causando
//      segundos de retraso (bufferbloat). Ahora el servidor deja pasar el movimiento
//      normal (~33 ms) con 0 ms extra y fusiona en memoria las rafagas de "state"
//      menores a 28 ms antes de tocar el socket de ssh.exe; StateFlushLoop entrega
//      cualquier estado pendiente puntualmente.
//   3. Ruta rapida 100% Lock-Free (sin ServerLock en state/hit/player_action/kunai).
//   4. Tunel SSH optimizado con -o IPQoS=lowdelay -o Compression=no y SendBuffer de 8 KB.
// ============================================================================

using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;

namespace KaitoOnlineServer
{
    // ========================================================================
    //  MODELOS
    // ========================================================================
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
        public volatile bool isAlive;
        public double hp;
        public double maxHp;
        public int lives;
        public int maxLives;
        public double ougi;
        public int placement;
        public bool votedRematch;
        public ClientConnection connection;

        // Control de pacing y coalescencia de "state" en el servidor (evita saturar ssh.exe)
        public readonly object statePacingLock = new object();
        public volatile byte[] pendingStateFrame;
        public int lastStateBroadcastTick;

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
            pendingStateFrame = null;
            lastStateBroadcastTick = Environment.TickCount - 1000;
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
        public volatile int sessionId;
        public volatile bool inMatch;
        public volatile bool matchEnded;
        public Timer victoryDelayTimer;
        public Timer rematchTimer;
        public int rematchSeconds;
        public DateTime createdAt;

        // Copia inmutable de los jugadores: permite hacer broadcast sin lock y sin asignar memoria.
        public volatile OnlinePlayer[] snapshot;

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
            snapshot = new OnlinePlayer[0];
        }

        // Llamar SIEMPRE con ServerLock tomado, despues de agregar o quitar jugadores.
        public void RefreshSnapshot()
        {
            OnlinePlayer[] arr = new OnlinePlayer[players.Count];
            players.Values.CopyTo(arr, 0);
            snapshot = arr;
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

    // ========================================================================
    //  FRAMES WEBSOCKET (se arman una sola vez y se comparten entre destinatarios)
    // ========================================================================
    internal static class WsFrame
    {
        public static byte[] BuildText(string text)
        {
            int byteCount = Encoding.UTF8.GetByteCount(text);
            int headerLen = HeaderLength(byteCount);
            byte[] frame = new byte[headerLen + byteCount];
            WriteHeader(frame, 0x81, byteCount);
            Encoding.UTF8.GetBytes(text, 0, text.Length, frame, headerLen);
            return frame;
        }

        public static byte[] BuildText(byte[] payload, int offset, int length)
        {
            int headerLen = HeaderLength(length);
            byte[] frame = new byte[headerLen + length];
            WriteHeader(frame, 0x81, length);
            if (length > 0) Buffer.BlockCopy(payload, offset, frame, headerLen, length);
            return frame;
        }

        public static byte[] BuildControl(byte opcode, byte[] payload, int length)
        {
            int len = Math.Min(length, 125);
            if (len < 0) len = 0;
            byte[] frame = new byte[2 + len];
            frame[0] = (byte)(0x80 | opcode);
            frame[1] = (byte)len;
            if (len > 0) Buffer.BlockCopy(payload, 0, frame, 2, len);
            return frame;
        }

        private static int HeaderLength(int payloadLen)
        {
            if (payloadLen < 126) return 2;
            if (payloadLen <= 65535) return 4;
            return 10;
        }

        private static void WriteHeader(byte[] frame, byte firstByte, int payloadLen)
        {
            frame[0] = firstByte;
            if (payloadLen < 126)
            {
                frame[1] = (byte)payloadLen;
            }
            else if (payloadLen <= 65535)
            {
                frame[1] = 126;
                frame[2] = (byte)((payloadLen >> 8) & 0xFF);
                frame[3] = (byte)(payloadLen & 0xFF);
            }
            else
            {
                frame[1] = 127;
                long len = payloadLen;
                for (int i = 0; i < 8; i++)
                {
                    frame[9 - i] = (byte)(len & 0xFF);
                    len >>= 8;
                }
            }
        }
    }

    // ========================================================================
    //  LECTOR JSON MINIMO PARA LA RUTA RAPIDA (100% LOCK-FREE)
    // ========================================================================
    internal struct FastInfo
    {
        public int typeCode;
        public bool hasSession;
        public int session;
        public bool hasHp;
        public double hp;
        public bool hasOugi;
        public double ougi;
    }

    internal static class FastJson
    {
        public const int T_UNKNOWN = 0;
        public const int T_STATE = 1;
        public const int T_ACTION = 2;
        public const int T_KUNAI = 3;
        public const int T_HIT = 4;
        public const int T_RINGOUT = 5;

        private static readonly byte[] KType = Encoding.ASCII.GetBytes("type");
        private static readonly byte[] KSession = Encoding.ASCII.GetBytes("sessionId");
        private static readonly byte[] KHp = Encoding.ASCII.GetBytes("hp");
        private static readonly byte[] KOugi = Encoding.ASCII.GetBytes("ougi");

        private static readonly byte[] VState = Encoding.ASCII.GetBytes("state");
        private static readonly byte[] VAction = Encoding.ASCII.GetBytes("player_action");
        private static readonly byte[] VKunai = Encoding.ASCII.GetBytes("spawn_kunai");
        private static readonly byte[] VHit = Encoding.ASCII.GetBytes("hit");
        private static readonly byte[] VRingOut = Encoding.ASCII.GetBytes("ring_out_blast");

        private static bool IsWs(byte c)
        {
            return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;
        }

        private static bool Eq(byte[] b, int start, int count, byte[] lit)
        {
            if (count != lit.Length) return false;
            for (int i = 0; i < count; i++)
            {
                if (b[start + i] != lit[i]) return false;
            }
            return true;
        }

        private static int SkipString(byte[] b, int len, int i)
        {
            int j = i + 1;
            while (j < len)
            {
                byte c = b[j];
                if (c == 0x5C) { j += 2; continue; }
                if (c == 0x22) return j + 1;
                j++;
            }
            return -1;
        }

        private static int SkipContainer(byte[] b, int len, int i)
        {
            int depth = 0;
            int j = i;
            while (j < len)
            {
                byte c = b[j];
                if (c == 0x22)
                {
                    j = SkipString(b, len, j);
                    if (j < 0) return -1;
                    continue;
                }
                if (c == 0x7B || c == 0x5B)
                {
                    depth++;
                }
                else if (c == 0x7D || c == 0x5D)
                {
                    depth--;
                    if (depth == 0) return j + 1;
                }
                j++;
            }
            return -1;
        }

        private static bool ParseNumber(byte[] b, int start, int end, out double value)
        {
            value = 0.0;
            int count = end - start;
            if (count <= 0 || count > 40) return false;

            int p = start;
            bool neg = false;
            if (b[p] == 0x2D) { neg = true; p++; }
            long acc = 0;
            int digits = 0;
            while (p < end && b[p] >= 0x30 && b[p] <= 0x39 && digits < 15)
            {
                acc = acc * 10 + (b[p] - 0x30);
                p++;
                digits++;
            }
            if (digits > 0 && p == end)
            {
                value = neg ? -(double)acc : (double)acc;
                return true;
            }
            if (digits > 0 && p < end && b[p] == 0x2E)
            {
                p++;
                double frac = 0.0;
                double div = 10.0;
                int fdigits = 0;
                while (p < end && b[p] >= 0x30 && b[p] <= 0x39 && fdigits < 10)
                {
                    frac += (b[p] - 0x30) / div;
                    div *= 10.0;
                    p++;
                    fdigits++;
                }
                if (p == end)
                {
                    double res = acc + frac;
                    value = neg ? -res : res;
                    return true;
                }
            }

            byte f = b[start];
            if (!((f >= 0x30 && f <= 0x39) || f == 0x2D)) return false;
            string s = Encoding.ASCII.GetString(b, start, count);
            return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
        }

        private static int TypeCodeOf(byte[] b, int start, int count)
        {
            if (Eq(b, start, count, VState)) return T_STATE;
            if (Eq(b, start, count, VAction)) return T_ACTION;
            if (Eq(b, start, count, VKunai)) return T_KUNAI;
            if (Eq(b, start, count, VHit)) return T_HIT;
            if (Eq(b, start, count, VRingOut)) return T_RINGOUT;
            return T_UNKNOWN;
        }

        public static bool Scan(byte[] b, int len, ref FastInfo info)
        {
            int i = 0;
            while (i < len && IsWs(b[i])) i++;
            if (i >= len || b[i] != 0x7B) return false;
            i++;

            while (i < len)
            {
                byte c = b[i];
                if (c == 0x2C || IsWs(c)) { i++; continue; }
                if (c == 0x7D) return true;
                if (c != 0x22) return false;

                int keyStart = i + 1;
                int afterKey = SkipString(b, len, i);
                if (afterKey < 0) return false;
                int keyLen = afterKey - 1 - keyStart;
                i = afterKey;
                while (i < len && IsWs(b[i])) i++;
                if (i >= len || b[i] != 0x3A) return false;
                i++;
                while (i < len && IsWs(b[i])) i++;
                if (i >= len) return false;

                int key = 0;
                if (Eq(b, keyStart, keyLen, KType)) key = 1;
                else if (Eq(b, keyStart, keyLen, KSession)) key = 2;
                else if (Eq(b, keyStart, keyLen, KHp)) key = 3;
                else if (Eq(b, keyStart, keyLen, KOugi)) key = 4;

                c = b[i];
                if (c == 0x22)
                {
                    int vStart = i + 1;
                    int afterVal = SkipString(b, len, i);
                    if (afterVal < 0) return false;
                    if (key == 1) info.typeCode = TypeCodeOf(b, vStart, afterVal - 1 - vStart);
                    i = afterVal;
                }
                else if (c == 0x7B || c == 0x5B)
                {
                    i = SkipContainer(b, len, i);
                    if (i < 0) return false;
                }
                else
                {
                    int vStart2 = i;
                    while (i < len && b[i] != 0x2C && b[i] != 0x7D && !IsWs(b[i])) i++;
                    if (key >= 2)
                    {
                        double d;
                        if (ParseNumber(b, vStart2, i, out d))
                        {
                            if (key == 2)
                            {
                                info.hasSession = true;
                                info.session = (d > int.MaxValue || d < int.MinValue) ? int.MinValue : (int)d;
                            }
                            else if (key == 3)
                            {
                                info.hasHp = true;
                                info.hp = d;
                            }
                            else
                            {
                                info.hasOugi = true;
                                info.ougi = d;
                            }
                        }
                    }
                }
            }
            return false;
        }
    }

    // ========================================================================
    //  CONEXION DE CLIENTE CON PRIORIDAD ESTRICTA EVENTOS > ESTADOS O(1)
    // ========================================================================
    public class ClientConnection
    {
        public string connectionId;
        public TcpClient tcpClient;
        public NetworkStream stream;
        public string remoteEndpoint;
        public OnlineRoom currentRoom;
        public OnlinePlayer currentPlayer;
        public bool isWebSocket;
        public volatile bool isClosed;
        public volatile int lastRecvTick;
        public double rttMs;

        // --- recepcion ---
        private readonly byte[] _rbuf = new byte[8192];
        private int _rpos;
        private int _rlen;
        public byte[] payloadBuf = new byte[4096];
        public readonly byte[] maskKey = new byte[4];
        public readonly byte[] extBuf = new byte[8];
        public int rateWindowStart;
        public int rateCount;

        // --- envio con doble prioridad ---
        private readonly object _qLock = new object();
        // Prioridad 1: Eventos de combate (hit, slash, kunai, ougi, salas)
        private readonly Queue<byte[]> _eventQueue = new Queue<byte[]>(64);
        private int _queuedEventBytes;
        // Prioridad 2: Ultimo "state" por ranura de jugador (0..4) + 1 ranura para ping y 1 para rooms
        private readonly byte[][] _latestSlots = new byte[8][];
        private int _dirtySlotsMask;

        private byte[] _scratch = new byte[8192];
        private Thread _writerThread;
        private int _closeOnce;

        public ClientConnection(string id, TcpClient client)
        {
            connectionId = id;
            tcpClient = client;
            try { client.NoDelay = true; } catch { }
            try { client.SendBufferSize = 8192; } catch { }
            try { client.ReceiveBufferSize = 16384; } catch { }
            try { client.SendTimeout = 10000; } catch { }
            stream = client.GetStream();
            string ep = "unknown";
            try
            {
                if (client.Client.RemoteEndPoint != null) ep = client.Client.RemoteEndPoint.ToString();
            }
            catch { }
            remoteEndpoint = ep;
            isWebSocket = false;
            isClosed = false;
            lastRecvTick = Environment.TickCount;
        }

        // ------------------------------ recepcion ------------------------------
        public int ReadByteBuffered()
        {
            if (_rpos >= _rlen)
            {
                int n = stream.Read(_rbuf, 0, _rbuf.Length);
                if (n <= 0) return -1;
                _rpos = 0;
                _rlen = n;
            }
            return _rbuf[_rpos++];
        }

        public bool ReadExactBuffered(byte[] dst, int count)
        {
            int got = 0;
            while (got < count)
            {
                if (_rpos >= _rlen)
                {
                    int remaining = count - got;
                    if (remaining >= _rbuf.Length)
                    {
                        int direct = stream.Read(dst, got, remaining);
                        if (direct <= 0) return false;
                        got += direct;
                        continue;
                    }
                    int n = stream.Read(_rbuf, 0, _rbuf.Length);
                    if (n <= 0) return false;
                    _rpos = 0;
                    _rlen = n;
                }
                int take = Math.Min(_rlen - _rpos, count - got);
                Buffer.BlockCopy(_rbuf, _rpos, dst, got, take);
                _rpos += take;
                got += take;
            }
            return true;
        }

        public byte[] EnsurePayloadCapacity(int needed)
        {
            if (payloadBuf.Length < needed)
            {
                int newSize = Math.Max(needed, payloadBuf.Length * 2);
                payloadBuf = new byte[newSize];
            }
            return payloadBuf;
        }

        // -------------------------------- envio --------------------------------
        public void StartWriter()
        {
            if (_writerThread != null) return;
            _writerThread = new Thread(WriterLoop);
            _writerThread.IsBackground = true;
            _writerThread.Priority = ThreadPriority.AboveNormal;
            _writerThread.Name = "ws-writer-" + connectionId;
            _writerThread.Start();
        }

        // Encola un evento de combate o control (Prioridad 1: sale antes que cualquier "state").
        public void EnqueueEvent(byte[] frame)
        {
            if (isClosed || !isWebSocket || frame == null) return;
            bool overflow = false;
            lock (_qLock)
            {
                if (isClosed) return;
                if (_queuedEventBytes + frame.Length > Program.MaxQueuedBytesPerClient)
                {
                    overflow = true;
                }
                else
                {
                    _eventQueue.Enqueue(frame);
                    _queuedEventBytes += frame.Length;
                    Monitor.Pulse(_qLock);
                }
            }
            if (overflow) Close();
        }

        // Guarda en O(1) el ultimo estado de una ranura (0..4 = jugadores, 5 = ping, 6 = rooms).
        // Cero asignaciones de memoria y cero acumulacion de cola.
        public void EnqueueSlotState(int slotIndex, byte[] frame)
        {
            if (isClosed || !isWebSocket || frame == null) return;
            int idx = (slotIndex >= 0 && slotIndex < _latestSlots.Length) ? slotIndex : 0;
            lock (_qLock)
            {
                if (isClosed) return;
                _latestSlots[idx] = frame;
                _dirtySlotsMask |= (1 << idx);
                Monitor.Pulse(_qLock);
            }
        }

        public void SendWebSocketText(string jsonText)
        {
            EnqueueEvent(WsFrame.BuildText(jsonText));
        }

        public void SendPong(byte[] pingPayload, int length)
        {
            EnqueueEvent(WsFrame.BuildControl(0x0A, pingPayload, length));
        }

        public void SendPing()
        {
            long stamp = Stopwatch.GetTimestamp();
            byte[] p = new byte[8];
            for (int i = 0; i < 8; i++)
            {
                p[7 - i] = (byte)((stamp >> (8 * i)) & 0xFF);
            }
            EnqueueSlotState(5, WsFrame.BuildControl(0x09, p, 8));
        }

        public void OnPong(byte[] payload, int length)
        {
            if (length != 8) return;
            long stamp = 0;
            for (int i = 0; i < 8; i++)
            {
                stamp = (stamp << 8) | payload[i];
            }
            double ms = (Stopwatch.GetTimestamp() - stamp) * 1000.0 / Stopwatch.Frequency;
            if (ms < 0.0 || ms > 60000.0) return;
            rttMs = rttMs <= 0.0 ? ms : (rttMs * 0.7 + ms * 0.3);
        }

        private void WriterLoop()
        {
            List<byte[]> batch = new List<byte[]>(16);
            while (true)
            {
                batch.Clear();
                lock (_qLock)
                {
                    while (_eventQueue.Count == 0 && _dirtySlotsMask == 0 && !isClosed)
                    {
                        Monitor.Wait(_qLock);
                    }
                    if (isClosed) return;

                    // 1. Drenar TODOS los eventos prioritarios primero (ataques, impactos, kunais, salas)
                    while (_eventQueue.Count > 0)
                    {
                        batch.Add(_eventQueue.Dequeue());
                    }
                    _queuedEventBytes = 0;

                    // 2. Drenar solo el ultimo "state" de cada ranura sucia
                    if (_dirtySlotsMask != 0)
                    {
                        for (int i = 0; i < _latestSlots.Length; i++)
                        {
                            if ((_dirtySlotsMask & (1 << i)) != 0)
                            {
                                byte[] sFrame = _latestSlots[i];
                                _latestSlots[i] = null;
                                if (sFrame != null) batch.Add(sFrame);
                            }
                        }
                        _dirtySlotsMask = 0;
                    }
                }

                try
                {
                    WriteBatch(batch);
                }
                catch
                {
                    Close();
                    return;
                }
            }
        }

        private void WriteBatch(List<byte[]> batch)
        {
            int count = batch.Count;
            if (count == 0) return;
            if (count == 1)
            {
                byte[] only = batch[0];
                stream.Write(only, 0, only.Length);
                return;
            }

            int total = 0;
            for (int i = 0; i < count; i++)
            {
                total += batch[i].Length;
            }

            if (total > 32768)
            {
                for (int i = 0; i < count; i++)
                {
                    byte[] big = batch[i];
                    stream.Write(big, 0, big.Length);
                }
                return;
            }

            if (_scratch.Length < total) _scratch = new byte[total + 1024];
            int off = 0;
            for (int i = 0; i < count; i++)
            {
                byte[] d = batch[i];
                Buffer.BlockCopy(d, 0, _scratch, off, d.Length);
                off += d.Length;
            }
            stream.Write(_scratch, 0, total);
        }

        public void Close()
        {
            if (Interlocked.Exchange(ref _closeOnce, 1) == 1) return;
            isClosed = true;
            lock (_qLock)
            {
                _eventQueue.Clear();
                _queuedEventBytes = 0;
                for (int i = 0; i < _latestSlots.Length; i++) _latestSlots[i] = null;
                _dirtySlotsMask = 0;
                Monitor.PulseAll(_qLock);
            }
            try { stream.Close(); } catch { }
            try { tcpClient.Close(); } catch { }
        }
    }

    // ========================================================================
    //  PROGRAMA PRINCIPAL
    // ========================================================================
    class Program
    {
        public static int TcpPort = 7779;
        public static int UdpDiscoveryPort = 7780;
        public const int MaxPlayersPerRoom = 5;
        public const int RematchCountdownSeconds = 10;
        public const int VictoryCelebrationMs = 3200;
        public static string ServerName = "Servidor Oficial Kaito Online";

        // ---- Ajustes de rendimiento / red ----
        // Umbral de micro-rafaga (14 ms): deja pasar el 100% de los paquetes de movimiento
        // normales (~33 ms) con 0 ms de espera incluso con jitter de red, y solo fusiona
        // rafagas duplicadas (< 14 ms) para no llenar el buffer de ssh.exe / cloudflared.exe.
        public const int MinStateIntervalMs = 14;
        public const int PingIntervalMs = 10000;
        public const int IdleTimeoutMs = 60000;
        public const int IdleTimeoutNoPongMs = 300000;
        public const int MaxQueuedBytesPerClient = 512 * 1024;
        public const int MaxPayloadBytes = 128 * 1024;
        public const int MaxMessagesPerSecond = 1200;

        // Canal de autodescubrimiento global (MQTT Retained sobre TCP/WSS, sin limites 429)
        public const string GlobalDiscoveryTopic = "kaito_adventure/janosos/online_srv_v2";
        public static readonly string[] GlobalMqttBrokers = new string[] {
            "broker.emqx.io",
            "broker.hivemq.com"
        };
        public const int GlobalMqttTcpPort = 1883;
        public static volatile string PublicTunnelWsUrl = "";

        private static readonly object ServerLock = new object();
        private static readonly Dictionary<string, OnlineRoom> Rooms = new Dictionary<string, OnlineRoom>();
        private static volatile OnlineRoom[] _roomsSnapshot = new OnlineRoom[0];
        private static readonly Dictionary<string, ClientConnection> Clients = new Dictionary<string, ClientConnection>();
        private static int _nextRoomCounter = 1;
        private static int _nextPlayerCounter = 1;
        private static int _nextConnCounter = 1;
        private static volatile bool _running = true;
        private static int _shutdownFlag = 0;
        private static TcpListener _tcpListener;
        private static UdpClient _udpListener;
        private static Process _tunnelProcess;
        private static Timer _globalBeaconTimer;

        private delegate bool ConsoleCtrlDelegate(int sig);
        [DllImport("Kernel32")]
        private static extern bool SetConsoleCtrlHandler(ConsoleCtrlDelegate handler, bool add);
        [DllImport("winmm.dll")]
        private static extern uint timeBeginPeriod(uint uPeriod);
        private static ConsoleCtrlDelegate _consoleHandler;

        [ThreadStatic]
        private static JavaScriptSerializer _tlsJson;
        private static JavaScriptSerializer Json
        {
            get
            {
                if (_tlsJson == null) _tlsJson = new JavaScriptSerializer();
                return _tlsJson;
            }
        }

        private static void RefreshRoomsSnapshotLocked()
        {
            OnlineRoom[] arr = new OnlineRoom[Rooms.Count];
            Rooms.Values.CopyTo(arr, 0);
            _roomsSnapshot = arr;
        }

        static void Main(string[] args)
        {
            try
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072 | SecurityProtocolType.Tls;
            }
            catch { }
            try { ServicePointManager.Expect100Continue = false; } catch { }

            try { Console.OutputEncoding = Encoding.UTF8; } catch { }
            try { Console.Title = "KAITO ADVENTURE: INK SHINOBI - SERVIDOR MULTIPLAYER ONLINE"; } catch { }

            if (args != null && args.Length > 0)
            {
                int parsedPort;
                if (int.TryParse(args[0], out parsedPort) && parsedPort > 1024 && parsedPort < 65535)
                {
                    TcpPort = parsedPort;
                }
            }

            TuneProcess();
            StartLogger();

            _consoleHandler = new ConsoleCtrlDelegate(OnConsoleClose);
            try { SetConsoleCtrlHandler(_consoleHandler, true); } catch { }
            AppDomain.CurrentDomain.ProcessExit += delegate(object s, EventArgs e) { ShutdownServer(); };

            PrintBanner();

            try
            {
                _tcpListener = new TcpListener(IPAddress.Any, TcpPort);
                _tcpListener.Start();
            }
            catch (Exception ex)
            {
                LogError("No se pudo iniciar el servidor en el puerto TCP " + TcpPort + ": " + ex.Message);
                LogInfo("Verifica que no haya otra ventana del servidor abierta.");
                FlushLogs(500);
                Console.WriteLine("\nPresiona cualquier tecla para salir...");
                try { Console.ReadKey(true); } catch { }
                return;
            }

            StartUdpDiscoveryService();

            Thread acceptThread = new Thread(AcceptClientsLoop);
            acceptThread.IsBackground = true;
            acceptThread.Start();

            // Hilo de precision (cada 10 ms) que entrega los "state" coalescidos puntualmente
            Thread stateFlushThread = new Thread(StateFlushLoop);
            stateFlushThread.IsBackground = true;
            stateFlushThread.Priority = ThreadPriority.AboveNormal;
            stateFlushThread.Name = "state-pacing-flush";
            stateFlushThread.Start();

            Thread watchdogThread = new Thread(WatchdogLoop);
            watchdogThread.IsBackground = true;
            watchdogThread.Start();

            LogSuccess("Motor del Servidor iniciado en esta PC (127.0.0.1:" + TcpPort + ").");

            Thread tunnelThread = new Thread(StartInternetTunnelLoop);
            tunnelThread.IsBackground = true;
            tunnelThread.Start();

            _globalBeaconTimer = new Timer(delegate(object state)
            {
                if (_running && !string.IsNullOrEmpty(PublicTunnelWsUrl))
                {
                    PublishOnlineBeacon(true);
                }
            }, null, 120000, 120000);

            lock (ConsoleLock)
            {
                Console.WriteLine("--------------------------------------------------------------------------------");
                Console.WriteLine("Comandos en consola: [S] Ver Salas, Jugadores y Ping | [C] Limpiar | [Q] Apagar");
                Console.WriteLine("--------------------------------------------------------------------------------\n");
            }

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
                            lock (ConsoleLock)
                            {
                                Console.Clear();
                            }
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

            ShutdownServer();
        }

        private static void TuneProcess()
        {
            try { timeBeginPeriod(1); } catch { }
            try { Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.AboveNormal; } catch { }
            try { System.Runtime.GCSettings.LatencyMode = System.Runtime.GCLatencyMode.SustainedLowLatency; } catch { }
            try { ThreadPool.SetMinThreads(24, 24); } catch { }
        }

        private static bool OnConsoleClose(int sig)
        {
            ShutdownServer();
            return false;
        }

        private static void ShutdownServer()
        {
            if (Interlocked.Exchange(ref _shutdownFlag, 1) == 1) return;
            _running = false;

            try { if (_globalBeaconTimer != null) _globalBeaconTimer.Dispose(); } catch { }
            StopTunnelProcess();
            PublishOnlineBeacon(false);
            try { if (_tcpListener != null) _tcpListener.Stop(); } catch { }
            try { if (_udpListener != null) _udpListener.Close(); } catch { }
            FlushLogs(300);
        }

        // ====================================================================
        //  PACING Y COALESCENCIA DE ESTADOS (evita bufferbloat en ssh.exe)
        // ====================================================================
        private static void HandlePlayerStatePaced(OnlineRoom room, OnlinePlayer sender, byte[] stateFrame)
        {
            bool sendNow = false;
            int now = Environment.TickCount;
            lock (sender.statePacingLock)
            {
                int elapsed = unchecked(now - sender.lastStateBroadcastTick);
                if (elapsed >= MinStateIntervalMs && sender.pendingStateFrame == null)
                {
                    sender.lastStateBroadcastTick = now;
                    sendNow = true;
                }
                else
                {
                    // Reemplaza en memoria el estado pendiente sin saturar el socket TCP de ssh.exe
                    sender.pendingStateFrame = stateFrame;
                }
            }
            if (sendNow)
            {
                BroadcastStateToRoom(room, stateFrame, sender.id, sender.slot);
            }
        }

        private static void StateFlushLoop()
        {
            while (_running)
            {
                Thread.Sleep(4);
                if (!_running) break;
                try
                {
                    int now = Environment.TickCount;
                    OnlineRoom[] rooms = _roomsSnapshot;
                    for (int r = 0; r < rooms.Length; r++)
                    {
                        OnlineRoom room = rooms[r];
                        if (room == null) continue;
                        OnlinePlayer[] players = room.snapshot;
                        for (int p = 0; p < players.Length; p++)
                        {
                            OnlinePlayer player = players[p];
                            if (player == null || player.pendingStateFrame == null) continue;

                            byte[] toSend = null;
                            lock (player.statePacingLock)
                            {
                                if (player.pendingStateFrame != null &&
                                    unchecked(now - player.lastStateBroadcastTick) >= MinStateIntervalMs)
                                {
                                    toSend = player.pendingStateFrame;
                                    player.pendingStateFrame = null;
                                    player.lastStateBroadcastTick = now;
                                }
                            }
                            if (toSend != null)
                            {
                                BroadcastStateToRoom(room, toSend, player.id, player.slot);
                            }
                        }
                    }
                }
                catch { }
            }
        }

        // ====================================================================
        //  LOG ASINCRONO
        // ====================================================================
        private sealed class LogLine
        {
            public DateTime time;
            public ConsoleColor color;
            public string tag;
            public string msg;
        }

        private static readonly Queue<LogLine> LogQueue = new Queue<LogLine>();
        private static readonly object LogLock = new object();
        private static readonly object ConsoleLock = new object();

        private static void StartLogger()
        {
            Thread t = new Thread(LogLoop);
            t.IsBackground = true;
            t.Priority = ThreadPriority.BelowNormal;
            t.Name = "log-writer";
            t.Start();
        }

        private static void EnqueueLog(ConsoleColor color, string tag, string msg)
        {
            LogLine line = new LogLine();
            line.time = DateTime.Now;
            line.color = color;
            line.tag = tag;
            line.msg = msg;
            lock (LogLock)
            {
                if (LogQueue.Count >= 2000) LogQueue.Dequeue();
                LogQueue.Enqueue(line);
                Monitor.Pulse(LogLock);
            }
        }

        private static void LogLoop()
        {
            while (true)
            {
                LogLine line;
                lock (LogLock)
                {
                    while (LogQueue.Count == 0)
                    {
                        Monitor.Wait(LogLock);
                    }
                    line = LogQueue.Dequeue();
                }
                try
                {
                    lock (ConsoleLock)
                    {
                        Console.ForegroundColor = line.color;
                        Console.Write("[" + line.time.ToString("HH:mm:ss") + "] " + line.tag);
                        Console.ResetColor();
                        Console.WriteLine(line.msg);
                    }
                }
                catch { }
            }
        }

        private static void FlushLogs(int maxWaitMs)
        {
            int waited = 0;
            while (waited < maxWaitMs)
            {
                lock (LogLock)
                {
                    if (LogQueue.Count == 0) break;
                }
                Thread.Sleep(20);
                waited += 20;
            }
            Thread.Sleep(30);
        }

        private static void LogInfo(string msg)
        {
            EnqueueLog(ConsoleColor.Cyan, "[INFO] ", msg);
        }

        private static void LogSuccess(string msg)
        {
            EnqueueLog(ConsoleColor.Green, "[OK]   ", msg);
        }

        private static void LogError(string msg)
        {
            EnqueueLog(ConsoleColor.Red, "[ERR]  ", msg);
        }

        // ====================================================================
        //  VIGILANTE: Ping WebSocket + limpieza de conexiones muertas
        // ====================================================================
        private static void WatchdogLoop()
        {
            while (_running)
            {
                Thread.Sleep(PingIntervalMs);
                if (!_running) break;
                try
                {
                    List<ClientConnection> snapshot;
                    lock (ServerLock)
                    {
                        snapshot = new List<ClientConnection>(Clients.Values);
                    }
                    int now = Environment.TickCount;
                    for (int i = 0; i < snapshot.Count; i++)
                    {
                        ClientConnection c = snapshot[i];
                        if (c.isClosed || !c.isWebSocket) continue;

                        int idle = unchecked(now - c.lastRecvTick);
                        int limit = c.rttMs > 0.0 ? IdleTimeoutMs : IdleTimeoutNoPongMs;
                        if (idle > limit)
                        {
                            LogInfo("Conexion " + c.connectionId + " sin respuesta por " + (idle / 1000) + " s: se cierra.");
                            c.Close();
                            continue;
                        }
                        c.SendPing();
                    }
                }
                catch { }
            }
        }

        // ====================================================================
        //  TUNEL DE INTERNET (optimizado con IPQoS=lowdelay y Compression=no)
        // ====================================================================
        private static void StopTunnelProcess()
        {
            try
            {
                if (_tunnelProcess != null && !_tunnelProcess.HasExited)
                {
                    _tunnelProcess.Kill();
                    _tunnelProcess.Dispose();
                }
            }
            catch { }
            _tunnelProcess = null;
        }

        private static string ResolveCloudflaredPath()
        {
            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string localCf = Path.Combine(baseDir, "cloudflared.exe");
                if (File.Exists(localCf)) return localCf;
                string localCf64 = Path.Combine(baseDir, "cloudflared-windows-amd64.exe");
                if (File.Exists(localCf64)) return localCf64;

                string pf = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                string pfCf = Path.Combine(pf, @"cloudflared\cloudflared.exe");
                if (File.Exists(pfCf)) return pfCf;

                string pf86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
                string pf86Cf = Path.Combine(pf86, @"cloudflared\cloudflared.exe");
                if (File.Exists(pf86Cf)) return pf86Cf;

                string pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
                string[] dirs = pathEnv.Split(Path.PathSeparator);
                for (int i = 0; i < dirs.Length; i++)
                {
                    string d = dirs[i].Trim();
                    if (d.Length == 0) continue;
                    string candidate = Path.Combine(d, "cloudflared.exe");
                    if (File.Exists(candidate)) return candidate;
                }
            }
            catch { }
            return null;
        }

        private static string EnsureCloudflaredInstalled()
        {
            string existing = ResolveCloudflaredPath();
            if (!string.IsNullOrEmpty(existing)) return existing;
            if (TcpPort != 7779) return null; // En pruebas automatizadas (otro puerto) usar ssh directo

            try
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string targetPath = Path.Combine(baseDir, "cloudflared.exe");
                string tmpPath = Path.Combine(baseDir, "cloudflared.exe.tmp");
                LogInfo("Descargando motor Cloudflare Edge (cloudflared.exe) por unica vez para reducir la latencia...");
                using (WebClient wc = new WebClient())
                {
                    wc.Headers.Add("User-Agent", "KaitoAdventureOnlineServer/2.0");
                    wc.DownloadFile("https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe", tmpPath);
                }
                if (File.Exists(tmpPath))
                {
                    FileInfo fi = new FileInfo(tmpPath);
                    if (fi.Length > 5 * 1024 * 1024)
                    {
                        if (File.Exists(targetPath)) File.Delete(targetPath);
                        File.Move(tmpPath, targetPath);
                        LogSuccess("Motor Cloudflare Edge instalado correctamente en servidor_online\\cloudflared.exe");
                        return targetPath;
                    }
                    try { File.Delete(tmpPath); } catch { }
                }
            }
            catch (Exception ex)
            {
                LogInfo("No se pudo descargar cloudflared automaticamente (" + ex.Message + "); se usara OpenSSH.");
            }
            return null;
        }

        private static string ResolveWindowsSshPath()
        {
            string sys32Ssh = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"OpenSSH\ssh.exe");
            if (File.Exists(sys32Ssh)) return sys32Ssh;

            string winDirSsh = Path.Combine(Environment.GetEnvironmentVariable("WINDIR") ?? @"C:\Windows", @"System32\OpenSSH\ssh.exe");
            if (File.Exists(winDirSsh)) return winDirSsh;

            string sysNativeSsh = Path.Combine(Environment.GetEnvironmentVariable("WINDIR") ?? @"C:\Windows", @"Sysnative\OpenSSH\ssh.exe");
            if (File.Exists(sysNativeSsh)) return sysNativeSsh;

            return "ssh.exe";
        }

        private static void StartInternetTunnelLoop()
        {
            Regex urlRegex = new Regex(@"https://([a-zA-Z0-9\.-]+\.(?:trycloudflare\.com|lhr\.life))", RegexOptions.IgnoreCase);
            int retryDelayMs = 3000;
            bool forceSshFallback = false;

            while (_running)
            {
                Stopwatch aliveTime = Stopwatch.StartNew();
                bool usedCloudflared = false;
                try
                {
                    string cfExe = forceSshFallback ? null : EnsureCloudflaredInstalled();
                    usedCloudflared = !string.IsNullOrEmpty(cfExe);
                    ProcessStartInfo psi = new ProcessStartInfo();
                    if (usedCloudflared)
                    {
                        LogInfo("Activando puente Cloudflare Edge de ultra-baja latencia (cloudflared)...");
                        psi.FileName = cfExe;
                        psi.Arguments = "tunnel --url http://127.0.0.1:" + TcpPort + " --no-autoupdate";
                    }
                    else
                    {
                        string sshExe = ResolveWindowsSshPath();
                        LogInfo("Activando puente de Internet OpenSSH de baja latencia...");
                        psi.FileName = sshExe;
                        psi.Arguments = "-T -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o IPQoS=lowdelay -o Compression=no -R 80:127.0.0.1:" + TcpPort + " nokey@localhost.run";
                    }
                    psi.UseShellExecute = false;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    psi.CreateNoWindow = true;

                    _tunnelProcess = Process.Start(psi);
                    if (_tunnelProcess == null)
                    {
                        LogError("No se pudo iniciar el puente OpenSSH integrado de Windows.");
                        return;
                    }
                    try { _tunnelProcess.PriorityClass = ProcessPriorityClass.AboveNormal; } catch { }

                    Process currentProc = _tunnelProcess;
                    Thread errThread = new Thread(delegate()
                    {
                        try
                        {
                            while (_running && currentProc != null && !currentProc.HasExited)
                            {
                                string errLine = currentProc.StandardError.ReadLine();
                                if (errLine == null) break;
                                Match m = urlRegex.Match(errLine);
                                if (m.Success)
                                {
                                    UpdatePublicTunnelHost(m.Groups[1].Value);
                                }
                            }
                        }
                        catch { }
                    });
                    errThread.IsBackground = true;
                    errThread.Start();

                    while (_running && currentProc != null && !currentProc.HasExited)
                    {
                        string line = currentProc.StandardOutput.ReadLine();
                        if (line == null) break;
                        Match m = urlRegex.Match(line);
                        if (m.Success)
                        {
                            UpdatePublicTunnelHost(m.Groups[1].Value);
                        }
                    }
                }
                catch (Exception ex)
                {
                    if (_running)
                    {
                        LogError("Aviso en puente de Internet: " + ex.Message);
                    }
                }
                finally
                {
                    if (usedCloudflared && aliveTime.ElapsedMilliseconds < 10000 && string.IsNullOrEmpty(PublicTunnelWsUrl))
                    {
                        forceSshFallback = true;
                    }
                    StopTunnelProcess();
                    if (_running) ClearPublicTunnelUrl();
                }

                if (_running)
                {
                    if (aliveTime.ElapsedMilliseconds > 60000) retryDelayMs = 3000;
                    LogInfo("Reconectando puente de Internet en " + (retryDelayMs / 1000) + " segundos...");
                    Thread.Sleep(retryDelayMs);
                    retryDelayMs = Math.Min(retryDelayMs * 2, 30000);
                }
            }
        }

        private static void UpdatePublicTunnelHost(string hostDomain)
        {
            if (string.IsNullOrEmpty(hostDomain)) return;
            string nextWsUrl = "wss://" + hostDomain.Trim();
            if (PublicTunnelWsUrl == nextWsUrl) return;

            PublicTunnelWsUrl = nextWsUrl;
            LogSuccess("\u00A1Servidor Online Global ACTIVO usando tu PC e Internet!");
            LogSuccess("Enlace directo (sin abrir puertos): " + PublicTunnelWsUrl);
            PublishOnlineBeacon(true);
        }

        private static void ClearPublicTunnelUrl()
        {
            if (string.IsNullOrEmpty(PublicTunnelWsUrl)) return;
            PublicTunnelWsUrl = "";
            LogInfo("Puente de Internet caido: se retira el enlace anterior.");
            ThreadPool.QueueUserWorkItem(delegate(object o) { PublishOnlineBeacon(false); });
        }

        private static void PublishOnlineBeacon(bool isActive)
        {
            try
            {
                string url = PublicTunnelWsUrl;
                Dictionary<string, object> payload = new Dictionary<string, object>();
                payload["type"] = "kaito_online_beacon";
                payload["active"] = isActive && !string.IsNullOrEmpty(url);
                payload["wsUrl"] = isActive ? url : "";
                payload["serverName"] = ServerName;
                payload["ts"] = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalSeconds;

                string jsonText = Json.Serialize(payload);
                for (int i = 0; i < GlobalMqttBrokers.Length; i++)
                {
                    try
                    {
                        PublishMqttRetained(GlobalMqttBrokers[i], GlobalMqttTcpPort, GlobalDiscoveryTopic, jsonText);
                    }
                    catch { }
                }
            }
            catch
            {
            }
        }

        private static void WriteMqttUtf8(MemoryStream ms, string s)
        {
            byte[] b = Encoding.UTF8.GetBytes(s);
            ms.WriteByte((byte)((b.Length >> 8) & 0xFF));
            ms.WriteByte((byte)(b.Length & 0xFF));
            ms.Write(b, 0, b.Length);
        }

        private static void WriteMqttPacket(Stream s, byte header, byte[] body)
        {
            s.WriteByte(header);
            int len = body.Length;
            do
            {
                byte d = (byte)(len % 128);
                len /= 128;
                if (len > 0) d |= 0x80;
                s.WriteByte(d);
            } while (len > 0);
            if (body.Length > 0)
            {
                s.Write(body, 0, body.Length);
            }
            s.Flush();
        }

        private static void PublishMqttRetained(string host, int port, string topic, string jsonPayload)
        {
            using (TcpClient client = new TcpClient())
            {
                client.SendTimeout = 3500;
                client.ReceiveTimeout = 3500;
                IAsyncResult ar = client.BeginConnect(host, port, null, null);
                if (!ar.AsyncWaitHandle.WaitOne(3000))
                {
                    client.Close();
                    return;
                }
                client.EndConnect(ar);

                using (NetworkStream ns = client.GetStream())
                {
                    MemoryStream connectBody = new MemoryStream();
                    WriteMqttUtf8(connectBody, "MQTT");
                    connectBody.WriteByte(4);
                    connectBody.WriteByte(0x02);
                    connectBody.WriteByte(0);
                    connectBody.WriteByte(30);
                    WriteMqttUtf8(connectBody, "kaito_srv_" + Guid.NewGuid().ToString("N").Substring(0, 10));
                    WriteMqttPacket(ns, 0x10, connectBody.ToArray());

                    byte[] ack = new byte[4];
                    int r = ns.Read(ack, 0, 4);
                    if (r < 4 || ack[0] != 0x20 || ack[3] != 0x00) return;

                    MemoryStream pubBody = new MemoryStream();
                    WriteMqttUtf8(pubBody, topic);
                    pubBody.WriteByte(0x00);
                    pubBody.WriteByte(0x01);
                    byte[] payloadBytes = Encoding.UTF8.GetBytes(jsonPayload);
                    pubBody.Write(payloadBytes, 0, payloadBytes.Length);
                    WriteMqttPacket(ns, 0x33, pubBody.ToArray());

                    byte[] pubAck = new byte[4];
                    ns.Read(pubAck, 0, 4);

                    WriteMqttPacket(ns, 0xE0, new byte[0]);
                }
            }
        }

        // ====================================================================
        //  CONSOLA
        // ====================================================================
        private static void PrintBanner()
        {
            lock (ConsoleLock)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("================================================================================");
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("      KAITO ADVENTURE: INK SHINOBI - SERVIDOR DEDICADO MULTIPLAYER ONLINE");
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("================================================================================");
                Console.ResetColor();

                Console.WriteLine("  Modo de Operacion   : Usa tu PC, tu Internet y tus recursos como Servidor");
                Console.WriteLine("  Motor de Red        : Baja Latencia (Prioridad Ataques + Anti-Bufferbloat)");
                Console.WriteLine("  Puerto Local Motor  : " + TcpPort);
                Console.WriteLine("  Capacidad por Sala  : 2 a 5 Jugadores (Multiples Salas Online Simultaneas)");
                Console.WriteLine("================================================================================\n");
            }
        }

        private static void PrintServerStatus()
        {
            List<string> lines = new List<string>();
            lock (ServerLock)
            {
                lines.Add("  Enlace Global      : " + (string.IsNullOrEmpty(PublicTunnelWsUrl) ? "Conectando..." : PublicTunnelWsUrl));
                lines.Add("  Conexiones activas : " + Clients.Count);
                lines.Add("  Salas Online       : " + Rooms.Count);
                foreach (OnlineRoom r in Rooms.Values)
                {
                    lines.Add("  * [" + r.roomId + "] \"" + r.roomName + "\" (" + r.players.Count + "/5) - " + (r.inMatch ? "EN COMBATE" : "EN SALA DE ESPERA"));
                    foreach (OnlinePlayer p in r.players.Values)
                    {
                        string ping = "";
                        if (p.connection != null && p.connection.rttMs > 0.0)
                        {
                            ping = " | Ping al servidor: " + ((int)p.connection.rttMs) + " ms";
                        }
                        lines.Add("      - Slot " + (p.slot + 1) + ": " + p.nickname + (p.isHost ? " [ANFITRION]" : "") + " (HP: " + p.hp + "/" + p.maxHp + ", Vidas: " + p.lives + ")" + ping);
                    }
                }
            }

            lock (ConsoleLock)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("\n--- ESTADO ACTUAL DEL SERVIDOR ONLINE ---");
                Console.ResetColor();
                foreach (string l in lines)
                {
                    Console.WriteLine(l);
                }
                Console.WriteLine("-----------------------------------------\n");
            }
        }

        // ====================================================================
        //  RED LOCAL / DESCUBRIMIENTO UDP
        // ====================================================================
        private static readonly object IpCacheLock = new object();
        private static List<string> _cachedIps;
        private static int _cachedIpsTick;

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

        private static List<string> GetLocalIPv4AddressesCached()
        {
            lock (IpCacheLock)
            {
                int now = Environment.TickCount;
                if (_cachedIps == null || unchecked(now - _cachedIpsTick) > 15000)
                {
                    _cachedIps = GetLocalIPv4Addresses();
                    _cachedIpsTick = now;
                }
                return _cachedIps;
            }
        }

        private static void StartUdpDiscoveryService()
        {
            try
            {
                _udpListener = new UdpClient(UdpDiscoveryPort);
                _udpListener.EnableBroadcast = true;

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
            catch { }
        }

        private static byte[] BuildUdpBeaconBytes()
        {
            List<string> ips = GetLocalIPv4AddressesCached();
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
            payload["wsUrl"] = PublicTunnelWsUrl;
            payload["roomCount"] = roomCount;
            payload["playerCount"] = clientCount;
            return Encoding.UTF8.GetBytes(Json.Serialize(payload));
        }

        // ====================================================================
        //  ACEPTAR CLIENTES / HANDSHAKE HTTP + WEBSOCKET
        // ====================================================================
        private static void AcceptClientsLoop()
        {
            while (_running)
            {
                TcpClient tcpClient = null;
                try
                {
                    tcpClient = _tcpListener.AcceptTcpClient();
                    string connId = "c_" + (_nextConnCounter++);
                    ClientConnection conn = new ClientConnection(connId, tcpClient);
                    Thread clientThread = new Thread(delegate() { HandleClientConnection(conn); });
                    clientThread.IsBackground = true;
                    clientThread.Priority = ThreadPriority.AboveNormal;
                    clientThread.Start();
                }
                catch
                {
                    if (tcpClient != null)
                    {
                        try { tcpClient.Close(); } catch { }
                    }
                    if (!_running) break;
                    Thread.Sleep(20);
                }
            }
        }

        private static void HandleClientConnection(ClientConnection conn)
        {
            try
            {
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

                if (method == "OPTIONS")
                {
                    WriteHttpResponse(conn.stream, "200 OK", "text/plain", "");
                    conn.Close();
                    return;
                }

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
                    conn.lastRecvTick = Environment.TickCount;
                    conn.StartWriter();

                    lock (ServerLock)
                    {
                        Clients[conn.connectionId] = conn;
                    }

                    conn.SendPing();
                    SendRoomsListToClient(conn);
                    WebSocketReceiveLoop(conn);
                }
                else
                {
                    string statusJson = BuildStatusJson();
                    WriteHttpResponse(conn.stream, "200 OK", "application/json; charset=utf-8", statusJson);
                    conn.Close();
                }
            }
            catch
            {
            }
            finally
            {
                HandleClientDisconnect(conn);
            }
        }

        private static string ReadHttpHeaders(NetworkStream stream)
        {
            List<byte> buffer = new List<byte>(512);
            byte[] single = new byte[1];
            bool complete = false;
            stream.ReadTimeout = 5000;
            Stopwatch sw = Stopwatch.StartNew();
            while (buffer.Count < 16384 && sw.ElapsedMilliseconds < 8000)
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
                    complete = true;
                    break;
                }
            }
            stream.ReadTimeout = Timeout.Infinite;
            if (!complete) return null;
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
            using (SHA1 sha = SHA1.Create())
            {
                byte[] hash = sha.ComputeHash(Encoding.ASCII.GetBytes(combined));
                return Convert.ToBase64String(hash);
            }
        }

        // ====================================================================
        //  BUCLE DE RECEPCION WEBSOCKET
        // ====================================================================
        private static void WebSocketReceiveLoop(ClientConnection conn)
        {
            while (_running && !conn.isClosed)
            {
                int b0 = conn.ReadByteBuffered();
                if (b0 < 0) break;
                int b1 = conn.ReadByteBuffered();
                if (b1 < 0) break;

                int opcode = b0 & 0x0F;
                bool masked = (b1 & 0x80) != 0;
                long payloadLen = b1 & 0x7F;

                if (payloadLen == 126)
                {
                    if (!conn.ReadExactBuffered(conn.extBuf, 2)) break;
                    payloadLen = (conn.extBuf[0] << 8) | conn.extBuf[1];
                }
                else if (payloadLen == 127)
                {
                    if (!conn.ReadExactBuffered(conn.extBuf, 8)) break;
                    payloadLen = 0;
                    for (int i = 0; i < 8; i++)
                    {
                        payloadLen = (payloadLen << 8) | conn.extBuf[i];
                    }
                }

                if (payloadLen < 0 || payloadLen > MaxPayloadBytes)
                {
                    break;
                }

                if (masked)
                {
                    if (!conn.ReadExactBuffered(conn.maskKey, 4)) break;
                }

                int len = (int)payloadLen;
                byte[] buf = conn.EnsurePayloadCapacity(len);
                if (len > 0 && !conn.ReadExactBuffered(buf, len)) break;

                if (masked)
                {
                    byte[] mk = conn.maskKey;
                    for (int j = 0; j < len; j++)
                    {
                        buf[j] = (byte)(buf[j] ^ mk[j & 3]);
                    }
                }

                int nowTick = Environment.TickCount;
                conn.lastRecvTick = nowTick;

                if (unchecked(nowTick - conn.rateWindowStart) >= 1000)
                {
                    conn.rateWindowStart = nowTick;
                    conn.rateCount = 0;
                }
                conn.rateCount++;
                if (conn.rateCount > MaxMessagesPerSecond)
                {
                    LogError("Conexion " + conn.connectionId + " supero " + MaxMessagesPerSecond + " mensajes/s: se desconecta.");
                    break;
                }

                if (opcode == 0x08)
                {
                    break;
                }
                else if (opcode == 0x09)
                {
                    conn.SendPong(buf, len);
                }
                else if (opcode == 0x0A)
                {
                    conn.OnPong(buf, len);
                }
                else if (opcode == 0x01 || opcode == 0x02)
                {
                    try
                    {
                        HandleFrameMessage(conn, buf, len);
                    }
                    catch
                    {
                    }
                }
            }
        }

        // ====================================================================
        //  PROCESAMIENTO DE PAQUETES (RUTA RAPIDA 100% SIN SERVERLOCK)
        // ====================================================================
        private static void HandleFrameMessage(ClientConnection conn, byte[] buf, int len)
        {
            FastInfo info = new FastInfo();
            bool scanned = false;
            try { scanned = FastJson.Scan(buf, len, ref info); } catch { scanned = false; }

            if (scanned && info.typeCode != FastJson.T_UNKNOWN)
            {
                OnlineRoom room = conn.currentRoom;
                OnlinePlayer sender = conn.currentPlayer;
                if (room == null || sender == null) return;
                if (info.hasSession && info.session != room.sessionId) return;

                if (info.typeCode == FastJson.T_STATE)
                {
                    // Actualizacion local sin bloquear ServerLock
                    if (!sender.isAlive)
                    {
                        sender.hp = 0.0;
                    }
                    else if (info.hasHp && info.hp < sender.hp)
                    {
                        sender.hp = Math.Max(0.0, Math.Min(sender.maxHp, info.hp));
                    }
                    if (info.hasOugi)
                    {
                        sender.ougi = info.ougi;
                    }

                    byte[] stateFrame = WsFrame.BuildText(buf, 0, len);
                    HandlePlayerStatePaced(room, sender, stateFrame);
                    return;
                }

                // Eventos prioritarios (player_action, spawn_kunai, hit, ring_out_blast):
                // Salen inmediatamente por la cola de prioridad 1 (_eventQueue), adelantando a "state".
                BroadcastEventFrame(room, WsFrame.BuildText(buf, 0, len), sender.id);
                return;
            }

            ProcessIncomingPacket(conn, Encoding.UTF8.GetString(buf, 0, len));
        }

        private static void ProcessIncomingPacket(ClientConnection conn, string jsonText)
        {
            JavaScriptSerializer serializer = Json;
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
                HandlePlayerStatePaced(room, sender, WsFrame.BuildText(jsonText));
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

                        LogInfo("[" + room.roomName + "] " + sender.nickname + " fue eliminado (" + sender.placement + "\u00B0 lugar).");

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

        // ====================================================================
        //  SALAS
        // ====================================================================
        private static void HandleCreateOnlineRoom(ClientConnection conn, Dictionary<string, object> map)
        {
            RemovePlayerFromCurrentRoom(conn);
            JavaScriptSerializer serializer = Json;

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
                room.RefreshSnapshot();
                Rooms[roomId] = room;
                RefreshRoomsSnapshotLocked();
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
            JavaScriptSerializer serializer = Json;

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
                    err["msg"] = "La sala est\u00E1 llena (M\u00E1ximo 5 jugadores).";
                    conn.SendWebSocketText(serializer.Serialize(err));
                    return;
                }

                if (targetRoom.inMatch)
                {
                    Dictionary<string, object> err = new Dictionary<string, object>();
                    err["type"] = "error";
                    err["msg"] = "La partida en esta sala ya est\u00E1 en curso.";
                    conn.SendWebSocketText(serializer.Serialize(err));
                    return;
                }

                string playerName = map.ContainsKey("name") ? Convert.ToString(map["name"]).Trim() : "Shinobi";
                if (string.IsNullOrEmpty(playerName)) playerName = "Shinobi";
                int colorIdx = map.ContainsKey("color") ? ToInt(map["color"], 1) : 1;

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
                targetRoom.RefreshSnapshot();
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
                lock (p.statePacingLock)
                {
                    p.pendingStateFrame = null;
                }
            }

            LogSuccess("\u00A1Combate iniciado en la sala \"" + room.roomName + "\"! (" + room.players.Count + " Shinobis, Sesion #" + room.sessionId + ")");

            Dictionary<string, object> startPacket = new Dictionary<string, object>();
            startPacket["type"] = "match_start";
            startPacket["sessionId"] = room.sessionId;
            startPacket["config"] = room.config.ToDict();
            startPacket["players"] = room.GetPlayersDictList();

            BroadcastToRoom(room, Json.Serialize(startPacket), null);
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
                LogSuccess("[" + room.roomName + "] \u00A1CAMPE\u00D3N DE LA PARTIDA: " + winner.nickname + "!");
            }

            JavaScriptSerializer serializer = Json;

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
                    BroadcastToRoom(room, Json.Serialize(cancelPkt), null);
                }
                return;
            }

            if (room.rematchTimer == null)
            {
                room.rematchSeconds = RematchCountdownSeconds;
                Dictionary<string, object> startCountdown = new Dictionary<string, object>();
                startCountdown["type"] = "rematch_countdown";
                startCountdown["seconds"] = room.rematchSeconds;
                BroadcastToRoom(room, Json.Serialize(startCountdown), null);

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
                            BroadcastToRoom(room, Json.Serialize(cancelPkt), null);
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
                            BroadcastToRoom(room, Json.Serialize(tickPkt), null);
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
            JavaScriptSerializer serializer = Json;
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
                    room.RefreshSnapshot();
                    LogInfo("Jugador \"" + player.nickname + "\" salio de la sala \"" + room.roomName + "\".");
                }

                if (room.players.Count == 0)
                {
                    room.StopTimers();
                    Rooms.Remove(room.roomId);
                    RefreshRoomsSnapshotLocked();
                    LogInfo("Sala \"" + room.roomName + "\" cerrada (0 jugadores).");
                    BroadcastRoomsListToLobby();
                    return;
                }

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

        // ====================================================================
        //  DIFUSION CON PRIORIDAD SEPARADA (EVENTOS vs ESTADOS O(1))
        // ====================================================================
        private static void BroadcastEventFrame(OnlineRoom room, byte[] frame, string excludePlayerId)
        {
            OnlinePlayer[] targets = room.snapshot;
            for (int i = 0; i < targets.Length; i++)
            {
                OnlinePlayer p = targets[i];
                if (excludePlayerId != null && p.id == excludePlayerId) continue;
                ClientConnection c = p.connection;
                if (c != null && !c.isClosed)
                {
                    c.EnqueueEvent(frame);
                }
            }
        }

        private static void BroadcastStateToRoom(OnlineRoom room, byte[] frame, string excludePlayerId, int senderSlot)
        {
            OnlinePlayer[] targets = room.snapshot;
            int slotIdx = (senderSlot >= 0 && senderSlot < 5) ? senderSlot : 0;
            for (int i = 0; i < targets.Length; i++)
            {
                OnlinePlayer p = targets[i];
                if (excludePlayerId != null && p.id == excludePlayerId) continue;
                ClientConnection c = p.connection;
                if (c != null && !c.isClosed)
                {
                    c.EnqueueSlotState(slotIdx, frame);
                }
            }
        }

        private static void BroadcastToRoom(OnlineRoom room, string jsonText, string excludePlayerId)
        {
            BroadcastEventFrame(room, WsFrame.BuildText(jsonText), excludePlayerId);
        }

        private static string BuildStatusJson()
        {
            JavaScriptSerializer serializer = Json;
            List<string> ips = GetLocalIPv4AddressesCached();
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
                status["wsUrl"] = PublicTunnelWsUrl;
                status["connectedClients"] = Clients.Count;
                status["roomCount"] = Rooms.Count;
                status["rooms"] = roomSummaries;
                return serializer.Serialize(status);
            }
        }

        private static string BuildRoomsListPacketJson()
        {
            JavaScriptSerializer serializer = Json;
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
                pkt["wsUrl"] = PublicTunnelWsUrl;
                pkt["connectedClients"] = Clients.Count;
                pkt["roomCount"] = Rooms.Count;
                pkt["rooms"] = roomSummaries;
                return serializer.Serialize(pkt);
            }
        }

        private static void SendRoomsListToClient(ClientConnection conn)
        {
            conn.EnqueueSlotState(6, WsFrame.BuildText(BuildRoomsListPacketJson()));
        }

        private static void BroadcastRoomsListToLobby()
        {
            byte[] frame = WsFrame.BuildText(BuildRoomsListPacketJson());
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
            for (int i = 0; i < lobbyClients.Count; i++)
            {
                lobbyClients[i].EnqueueSlotState(6, frame);
            }
        }

        // ====================================================================
        //  UTILIDADES
        // ====================================================================
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
    }
}
