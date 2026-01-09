#!/system/bin/sh
#########################################################################
# StayART - Enforce Factory ART Version
# Checks /apex/apex-info-list.xml for non-factory updates.
#########################################################################

# --- Configuration ---
LOG_TAG="StayART"
PKG_INTERNAL="com.android.art"
PKG_GOOGLE="com.google.android.art"
APEX_INFO="/apex/apex-info-list.xml"
LOG_FILE="/data/local/tmp/stayART.log"
CONFIG_FILE="/data/local/tmp/stayART_config.sh"
MODULE_CONFIG="/data/adb/modules/stay_art/config.sh"

# Default configuration
AUTO_REBOOT=1
LOG_LEVEL=1

log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$LOG_TAG] $1"
    echo "$msg" >> "$LOG_FILE"
    if [ "$LOG_LEVEL" -ge 1 ]; then
        log -t "$LOG_TAG" "$1"
    fi
}

log_verbose() {
    if [ "$LOG_LEVEL" -ge 2 ]; then
        log_msg "[VERBOSE] $1"
    fi
}

# Wait for system to be ready
sleep 30

# Initialize log file
echo "========================================" >> "$LOG_FILE"
log_msg "StayART service starting..."

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    log_verbose "Loading user config from $CONFIG_FILE"
    . "$CONFIG_FILE"
elif [ -f "$MODULE_CONFIG" ]; then
    log_verbose "Loading module config from $MODULE_CONFIG"
    . "$MODULE_CONFIG"
    # Copy to user location for easier editing
    cp "$MODULE_CONFIG" "$CONFIG_FILE"
    log_msg "Config copied to $CONFIG_FILE for customization"
fi

# Ensure we are Root
if [ "$(id -u)" -ne 0 ]; then
    log_msg "Error: This script requires Root access."
    exit 1
fi

log_msg "Checking ART module status..."

# --- Detection Logic ---
# We look for the package name AND 'isFactory="false"' on the same line.
# This confirms a user-update is active.

DETECTED_INTERNAL=$(grep -F "$PKG_INTERNAL" "$APEX_INFO" | grep 'isFactory="false"')
DETECTED_GOOGLE=$(grep -F "$PKG_GOOGLE" "$APEX_INFO" | grep 'isFactory="false"')

UPDATE_FOUND=0

if [ ! -z "$DETECTED_INTERNAL" ]; then
    log_msg "DETECTED: Non-factory update found for $PKG_INTERNAL"
    TARGET_PKG="$PKG_INTERNAL"
    UPDATE_FOUND=1
elif [ ! -z "$DETECTED_GOOGLE" ]; then
    log_msg "DETECTED: Non-factory update found for $PKG_GOOGLE"
    TARGET_PKG="$PKG_GOOGLE"
    UPDATE_FOUND=1
fi

# --- Action Logic ---
if [ $UPDATE_FOUND -eq 1 ]; then
    log_msg "Initiating rollback to Factory version..."

    # Attempt uninstall for the specific target
    pm uninstall "$TARGET_PKG" > /dev/null 2>&1
    log_verbose "Uninstalled $TARGET_PKG"

    # Double tap: Try the other name just in case of weird aliasing
    if [ "$TARGET_PKG" = "$PKG_INTERNAL" ]; then
        pm uninstall "$PKG_GOOGLE" > /dev/null 2>&1
        log_verbose "Also attempted uninstall of $PKG_GOOGLE"
    else
        pm uninstall "$PKG_INTERNAL" > /dev/null 2>&1
        log_verbose "Also attempted uninstall of $PKG_INTERNAL"
    fi

    log_msg "Uninstall command issued."

    if [ "$AUTO_REBOOT" -eq 1 ]; then
        log_msg "Rebooting immediately to apply changes..."
        reboot
    else
        log_msg "AUTO_REBOOT disabled. Manual reboot required to apply changes."
    fi
else
    log_msg "Status Normal: System is running Factory ART (Original ROM version)."
    # Print the current version code for verification
    CURRENT_VER=$(grep -F "$PKG_INTERNAL" "$APEX_INFO" | sed -n 's/.*versionCode="\([^"]*\)".*/\1/p')
    if [ -z "$CURRENT_VER" ]; then
         CURRENT_VER=$(grep -F "$PKG_GOOGLE" "$APEX_INFO" | sed -n 's/.*versionCode="\([^"]*\)".*/\1/p')
    fi
    if [ ! -z "$CURRENT_VER" ]; then
        log_msg "Current Active VersionCode: $CURRENT_VER"
    fi
fi

# --- Disable Update Services ---
log_msg "Ensuring update services are disabled..."

pm disable --user 0 com.google.android.gms/.update.SystemUpdatePersistentListenerService 2>/dev/null
if [ $? -eq 0 ]; then
    log_msg "Disabled SystemUpdatePersistentListenerService"
else
    log_verbose "SystemUpdatePersistentListenerService already disabled or not found"
fi

pm disable --user 0 com.google.android.gms/.update.SystemUpdateService 2>/dev/null
if [ $? -eq 0 ]; then
    log_msg "Disabled SystemUpdateService"
else
    log_verbose "SystemUpdateService already disabled or not found"
fi

log_msg "StayART service completed."
