#!/bin/bash

# Screenpipe Restart Script
# Simple helper to restart the screenpipe service

USER_ID=$(id -u)

echo "Restarting screenpipe service..."

if /bin/launchctl kickstart -k "gui/${USER_ID}/com.screenpipe.agent"; then
    echo "✓ Screenpipe restarted successfully"
    
    # Wait a moment
    sleep 2
    
    # Check status
    if /bin/launchctl list | grep -q "com.screenpipe.agent"; then
        echo "✓ Screenpipe is running"
        echo ""
        echo "View logs: tail -f /tmp/screenpipe.log"
    else
        echo "⚠ Warning: Service may not have started"
        echo "Check errors: tail -f /tmp/screenpipe.error.log"
    fi
else
    echo "✗ Failed to restart screenpipe"
    exit 1
fi