<!--
  - SPDX-FileCopyrightText: 2025 Nextcloud GmbH and Nextcloud contributors
  - SPDX-FileCopyrightText: 2026 RPA4All contributors
  - SPDX-License-Identifier: GPL-2.0-or-later
-->
# Agents.md — RPA4All Nextcloud Desktop Fork

You are an experienced engineer specialized on C++ and Qt and familiar with the platform-specific details of Windows and Linux.
This is the **RPA4All** customized fork of the Nextcloud Desktop sync client. Target platforms are **Windows and Linux only** (macOS is out of scope for this fork).

## Your Role

- You implement features and fix bugs specific to the RPA4All white-label client.
- You apply RPA4All branding (colors, logos, app name) defined in `./src/theme/`.
- Your documentation and explanations are written for less experienced contributors to ease understanding and learning.
- You work on an open source fork and keep customizations cleanly separated from upstream changes to ease future merges.

## RPA4All Fork Context

- **Organization**: RPA4All (Robotic Process Automation for All)
- **Upstream remote**: `origin` → `https://github.com/nextcloud/desktop`
- **Fork remote**: `rpa4all` → `https://github.com/eddiejdi/rpa4all-nextcloud-desktop`
- **Default server URL**: `https://nextcloud.rpa4all.com`
- **SSO authentication**: Authentik (`https://auth.rpa4all.com`) — used with OAuth2/OIDC
- **Target platforms**: Windows and Linux **only** — macOS customizations are **out of scope**
- **Branding config**: `./NEXTCLOUD.cmake` — arquivo CMake incluído pelo `CMakeLists.txt` com todas as variáveis de nome, domínio, URL de servidor e tema. **É aqui que as customizações RPA4All devem ser aplicadas.**
- **Ícones/logos**: Diretório `./theme/colored/` (raiz do projeto) — arquivos SVG/PNG por contexto de tema
- **Branch convention**: `rpa4all/<feature>` for customization branches, `master` for upstream tracking
- **Build pipeline**: Docker-based em `./scripts/` → produz `.deb` para LMDE 7 / Debian 13 Trixie

## Project Overview

The Nextcloud Desktop Client is a tool to synchronize files from Nextcloud Server with your computer.
Qt, C++, CMake and KDE Craft are the key technologies used for building the app on Windows and Linux.
Beyond that, there are platform-specific shell integrations in the `./shell_integration` directory.
**macOS and iOS/Android are irrelevant for this fork.**

## Project Structure: AI Agent Handling Guidelines

| Directory       | Description                                         | Agent Action         |
|-----------------|-----------------------------------------------------|----------------------|
| `./admin`       | Platform-specific build, packaging and distribution tooling | Focus on Windows (`./admin/win`) and Linux (`./admin/linux`) only |
| `./admin/osx`   | macOS build tooling                                 | **Ignore entirely**  |
| `./shell_integration/windows` | Windows Explorer shell extension | Relevant for Windows integration features |
| `./shell_integration/dolphin` | KDE Dolphin integration            | Relevant for Linux integration features |
| `./shell_integration/nautilus` | GNOME Nautilus integration        | Relevant for Linux integration features |
| `./shell_integration/MacOSX` | macOS app extensions             | **Ignore entirely**  |
| `./src/theme/`  | Branding: app name, colors, logos, default server URL | Primary target for RPA4All customizations |
| `./translations` | Translation files from Transifex.                  | Do not modify |
| `.mac-crafter`  | macOS build artifacts.                              | **Ignore entirely**  |
| `.xcode`        | macOS build artifacts.                              | **Ignore entirely**  |

## Build Pipeline

O build é feito via Docker para garantir ambiente reprodutível (Debian 13 Trixie):

```bash
# Compila e gera .deb em ./build/
./scripts/docker-build-deb.sh

# Com número fixo de jobs
./scripts/docker-build-deb.sh 4
```

**Arquivos de build** (em `./scripts/`, **não commitados ainda**):
| Arquivo | Função |
|---------|--------|
| `Dockerfile.build` | Imagem Debian Trixie com todas as dependências Qt6/KDE |
| `Dockerfile.patch` | Patch incremental sobre imagem já existente (mais rápido) |
| `compile.sh` | Executado dentro do container: cmake + ninja + cpack → `.deb` |
| `docker-build-deb.sh` | Script host: constrói a imagem e executa o container |

**Output**: `./build/rpa4all-nextcloud-desktop_<versão>_amd64.deb` — instalável em LMDE 7 / Debian 13.

## Branding / Customizações RPA4All

**Ponto central**: `./NEXTCLOUD.cmake` — incluído pelo `CMakeLists.txt` via `include(${CMAKE_SOURCE_DIR}/NEXTCLOUD.cmake)`.

Variáveis a sobrescrever para a build RPA4All:

```cmake
set( APPLICATION_NAME       "RPA4All Files" )
set( APPLICATION_SHORTNAME  "RPA4AllFiles" )
set( APPLICATION_EXECUTABLE "rpa4all-files" )
set( APPLICATION_ICON_NAME  "RPA4AllFiles" )
set( APPLICATION_CONFIG_NAME "rpa4all-files" )
set( APPLICATION_DOMAIN     "rpa4all.com" )
set( APPLICATION_VENDOR     "RPA4All" )
set( APPLICATION_SERVER_URL "https://nextcloud.rpa4all.com" CACHE STRING "" )
set( APPLICATION_SERVER_URL_ENFORCE ON )
set( APPLICATION_REV_DOMAIN "com.rpa4all.files" )
set( LINUX_PACKAGE_SHORTNAME "rpa4all-files" )
set( LINUX_APPLICATION_ID   "${APPLICATION_REV_DOMAIN}.${LINUX_PACKAGE_SHORTNAME}" )
set( THEME_CLASS            "RPA4AllTheme" )
```

**Ícones/logos**: Colocar SVGs em `./theme/colored/` seguindo as convenções de nomenclatura do upstream (ex: `wizard_logo.svg`, `Nextcloud.svg` → renomear para o `APPLICATION_ICON_NAME` definido).

**Commit convention para branding**: prefixar com `rpa4all:` para facilitar merge com upstream.

## General Guidance

Every new file needs to get a SPDX header in the first rows according to this template.
The year in the first line must be replaced with the year when the file is created (for example, 2026 for files first added in 2026).
The commenting signs need to be used depending on the file type.

```plaintext
SPDX-FileCopyrightText: <YEAR> RPA4All contributors
SPDX-License-Identifier: GPL-2.0-or-later
```

Avoid creating source files that implement multiple types; instead, place each type in its own dedicated source file.

## RPA4All Branding Guidelines

When applying branding customizations:
- **App name**: `RPA4All Files` (product name for display)
- **Default server**: `https://nextcloud.rpa4all.com` — set in theme config as `defaultServerUrl`
- **Colors**: Use corporate palette from `./src/theme/` (primary: check existing theme CMake variables)
- **Logo files**: Place in `./src/theme/` as `app.ico` (Windows) / `app.png` (Linux)
- **OAuth client**: Registrado no Authentik em `https://auth.rpa4all.com`
- Do **not** hard-code credentials or client secrets — use OAuth2 PKCE flow
- Keep all branding changes in separate commits prefixed with `rpa4all: ...` to simplify upstream merge conflict resolution

## Commit and Pull Request Guidelines

- **Commits**: Follow Conventional Commits format.
  - Upstream-tracking changes: `feat: ...`, `fix: ...`, `refactor: ...`
  - RPA4All-specific changes: prefix with `rpa4all:` — e.g., `rpa4all: update default server URL`
- Include a short summary of what changed.
- **Pull Request**: When the agent creates a PR against `rpa4all/rpa4all-main`, include a description summarizing the changes and why they were made.

## Windows-Specific Guidelines

- Target minimum: Windows 10 (x64)
- Installer built with NSIS — scripts in `./admin/win/`
- Shell integration (`./shell_integration/windows/`) uses COM for Explorer overlays
- Code signing: **not required** in development builds; leave signing config untouched
- Build verification: `cmake -DCMAKE_BUILD_TYPE=Debug .. && cmake --build .`

## Linux-Specific Guidelines

- Target distributions: Ubuntu 22.04+, Debian 12+, RHEL/Rocky 9+
- Packages: AppImage (preferred for distribution), `.deb`, `.rpm`
- Shell integrations (`./shell_integration/nautilus/`, `./shell_integration/dolphin/`) must be tested on GNOME and KDE
- Do NOT modify systemd unit files or distribution packaging scripts without explicit request
- Build verification: standard CMake flow, `cmake -DCMAKE_BUILD_TYPE=Debug ..`

## Code Style

- Do not exceed 300 lines of code per file.
- Apply fail fast principle instead of using nested if-else statements.
- Use Qt types (`QString`, `QUrl`, `QList`) consistently — avoid `std::string` in Qt-facing code.
- Use `qCDebug`/`qCWarning` for logging — never `printf` or `std::cout` in production code.
- Avoid hardcoded strings, colors, dimensions — use Qt resource files and theme variables.
- Run `clang-format` on modified files before committing.
- Do not add comments for every function — make code self-explanatory when possible.

## Tests

- Place new tests in `./test/` following existing test file naming conventions.
- Mock external network calls — never use real `https://nextcloud.rpa4all.com` in unit tests.
- Run unit tests: `ctest --test-dir <build_dir> -R <test_pattern>`
- If changes affect `./src/`, verify the project still compiles on Linux before pushing.
