# stayART

A Magisk module that enforces the Factory ART (Android Runtime) version by automatically rolling back any Play Store updates to the ART APEX module.

## What it does

- **Checks on every boot** whether the ART module has been updated from its factory version
- **Automatically rolls back** any non-factory ART updates by uninstalling user-installed versions
- **Reboots automatically** (configurable) to apply changes after rollback
- **Logs all activities** for troubleshooting and verification

## Why use this?

Some users prefer to keep the factory ART version that shipped with their ROM rather than accepting Play Store updates. This module ensures that any automatic updates to `com.android.art` or `com.google.android.art` are reverted to the original factory version.

## Installation

1. Download the latest release from the [Releases](https://github.com/HugoDataAnalyst/stayART/releases) page
2. Flash the module through Magisk Manager
3. Reboot your device

## Configuration

After first boot, the configuration file is created at:
```
/data/local/tmp/stayART_config.sh
```

### Available options:

```bash
# Enable or disable automatic reboot after rollback (1 = enabled, 0 = disabled)
AUTO_REBOOT=1

# Log verbosity level (0 = minimal, 1 = normal, 2 = verbose)
LOG_LEVEL=1
```

Edit this file and reboot to apply changes.

## How it works

The module reads `/apex/apex-info-list.xml` to detect whether the ART module is running a factory or user-installed version. It checks for `isFactory="false"` on the ART package entries:

- `com.android.art` (AOSP ART)
- `com.google.android.art` (Google ART)

If a non-factory version is detected, the module issues an uninstall command via `pm uninstall` and optionally reboots to apply changes.

## Logs

Execution logs are stored at:
```
/data/local/tmp/stayART.log
```

View logs with:
```bash
adb shell cat /data/local/tmp/stayART.log
```

## Requirements

- Android device with Magisk v20.4+
- Root access

## Credits

Based on the structure of [stayGMS](https://github.com/HugoDataAnalyst/stayGMS).

## License

MIT License
