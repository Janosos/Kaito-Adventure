@echo off
chcp 65001 >nul
title KAITO ADVENTURE - CONFIGURAR PUERTOS EN FIREWALL DE WINDOWS
cd /d "%~dp0"
cls

echo ================================================================================
echo   CONFIGURACION DE PUERTOS DEL SERVIDOR ONLINE EN FIREWALL DE WINDOWS
echo   Puertos: TCP 7779 (Combate y Salas WebSocket) / UDP 7780 (Autodescubrimiento)
echo ================================================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [AVISO] Solicitando permisos de Administrador para abrir los puertos 7779 y 7780...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [1/2] Habilitando Puerto TCP 7779 (Kaito Online Server TCP)...
netsh advfirewall firewall delete rule name="Kaito Adventure Online Server TCP" >nul 2>&1
netsh advfirewall firewall add rule name="Kaito Adventure Online Server TCP" dir=in action=allow protocol=TCP localport=7779

echo [2/2] Habilitando Puerto UDP 7780 (Kaito Online Server UDP Radar)...
netsh advfirewall firewall delete rule name="Kaito Adventure Online Server UDP" >nul 2>&1
netsh advfirewall firewall add rule name="Kaito Adventure Online Server UDP" dir=in action=allow protocol=UDP localport=7780

echo.
echo ================================================================================
echo   [OK] PUERTOS TCP 7779 Y UDP 7780 HABILITADOS CORRECTAMENTE EN EL FIREWALL.
echo   Ahora puedes ejecutar INICIAR_SERVIDOR_ONLINE.bat en esta PC.
echo ================================================================================
echo.
pause
