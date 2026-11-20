# 🌐 Kaito Adventure: Ink Shinobi — Servidor Dedicado Multiplayer Online (Portable)

Esta carpeta (`servidor_online`) convierte tu PC en el **Servidor Dedicado del Multijugador Online** de **Kaito Adventure: Ink Shinobi**, utilizando los recursos de tu PC y tu conexión a Internet.

- **Sin abrir puertos en el router ni configurar firewall.**
- **Sin instalar programas externos ni VPNs** (usa únicamente componentes nativos incluidos de fábrica en Windows 10 y Windows 11).
- **Conexión 100% automática con el juego**: Al encender `INICIAR_SERVIDOR_ONLINE.bat`, el servidor establece un puente saliente seguro (`WSS`) y vincula automáticamente tu PC con la app. Cuando está apagado, el juego muestra **"NO HAY SERVIDOR ONLINE ACTIVADO"** y el botón **`REFRESCAR`**.

---

## 📋 Requisitos Necesarios para Ejecutarlo

| Componente | Requisito | Notas |
| :--- | :--- | :--- |
| **Sistema Operativo** | Windows 10 o Windows 11 (64-bit / 32-bit) | 100% portable en cualquier PC |
| **Internet** | Conexión a Internet activa | Necesaria para enlazar automáticamente a los jugadores con tu PC |
| **Componentes Nativos** | `.NET Framework 4.x` y `Windows OpenSSH` | **Preinstalados de fábrica en Windows 10/11** (`C:\Windows\System32\OpenSSH\ssh.exe`) |
| **Memoria RAM** | 50 MB libres | Consume ~20 MB durante las partidas |
| **Procesador (CPU)** | Dual-Core 1.5 GHz o superior | Soporta múltiples salas simultáneas de 2 a 5 jugadores a 60 Hz |

---

## 🚀 Cómo Ejecutar el Servidor

1. Copia la carpeta `servidor_online` en cualquier PC con Windows.
2. Haz doble clic en **`INICIAR_SERVIDOR_ONLINE.bat`**.
3. En 3–5 segundos la consola mostrará:
   - `[OK] Motor del Servidor iniciado en esta PC (127.0.0.1:7779).`
   - `[OK] ¡Servidor Online Global ACTIVO usando tu PC e Internet!`
4. Abre **Kaito Adventure** (en Windows, Android o Web), entra a **Multijugador Online** y pulsa **`REFRESCAR`**.
   - El juego se conectará automáticamente a tu PC sin pedir direcciones IP ni puertos.
   - Para apagar el servidor, presiona **`[Q]`** en la consola o cierra la ventana.
