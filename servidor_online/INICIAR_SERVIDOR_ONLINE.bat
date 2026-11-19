@echo off
chcp 65001 >nul
title KAITO ADVENTURE: INK SHINOBI - SERVIDOR MULTIPLAYER ONLINE
cd /d "%~dp0"
cls

echo ================================================================================
echo   INICIANDO SERVIDOR DEDICADO MULTIPLAYER ONLINE - KAITO ADVENTURE
echo ================================================================================
echo.

REM 1. Si el ejecutable portable ya existe, lo iniciamos directamente
if exist "%~dp0KaitoOnlineServer.exe" (
    goto :RUN_SERVER
)

REM 2. Si no existe el .exe, lo compilamos automaticamente usando el compilador nativo de Windows (.NET Framework 4.x)
echo [INFO] Compilando KaitoOnlineServer.exe con Microsoft .NET Framework...
set "CSC64=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
set "CSC32=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if exist "%CSC64%" (
    "%CSC64%" /nologo /optimize+ /r:System.Web.Extensions.dll /out:"%~dp0KaitoOnlineServer.exe" "%~dp0KaitoOnlineServer.cs"
    if exist "%~dp0KaitoOnlineServer.exe" goto :RUN_SERVER
)

if exist "%CSC32%" (
    "%CSC32%" /nologo /optimize+ /r:System.Web.Extensions.dll /out:"%~dp0KaitoOnlineServer.exe" "%~dp0KaitoOnlineServer.cs"
    if exist "%~dp0KaitoOnlineServer.exe" goto :RUN_SERVER
)

echo [ERROR] No se pudo encontrar o compilar KaitoOnlineServer.exe.
echo Revisa el archivo LEEME_REQUISITOS.txt para mas informacion.
pause
exit /b 1

:RUN_SERVER
"%~dp0KaitoOnlineServer.exe" %*
echo.
echo [INFO] El Servidor Online se ha detenido.
pause
