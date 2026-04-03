#!/usr/bin/env bash
# install.sh — Dependências do projeto Infinite Canvas Sketch App
# Ubuntu 22.04 / 24.04 (Noble)
#
# Execute: sudo bash install.sh

set -e

echo "=== Infinite Canvas — Instalação de Dependências ==="
echo ""

echo "[1/3] Atualizando lista de pacotes..."
apt-get update -q

echo "[2/3] Instalando dependências de desenvolvimento..."
apt-get install -y \
    libinput-dev \
    libudev-dev \
    libevdev-dev \
    pkg-config

echo ""
echo "[3/3] Verificando instalação..."
pkg-config --modversion libinput && echo "  ✓ libinput OK"
pkg-config --modversion libudev && echo "  ✓ libudev OK"

echo ""
echo "=== Instalação concluída ==="
echo ""
echo "Para rodar a POC de input:"
echo "  cd pocs/libinput_tablet_input/"
echo "  zig build run"
echo ""
echo "Nota: pode ser necessário adicionar seu usuário ao grupo 'input'"
echo "para acessar /dev/input sem sudo:"
echo "  sudo usermod -aG input \$USER"
echo "  (requer logout/login para ter efeito)"
