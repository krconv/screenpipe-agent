#!/bin/bash

# Screenpipe Agent Uninstaller
# Removes all screenpipe agent components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

USER_HOME="${HOME}"
USER_ID=$(id -u)

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Screenpipe Agent Uninstaller${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to print colored messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Confirm uninstallation
echo -e "${YELLOW}This will remove:${NC}"
echo "  • Screenpipe LaunchAgent"
echo "  • Auto-update LaunchAgent"
echo "  • Scripts in ~/Library/Scripts/screenpipe/"
echo "  • Log files in /tmp/"
echo ""
echo -e "${YELLOW}This will NOT remove:${NC}"
echo "  • Screenpipe binary (use 'brew uninstall screenpipe' for that)"
echo "  • Data in ~/.screenpipe/ (remove manually if desired)"
echo ""

read -p "Continue with uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled"
    exit 0
fi

echo ""
info "Stopping and removing services..."

# Stop and unload LaunchAgents
if launchctl list | grep -q "com.screenpipe.agent"; then
    if launchctl bootout "gui/${USER_ID}/com.screenpipe.agent" 2>/dev/null; then
        success "Stopped screenpipe service"
    else
        warning "Could not stop screenpipe service (may not be running)"
    fi
else
    info "Screenpipe service not running"
fi

if launchctl list | grep -q "com.screenpipe.autoupdate"; then
    if launchctl bootout "gui/${USER_ID}/com.screenpipe.autoupdate" 2>/dev/null; then
        success "Stopped auto-update service"
    else
        warning "Could not stop auto-update service (may not be running)"
    fi
else
    info "Auto-update service not running"
fi

# Remove LaunchAgent plists
info "Removing LaunchAgent files..."

if [ -f "${USER_HOME}/Library/LaunchAgents/com.screenpipe.agent.plist" ]; then
    rm "${USER_HOME}/Library/LaunchAgents/com.screenpipe.agent.plist"
    success "Removed com.screenpipe.agent.plist"
fi

if [ -f "${USER_HOME}/Library/LaunchAgents/com.screenpipe.autoupdate.plist" ]; then
    rm "${USER_HOME}/Library/LaunchAgents/com.screenpipe.autoupdate.plist"
    success "Removed com.screenpipe.autoupdate.plist"
fi

# Remove scripts
info "Removing scripts..."

if [ -d "${USER_HOME}/Library/Scripts/screenpipe" ]; then
    rm -rf "${USER_HOME}/Library/Scripts/screenpipe"
    success "Removed scripts directory"
fi

# Remove log files
info "Removing log files..."

for log in /tmp/screenpipe*.log /tmp/screenpipe*.error.log; do
    if [ -f "$log" ]; then
        rm "$log"
        success "Removed $(basename "$log")"
    fi
done

# Verify cleanup
echo ""
info "Verifying cleanup..."

if launchctl list | grep -q "com.screenpipe"; then
    warning "Some screenpipe services may still be loaded"
    echo "Try running: launchctl list | grep screenpipe"
else
    success "No screenpipe services running"
fi

if pgrep -f screenpipe > /dev/null; then
    warning "Screenpipe process still running (may need manual kill)"
    echo "PID: $(pgrep -f screenpipe)"
else
    success "No screenpipe processes running"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Uninstall Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

echo -e "${YELLOW}Optional cleanup:${NC}"
echo ""
echo "Remove screenpipe data (WARNING: deletes all recordings):"
echo "  rm -rf ~/.screenpipe"
echo ""
echo "Uninstall screenpipe via Homebrew:"
echo "  brew uninstall screenpipe"
echo ""