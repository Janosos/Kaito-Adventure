#!/bin/bash
set -e

echo "=== Configurando entorno Flutter para Vercel ==="

# Agregar Flutter al PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Verificar instalación de Flutter
echo "Versión de Flutter:"
flutter --version

# Habilitar web explícitamente
echo "Habilitando soporte Web..."
flutter config --enable-web

# Obtener dependencias
echo "Instalando paquetes de Flutter/Dart..."
flutter pub get

# Compilar para Web en modo release sin tree-shake de iconos para máxima compatibilidad CI
echo "Compilando Flutter Web en modo Release..."
flutter build web --release --no-tree-shake-icons

echo "=== Compilación completada con éxito. Archivos listos en build/web ==="

