# OpenWrt Package Files Description

## Directory Structure

```
libnfc-nci/
├── Makefile                          # OpenWrt package build script
├── README.md                        # Package documentation
├── PACKAGE_CONTENT.md              # This file
│
├── patches/                         # Patches applied to source code
│   ├── 001-change-config-dir.patch            # Change config install dir to /etc/nfc
│   ├── 002-fix-transport-config-path.patch    # Fix transport config path
│   ├── 003-fix-config-path-provider.patch     # Fix all config paths in provider
│   └── 100-64bit-support.patch                # 64-bit architecture support
│
├── files/                          # Additional files to install on target
│   ├── nfc.init                    # Init script for /etc/init.d/nfc
│   ├── nfc.config                  # UCI config for /etc/config/nfc
│   └── nfc-helper                  # Helper script for /usr/sbin/nfc-helper
│
└── src/                            # (Reserved for local source overrides)
```

## Patches Details

### Configuration Path Patches (001-003)

These patches modify the source code to use `/etc/nfc/` instead of `/usr/local/etc/`:

**001-change-config-dir.patch**
- File: `Makefile.am`
- Changes: `configdir = ${sysconfdir}/nfc`
- Purpose: Install configuration files to `/etc/nfc/`

**002-fix-transport-config-path.patch**
- File: `src/nxp_nci_hal_libnfc-nci/utils/config.cc`
- Changes: `transport_config_path[] = "/etc/nfc/"`
- Purpose: Update transport config path in runtime code

**003-fix-config-path-provider.patch**
- File: `src/libnfc-utils/src/ConfigPathProvider.cc`
- Changes: All config paths updated to `/etc/nfc/`
  - VENDOR_NFC_CONFIG → `/etc/nfc/libnfc-nxp.conf`
  - VENDOR_ESE_CONFIG → `/etc/nfc/libese-nxp.conf`
  - SYSTEM_CONFIG → `/etc/nfc/libnfc-nci.conf`
  - RF_CONFIG → `/etc/nfc/libnfc-nxp_RF.conf`
  - TRANSIT_CONFIG → `/etc/nfc/libnfc-nxpTransit.conf`
- Purpose: Update all configuration file search paths

### Architecture Support Patch (100)

**100-64bit-support.patch**
- Files: Multiple source files
- Changes:
  - Type conversions (unsigned int ↔ size_t)
  - Pointer dereference fixes
  - Integer type compatibility
- Purpose: Support 64-bit architectures properly
- Source: Official NXP patch from `64bit_patch/ROOT_src.patch`

## Files Details

### nfc.init

**Installation Path**: `/etc/init.d/nfc`

**Purpose**: OpenWrt init script using procd

**Features**:
- START=95 (starts late in boot sequence)
- STOP=10 (stops early in shutdown)
- Checks for configuration files
- Loads i2c-dev module if needed
- Template for running nfcDemoApp as a service (commented out by default)

**Usage**:
```bash
/etc/init.d/nfc start
/etc/init.d/nfc stop
/etc/init.d/nfc enable   # Enable at boot
```

### nfc.config

**Installation Path**: `/etc/config/nfc`

**Purpose**: UCI (Unified Configuration Interface) configuration file

**Settings**:
- `enabled`: Enable/disable NFC (1/0)
- `debug_level`: Debug verbosity (0-4)
- `i2c_device`: I2C device path
- `gpio_irq`: IRQ GPIO pin number
- `gpio_ven`: VEN (enable) GPIO pin number
- `gpio_dwl`: Download mode GPIO pin number

**Usage**:
```bash
uci show nfc
uci set nfc.settings.debug_level=3
uci commit nfc
```

### nfc-helper

**Installation Path**: `/usr/sbin/nfc-helper`

**Purpose**: Helper script for common NFC operations

**Commands**:
- `start` - Start NFC demo app in background
- `stop` - Stop NFC demo app
- `status` - Check if app is running
- `test` - Run hardware and configuration checks
- `check` - Check NFC hardware availability
- `config` - Display configuration files
- `help` - Show help message

**Usage Examples**:
```bash
nfc-helper check        # Check hardware and config
nfc-helper test         # Run basic test
nfc-helper start        # Start demo app
nfc-helper status       # Check status
nfc-helper stop         # Stop demo app
```

## Build Process

### 1. Download Source

OpenWrt automatically downloads from:
- URL: https://github.com/NXPNFCLinux/linux_libnfc-nci.git
- Branch: NCI2.0_PN7160

### 2. Apply Patches

Patches are applied in numerical order:
1. 001-change-config-dir.patch
2. 002-fix-transport-config-path.patch
3. 003-fix-config-path-provider.patch
4. 100-64bit-support.patch

### 3. Configure

```bash
./configure --prefix=/usr --sysconfdir=/etc/nfc
```

Additional CFLAGS:
- `-DCONFIG_PATH='"/etc/nfc/"'`

### 4. Compile

Standard autotools build:
```bash
make
make install DESTDIR=$(PKG_INSTALL_DIR)
```

### 5. Package Installation

Files installed to target system:

**libnfc-nci package**:
```
/usr/lib/libnfc_nci_linux.so*
/etc/nfc/libnfc-nci.conf
/etc/nfc/libnfc-nxp.conf
/etc/config/nfc
/etc/init.d/nfc
```

**libnfc-nci-utils package**:
```
/usr/sbin/nfcDemoApp
/usr/sbin/nfc-helper
```

**libpn7160-fw package**:
```
/usr/lib/libpn7160_fw.so*
```

## Patch Maintenance

### Adding New Patches

1. Create patch file in `patches/` directory
2. Use naming convention: `NNN-description.patch`
   - 000-099: Configuration changes
   - 100-199: Architecture/platform fixes
   - 200-299: Feature additions
   - 300-399: Bug fixes
   - 900-999: Local/temporary patches

3. Patch format (unified diff):
```patch
--- a/path/to/file
+++ b/path/to/file
@@ -line,count +line,count @@
 context line
-removed line
+added line
 context line
```

### Updating Patches

When source code changes, patches may need refreshing:

```bash
cd $(OPENWRT_DIR)
make package/libnfc-nci/refresh
```

This regenerates patches based on current changes.

### Testing Patches

```bash
# Clean build
make package/libnfc-nci/clean

# Rebuild with verbose output
make package/libnfc-nci/compile V=s

# Check build log
tail -f $(OPENWRT_DIR)/logs/package/feeds/packages/libnfc-nci/compile.txt
```

## File Modifications

### Adding Files to Installation

Edit `Makefile`, add to appropriate install section:

```makefile
define Package/libnfc-nci/install
	$(INSTALL_DIR) $(1)/path/to/dir
	$(INSTALL_DATA) ./files/myconfig $(1)/path/to/dir/
endef
```

Install macros:
- `INSTALL_DIR` - Create directory
- `INSTALL_DATA` - Install data file (0644)
- `INSTALL_CONF` - Install config file (0600)
- `INSTALL_BIN` - Install executable (0755)

## Configuration Override

### Runtime Override

Environment variables can override config paths:
```bash
export LIBNFC_NCI_CONF_PATH=/custom/path/
nfcDemoApp poll
```

### Build-time Override

Edit Makefile:
```makefile
CONFIGURE_ARGS += \
	--sysconfdir=/custom/etc/path
```

## Dependencies Graph

```
libnfc-nci (base library)
    ├── libstdcpp
    ├── libpthread
    ├── librt
    └── libgpiod
    
libnfc-nci-utils (utilities)
    └── libnfc-nci
    
libpn7160-fw (firmware)
    └── libnfc-nci
```

## Integration with Other Packages

### Using libnfc-nci in Your Package

**Makefile**:
```makefile
PKG_BUILD_DEPENDS:=libnfc-nci

define Package/your-package
  DEPENDS:=+libnfc-nci
endef
```

**Code**:
```c
#include <linux_nfc_api.h>
// Use NFC API functions
```

## Troubleshooting Build Issues

### Patch Fails to Apply

```bash
# Check patch format
cd $(PKG_BUILD_DIR)
patch -p1 --dry-run < /path/to/patch

# Manually fix and regenerate
make package/libnfc-nci/refresh
```

### Missing Dependencies

```bash
# Check dependencies
opkg list | grep libgpiod

# Install on build host
./scripts/feeds install libgpiod
```

### Configuration Path Issues

Check compiled binary for hardcoded paths:
```bash
strings /usr/lib/libnfc_nci_linux.so | grep -E '/(etc|usr)'
```

## Version Control

Keep track of patch versions matching source versions:
- Document source git commit hash
- Version patches when updating source
- Keep changelog of patch modifications
