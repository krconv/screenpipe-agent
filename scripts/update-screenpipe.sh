#!/bin/bash

# Screenpipe Auto-Update Script
# Updates screenpipe via Homebrew and restarts the service if updated

set -e

LOG_FILE="/tmp/screenpipe-update.log"
USER_ID=$(id -u)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "========================================"
log "Starting screenpipe update check"

# Check if Homebrew exists
if [ ! -f "/opt/homebrew/bin/brew" ]; then
    log "ERROR: Homebrew not found at /opt/homebrew/bin/brew"
    exit 1
fi

# Update Homebrew
log "Updating Homebrew..."
if ! /opt/homebrew/bin/brew update >> "$LOG_FILE" 2>&1; then
    log "ERROR: Failed to update Homebrew"
    exit 1
fi

# Check if screenpipe is installed
if ! /opt/homebrew/bin/brew list screenpipe > /dev/null 2>&1; then
    log "ERROR: screenpipe is not installed via Homebrew"
    exit 1
fi

# Check if screenpipe needs updating
if /opt/homebrew/bin/brew outdated | grep -q screenpipe; then
    log "Update available for screenpipe"
    
    # Get current version
    CURRENT_VERSION=$(/opt/homebrew/bin/brew list --versions screenpipe | awk '{print $2}')
    log "Current version: $CURRENT_VERSION"
    
    # Upgrade screenpipe
    log "Upgrading screenpipe..."
    if /opt/homebrew/bin/brew upgrade screenpipe >> "$LOG_FILE" 2>&1; then
        # Get new version
        NEW_VERSION=$(/opt/homebrew/bin/brew list --versions screenpipe | awk '{print $2}')
        log "Updated to version: $NEW_VERSION"
        
        # Restart the service
        log "Restarting screenpipe service..."
        if /bin/launchctl kickstart -k "gui/${USER_ID}/com.screenpipe.agent"; then
            log "Screenpipe service restarted successfully"
            
            # Wait a moment for service to start
            sleep 3
            
            # Verify service is running
            if /bin/launchctl list | grep -q "com.screenpipe.agent"; then
                log "Screenpipe is running"
            else
                log "WARNING: Screenpipe may not have started correctly"
            fi
        else
            log "ERROR: Failed to restart screenpipe service"
            exit 1
        fi
        
        log "Update completed successfully"
    else
        log "ERROR: Failed to upgrade screenpipe"
        exit 1
    fi
else
    log "Screenpipe is up to date"
fi

log "Update check completed"
log "========================================"