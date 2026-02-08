# Screenpipe Agent

Automated setup for running [screenpipe](https://github.com/mediar-ai/screenpipe) as a background service on macOS with auto-updates via Homebrew.

## Features

- 🚀 Auto-start screenpipe on login (via launchd)
- 🔄 Auto-update daily via Homebrew (3 AM by default)
- 📝 Comprehensive logging
- 🛠️ Easy install/uninstall
- ⚙️ Configurable update schedule

## Prerequisites

1. **macOS** >= 14 (Sonoma)
2. **Homebrew** installed at `/opt/homebrew/`
3. **screenpipe** installed via Homebrew:
   ```bash
   brew install screenpipe
   ```

## Quick Install

```bash
cd /Users/kodey/Code/screenpipe-agent
./install.sh
```

The install script will:
- ✅ Verify prerequisites
- ✅ Set up launchd agents
- ✅ Configure auto-updates
- ✅ Start screenpipe immediately
- ✅ Grant necessary permissions

## What Gets Installed

- **LaunchAgent for screenpipe**: `~/Library/LaunchAgents/com.screenpipe.agent.plist`
- **LaunchAgent for auto-updates**: `~/Library/LaunchAgents/com.screenpipe.autoupdate.plist`
- **Update script**: `~/Library/Scripts/screenpipe/update-screenpipe.sh`
- **Restart script**: `~/Library/Scripts/screenpipe/restart-screenpipe.sh`

## Required Permissions

After installation, you'll need to grant permissions in **System Settings**:

1. **Screen Recording**:
   - System Settings → Privacy & Security → Screen Recording
   - Enable for the process running screenpipe

2. **Microphone**:
   - System Settings → Privacy & Security → Microphone
   - Enable for the process running screenpipe

3. **Accessibility** (if needed):
   - System Settings → Privacy & Security → Accessibility

## Usage

### Check Status
```bash
# Check if screenpipe is running
launchctl list | grep screenpipe
ps aux | grep screenpipe
```

### View Logs
```bash
# Screenpipe output
tail -f /tmp/screenpipe.log

# Screenpipe errors
tail -f /tmp/screenpipe.error.log

# Auto-update logs
tail -f /tmp/screenpipe-update.log
```

### Manual Operations
```bash
# Restart screenpipe
launchctl kickstart -k gui/$(id -u)/com.screenpipe.agent

# Stop screenpipe
launchctl stop com.screenpipe.agent

# Start screenpipe
launchctl start com.screenpipe.agent

# Manually trigger update
~/Library/Scripts/screenpipe/update-screenpipe.sh
```

### Access API
```bash
# Screenpipe API runs on localhost:3030
curl http://localhost:3030/search?q=test&limit=5
```

### Data Location
By default, screenpipe stores data in:
```
~/.screenpipe/
```

## Configuration

### Change Auto-Update Time

Edit `~/Library/LaunchAgents/com.screenpipe.autoupdate.plist`:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>3</integer>  <!-- Change this (0-23) -->
    <key>Minute</key>
    <integer>0</integer>   <!-- Change this (0-59) -->
</dict>
```

Then reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.screenpipe.autoupdate.plist
launchctl load ~/Library/LaunchAgents/com.screenpipe.autoupdate.plist
```

### Disable Auto-Updates

```bash
launchctl unload ~/Library/LaunchAgents/com.screenpipe.autoupdate.plist
```

### Re-enable Auto-Updates

```bash
launchctl load ~/Library/LaunchAgents/com.screenpipe.autoupdate.plist
```

## Uninstall

```bash
cd /Users/kodey/Code/screenpipe-agent
./uninstall.sh
```

This will:
- Stop and remove all launchd agents
- Remove scripts from `~/Library/Scripts/screenpipe/`
- Clean up logs
- **Note**: Data in `~/.screenpipe/` is preserved

To also remove data:
```bash
rm -rf ~/.screenpipe
```

## Troubleshooting

### Screenpipe won't start
```bash
# Check logs for errors
tail -n 50 /tmp/screenpipe.error.log

# Verify binary exists
ls -la /opt/homebrew/bin/screenpipe

# Try running manually
/opt/homebrew/bin/screenpipe
```

### Updates not working
```bash
# Check update logs
tail -f /tmp/screenpipe-update.log

# Verify brew works
brew update
brew outdated | grep screenpipe

# Run update script manually
~/Library/Scripts/screenpipe/update-screenpipe.sh
```

### Permission denied errors
```bash
# Verify launch agent files are readable
ls -la ~/Library/LaunchAgents/com.screenpipe.*

# Verify script permissions
ls -la ~/Library/Scripts/screenpipe/
```

### Service won't auto-start on login
```bash
# Reload launch agent
launchctl unload ~/Library/LaunchAgents/com.screenpipe.agent.plist
launchctl load ~/Library/LaunchAgents/com.screenpipe.agent.plist

# Check for errors
launchctl list | grep screenpipe
```

## Resource Usage

When running, screenpipe typically uses:
- **CPU**: ~10%
- **RAM**: ~4GB
- **Storage**: ~15GB/month

## Next Steps

Once screenpipe is running, you can:

1. **Query the API** to build custom integrations
2. **Access the SQLite database** at `~/.screenpipe/db.sqlite`
3. **Build task automation** using the screenpipe data
4. **Install pipes** (plugins) from the screenpipe ecosystem

## Repository Structure

```
screenpipe-agent/
├── README.md                           # This file
├── install.sh                          # Installation script
├── uninstall.sh                        # Removal script
├── launchd/
│   ├── com.screenpipe.agent.plist     # Main service config
│   └── com.screenpipe.autoupdate.plist # Auto-update config
├── scripts/
│   ├── update-screenpipe.sh           # Update logic
│   └── restart-screenpipe.sh          # Restart helper
└── config/
    └── .screenpipe.env                # Optional config
```

## Contributing

Found a bug or want to improve this setup? Feel free to submit issues or PRs.

## License

MIT

## Links

- [Screenpipe GitHub](https://github.com/mediar-ai/screenpipe)
- [Screenpipe Documentation](https://docs.screenpi.pe)
- [Screenpipe Website](https://screenpi.pe)