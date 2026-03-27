#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 RPA4All contributors
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Compila o cliente Nextcloud Desktop RPA4All em um container Debian Trixie
# e empacota como .deb para instalação em LMDE 7 / Debian 13.
#
# Uso: ./scripts/docker-build-deb.sh [--jobs N]
# Saída: build/rpa4all-nextcloud-desktop_*.deb
set -euo pipefail

JOBS="${1:-$(nproc)}"
IMAGE="rpa4all-nextcloud-builder:trixie"
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${SOURCE_DIR}/build"

mkdir -p "${BUILD_DIR}"

echo "==> Construindo imagem Docker de build: ${IMAGE}"
docker build --pull -t "${IMAGE}" -f "${SOURCE_DIR}/scripts/Dockerfile.build" "${SOURCE_DIR}/scripts/"

echo "==> Compilando com ${JOBS} jobs no container Debian Trixie..."
docker run --rm \
  -v "${SOURCE_DIR}:/src:ro" \
  -v "${BUILD_DIR}:/build" \
  "${IMAGE}" \
  bash /scripts/compile.sh "${JOBS}"

echo "==> Build concluído. Pacotes .deb disponíveis em: ${BUILD_DIR}"
ls -lh "${BUILD_DIR}"/*.deb 2>/dev/null || echo "(nenhum .deb encontrado — verifique erros acima)"
