# Building and Running CQRLOG on macOS

Tested on macOS (Apple Silicon / arm64). Intel Macs should work the same way.

## Prerequisites

### 1. Install Homebrew dependencies

```bash
brew install openssl@3 mariadb hamlib
```

### 2. Install Lazarus and Free Pascal via fpcupdeluxe

Download [fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases) and install:
- Free Pascal (FPC) 3.2.2 or later
- Lazarus 4.x or later

By default, fpcupdeluxe installs to `~/fpcupdeluxe/`. The `lazbuild` binary will be at `~/fpcupdeluxe/lazarus/lazbuild`.

## Building

Clone the repository and build:

```bash
git clone https://github.com/ok2cqr/cqrlog.git
cd cqrlog
make
```

The Makefile auto-detects `lazbuild` in `PATH` or `~/fpcupdeluxe/lazarus/`. To override: `make LAZBUILD=/path/to/lazbuild`

The compiled binary will be at `src/cqrlog` (Mach-O arm64, Cocoa widget set).

## Installation

```bash
make install_macos
```

This creates a macOS application bundle at `~/cqrlog/CQRLOG.app` that can be launched from Finder, Spotlight, or the terminal. The bundle includes the binary, all data files, and an app icon.

You can override the install path: `make DESTDIR=/path/to/dir install_macos`

## Running

### Start MariaDB

MariaDB must be running before you launch CQRLOG:

```bash
brew services start mariadb
```

### Launch CQRLOG

```bash
open ~/cqrlog/CQRLOG.app
```

Or double-click `CQRLOG.app` in Finder (`~/cqrlog/`).

## Troubleshooting

### "libcrypto in an unsafe way" error

Make sure `openssl@3` is installed via Homebrew (`brew install openssl@3`). CQRLOG automatically detects OpenSSL in Homebrew paths (`/opt/homebrew/opt/openssl@3/lib/` on Apple Silicon, `/usr/local/opt/openssl@3/lib/` on Intel).

### CQRLOG cannot connect to the database

Make sure MariaDB is running:

```bash
brew services list | grep mariadb
```

If it is not running, start it:

```bash
brew services start mariadb
```

### "Can not load default MySQL library" error

Make sure MariaDB is installed via Homebrew (`brew install mariadb`). CQRLOG automatically detects the MariaDB client library in Homebrew paths (`/opt/homebrew/lib/` on Apple Silicon, `/usr/local/lib/` on Intel).

### Radio control not working

Make sure hamlib is installed (`brew install hamlib`) and that `rigctld` is available in your PATH:

```bash
which rigctld
```

CQRLOG automatically detects `rigctld` and `rotctld` in Homebrew paths (`/opt/homebrew/bin/` on Apple Silicon, `/usr/local/bin/` on Intel). The detected path is shown in Preferences → TRX control. If the path is wrong, you can change it manually there.

### LoTW (TQSL) upload not working

Install TQSL from the [ARRL website](https://www.arrl.org/tqsl-download) — it installs as a `.pkg` to `/Applications/TrustedQSL/`. CQRLOG automatically detects `tqsl` at `/Applications/TrustedQSL/tqsl.app/Contents/MacOS/tqsl`. Alternatively, you can set the path manually in the LoTW export dialog.

### Xplanet grayline map not showing

Install xplanet via Homebrew:

```bash
brew install xplanet
```

CQRLOG will detect it automatically in `/opt/homebrew/bin/xplanet` (Apple Silicon) or `/usr/local/bin/xplanet` (Intel). The path can also be set manually in Preferences → Band map.

### No window appears when running the binary directly

On macOS, Cocoa applications need to be packaged as `.app` bundles to properly display windows. Use `make install_macos` and launch via `open ~/cqrlog/CQRLOG.app` instead of running the binary directly.
