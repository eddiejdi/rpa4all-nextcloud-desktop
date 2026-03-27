#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 RPA4All contributors
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Executado dentro do container Docker para compilar e empacotar o cliente.
# Monta: /src (source read-only), /build (output de build)
set -euo pipefail

JOBS="${1:-$(nproc)}"
SOURCE="/src"
BUILD="/build/cmake-build"

mkdir -p "${BUILD}"
cd "${BUILD}"

echo "==> cmake configure (Release, DEB)..."
cmake "${SOURCE}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DQT_MAJOR_VERSION=6 \
    -DBUILD_TESTING=OFF \
    -DBUILD_UPDATER=OFF \
    -DNO_SHIBBOLETH=1 \
    -DCMAKE_SKIP_RPATH=ON \
    -DAPPLICATION_UPDATE_URL=https://updates.rpa4all.com/ \
    -DCPACK_GENERATOR=DEB \
    -DCPACK_DEBIAN_PACKAGE_MAINTAINER="RPA4All <it@rpa4all.com>" \
    -DCPACK_PACKAGE_VENDOR="RPA4All" \
    -DCPACK_PACKAGE_DESCRIPTION_SUMMARY="RPA4All Nextcloud Desktop Sync Client"

echo "==> ninja build com ${JOBS} jobs..."
ninja -j"${JOBS}"

echo "==> cpack -G DEB..."
cpack -G DEB --config CPackConfig.cmake 2>/dev/null || \
    cpack -G DEB 2>/dev/null || \
    echo "AVISO: cpack não gerou .deb — empacotando via make install + dpkg-deb"

# Fallback: instalar em DESTDIR e criar .deb manualmente
if ! ls *.deb 2>/dev/null; then
    echo "==> Fallback: empacotamento manual via DESTDIR..."
    DESTDIR="/build/destdir"
    mkdir -p "${DESTDIR}"
    DESTDIR="${DESTDIR}" ninja install

    VERSION=$(cmake -N -L "${SOURCE}" 2>/dev/null | grep "^MIRALL_VERSION=" | cut -d= -f2 | tr -d ' ' || echo "3.16")
    PKG_DIR="/build/pkg/rpa4all-nextcloud-desktop_${VERSION}_amd64"
    mkdir -p "${PKG_DIR}/DEBIAN"

    rsync -a "${DESTDIR}/" "${PKG_DIR}/"

    cat > "${PKG_DIR}/DEBIAN/control" << EOF
Package: rpa4all-nextcloud-desktop
Version: ${VERSION}
Architecture: amd64
Maintainer: RPA4All <it@rpa4all.com>
Installed-Size: $(du -sk "${PKG_DIR}" | cut -f1)
Description: RPA4All Nextcloud Desktop Sync Client
 Fork do cliente oficial do Nextcloud com configuracoes
 pre-definidas para o servidor nextcloud.rpa4all.com.
Depends: libqt6core6, libqt6gui6, libqt6network6, libqt6widgets6, libssl3, libkdsingleapplication-qt6-1.0
EOF

    fakeroot dpkg-deb --build "${PKG_DIR}" "/build/rpa4all-nextcloud-desktop_${VERSION}_amd64.deb"
fi

cp "${BUILD}"/*.deb /build/ 2>/dev/null || true
ls -lh /build/*.deb 2>/dev/null
echo "==> Concluído."
