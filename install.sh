#!/bin/bash

# Screenpipe Agent Installation Script
# Sets up screenpipe to run as a background service with auto-updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME}"
USER_ID=$(id -u)

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Screenpipe Agent Installer${NC}"
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

# Check prerequisites
info "Checking prerequisites..."

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
info "macOS version: $MACOS_VERSION"

# Check if Homebrew is installed
if [ ! -f "/opt/homebrew/bin/brew" ]; then
    error "Homebrew not found at /opt/homebrew/bin/brew"
    echo ""
    echo "Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
success "Homebrew found"

# Check if screenpipe is installed
if [ ! -f "/opt/homebrew/bin/screenpipe" ]; then
    error "screenpipe not found at /opt/homebrew/bin/screenpipe"
    echo ""
    echo "Please install screenpipe first:"
    echo "  brew install screenpipe"
    exit 1
fi
success "screenpipe found"

# Get screenpipe version
SCREENPIPE_VERSION=$(/opt/homebrew/bin/brew list --versions screenpipe | awk '{print $2}')
info "screenpipe version: $SCREENPIPE_VERSION"

echo ""
info "Setting up screenpipe agent..."

# Create necessary directories
mkdir -p "${USER_HOME}/Library/LaunchAgents"
mkdir -p "${USER_HOME}/Library/Scripts/screenpipe"

# Process and copy LaunchAgent plists
info "Installing LaunchAgent configurations..."

for plist in "${SCRIPT_DIR}/launchd"/*.plist; do
    if [ -f "$plist" ]; then
        filename=$(basename "$plist")
        target="${USER_HOME}/Library/LaunchAgents/${filename}"
        
        # Replace template variables
        sed "s|{{USER_HOME}}|${USER_HOME}|g" "$plist" > "$target"
        
        success "Installed ${filename}"
    fi
done

# Copy scripts
info "Installing scripts..."

for script in "${SCRIPT_DIR}/scripts"/*.sh; do
    if [ -f "$script" ]; then
        filename=$(basename "$script")
        target="${USER_HOME}/Library/Scripts/screenpipe/${filename}"
        
        cp "$script" "$target"
        chmod +x "$target"
        
        success "Installed ${filename}"
    fi
done

# Stop existing services if running
info "Stopping existing services (if any)..."
launchctl bootout "gui/${USER_ID}/com.screenpipe.agent" 2>/dev/null || true
launchctl bootout "gui/${USER_ID}/com.screenpipe.autoupdate" 2>/dev/null || true
sleep 1

# Load and start LaunchAgents
info "Loading screenpipe service..."
if launchctl bootstrap "gui/${USER_ID}" "${USER_HOME}/Library/LaunchAgents/com.screenpipe.agent.plist"; then
    success "Screenpipe service loaded"
else
    warning "Service may already be loaded, attempting to restart..."
    launchctl kickstart -k "gui/${USER_ID}/com.screenpipe.agent"
fi

info "Loading auto-update service..."
if launchctl bootstrap "gui/${USER_ID}" "${USER_HOME}/Library/LaunchAgents/com.screenpipe.autoupdate.plist"; then
    success "Auto-update service loaded"
else
    warning "Auto-update service may already be loaded"
fi

# Wait a moment for service to start
sleep 3

# Verify services are running
echo ""
info "Verifying installation..."

if launchctl list | grep -q "com.screenpipe.agent"; then
    success "Screenpipe service is running"
else
    error "Screenpipe service is not running"
    echo ""
    echo "Check logs for errors:"
    echo "  tail -f /tmp/screenpipe.error.log"
    exit 1
fi

if launchctl list | grep -q "com.screenpipe.autoupdate"; then
    success "Auto-update service is loaded"
else
    warning "Auto-update service may not be loaded"
fi

# Check if screenpipe process is actually running
if pgrep -f screenpipe > /dev/null; then
    success "Screenpipe process is running"
else
    warning "Screenpipe process not detected yet (may still be starting)"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

echo -e "${YELLOW}IMPORTANT: You need to grant permissions:${NC}"
echo ""
echo "1. Screen Recording Permission:"
echo "   System Settings → Privacy & Security → Screen Recording"
echo ""
echo "2. Microphone Permission:"
echo "   System Settings → Privacy & Security → Microphone"
echo ""
echo "3. Accessibility (if prompted):"
echo "   System Settings → Privacy & Security → Accessibility"
echo ""

echo "Useful commands:"
echo "  • View logs:          tail -f /tmp/screenpipe.log"
echo "  • View errors:        tail -f /tmp/screenpipe.error.log"
echo "  • Restart service:    launchctl kickstart -k gui/\$(id -u)/com.screenpipe.agent"
echo "  • Check status:       launchctl list | grep screenpipe"
echo "  • Access API:         curl http://localhost:3030/search?q=test"
echo "  • Uninstall:          ${SCRIPT_DIR}/uninstall.sh"
echo ""

echo -e "${BLUE}Data will be stored in: ${USER_HOME}/.screenpipe/${NC}"
echo -e "${BLUE}Auto-updates will run daily at 3:00 AM${NC}"
echo ""