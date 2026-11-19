# 🌐 Kaito Adventure: Ink Shinobi — Servidor Dedicado Multiplayer Online

Esta carpeta (`servidor_online`) contiene el **Servidor Dedicado Portable** para habilitar el modo **Multijugador Online** en **Kaito Adventure: Ink Shinobi**.

Puedes copiar esta carpeta completa a **cualquier PC con Windows** y ejecutarla directamente mediante **`INICIAR_SERVIDOR_ONLINE.bat`** sin necesidad de instalar motores ni programas adicionales.

---

## 📋 Requisitos Necesarios para Ejecutar el Servidor

| Componente | Requisito Mínimo | Notas |
| :--- | :--- | :--- |
| **Sistema Operativo** | Windows 10 o Windows 11 (64-bit / 32-bit) | También compatible con Windows Server |
| **Dependencias / Runtime** | **Ninguna instalación externa** | Utiliza `.NET Framework 4.x`, preinstalado de fábrica en Windows 10/11 |
| **Memoria RAM** | 50 MB libres | Consume ~15–25 MB durante las partidas |
| **Procesador (CPU)** | Dual-Core 1.5 GHz o superior | Muy ligero, soporta múltiples salas a 60 Hz |
| **Puertos de Red** | **TCP `7779`** y **UDP `7780`** | TCP `7779` para salas/combate WebSocket; UDP `7780` para autodescubrimiento |

---

## 🚀 Cómo Ejecutar el Servidor (Portable)

1. Copia la carpeta `servidor_online` en cualquier ubicación de tu PC.
2. *(Opcional, recomendado la primera vez en una PC nueva)* Ejecuta **`ABRIR_PUERTOS_FIREWALL_ADMIN.bat`** para autorizar los puertos `7779` (TCP) y `7780` (UDP) en el Firewall de Windows.
3. Haz doble clic en **`INICIAR_SERVIDOR_ONLINE.bat`**.
4. La consola mostrará:
   - `Estado del Servidor : ACTIVO (ONLINE)`
   - Todas las direcciones IP detectadas en la PC (`127.0.0.1:7779`, IP de red local `192.168.x.x:7779`, e IPs de VPN como Radmin/Tailscale/ZeroTier/Hamachi).
5. Abre **Kaito Adventure**, entra en **Multijugador Online** y pulsa **`REFRESCAR`**.
   - Si el servidor está encendido, el juego se conectará y permitirá **Crear Salas Online**, **Unirse a Salas Activas** o jugar en **Partida Rápida Online** (de 2 a 5 jugadores por sala).
   - Si el servidor está apagado, el juego indicará **"NO HAY SERVIDOR ONLINE ACTIVADO"** con la opción de **`REFRESCAR`**.

---

## 🌍 Cómo Conectar Jugadores Remotos por Internet

1. **Con VPN Virtual (Radmin VPN / Tailscale / ZeroTier / Hamachi)** *(Sin abrir puertos en el router)*:
   - Conecta las PCs o móviles a la misma red virtual.
   - Ejecuta `INICIAR_SERVIDOR_ONLINE.bat` en la PC que hará de servidor.
   - Copia la IP virtual que aparece en la consola del servidor (ej. `26.x.x.x:7779`), pégala en el campo **Servidor Online** dentro del juego y pulsa **`REFRESCAR`**.
2. **Con Apertura de Puertos (Port Forwarding)**:
   - Redirige el puerto **TCP `7779`** en tu router hacia la IP local de la PC donde corre `INICIAR_SERVIDOR_ONLINE.bat`.
   - Los jugadores ingresan `TuIpPublica:7779` en el juego y pulsan **`REFRESCAR`**.
3. **En la Misma PC o Red Local**:
   - El juego detecta automáticamente el servidor en `127.0.0.1:7779` o por radar UDP (`7780`) sin necesidad de escribir ninguna IP.

---

## ⌨️ Comandos de la Consola del Servidor

- **`[S]`**: Mostrar resumen en vivo de salas online creadas y jugadores conectados.
- **`[C]`**: Limpiar la pantalla de la consola.
- **`[Q]`**: Apagar el servidor de forma segura.
