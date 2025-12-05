#!/bin/bash
# my-alert - Setup Script
# macOS launchd 기반 범용 알림 시스템 설치

set -e

echo "🔔 my-alert Setup"
echo "================="
echo ""

# Paths
SKILL_SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/Library/Scripts/my-alert"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
CACHE_DIR="$HOME/.claude/cache/my-alert"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$LAUNCHD_DIR"
mkdir -p "$CACHE_DIR"
echo -e "${GREEN}✓${NC} Directories created"
echo ""

# Copy scripts
echo "📋 Installing scripts..."
SCRIPTS=(
    "show-alert.sh"
    "register-alert.sh"
    "run-alerts.sh"
    "list-alerts.sh"
    "cancel-alert.sh"
    "update-alert.sh"
)

for script in "${SCRIPTS[@]}"; do
    cp "$SKILL_SCRIPTS/$script" "$INSTALL_DIR/$script"
    chmod +x "$INSTALL_DIR/$script"
    echo -e "  ${GREEN}✓${NC} $script"
done
echo ""

# Initialize cache
if [ ! -f "$CACHE_DIR/alerts.json" ]; then
    echo '{"alerts":[]}' > "$CACHE_DIR/alerts.json"
    echo -e "${GREEN}✓${NC} Cache initialized"
    echo ""
fi

# Install launchd plist for alert runner (1 minute)
echo "⏱️  Installing scheduler..."
RUNNER_PLIST="$LAUNCHD_DIR/com.user.my-alert-runner.plist"
cat > "$RUNNER_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.my-alert-runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$INSTALL_DIR/run-alerts.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/my-alert-runner.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/my-alert-runner.error.log</string>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

launchctl unload "$RUNNER_PLIST" 2>/dev/null || true
launchctl load "$RUNNER_PLIST"
echo -e "  ${GREEN}✓${NC} Alert runner (1분마다)"
echo ""

echo "✅ my-alert 설치 완료!"
echo ""
echo "사용법:"
echo "  register-alert.sh \"2025-12-03 14:00\" \"알림 메시지\" \"dialog\""
echo ""
