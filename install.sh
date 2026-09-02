#!/bin/sh
# ==============================================================================
# GitHub Contribution Widget for macOS - Installer
# Usage:
#   sh install.sh [--login] [--build-only] [--uninstall]
# ==============================================================================

set -e

APP_NAME="GitContributionWidget"
BUNDLE_ID="com.user.gitcontributionwidget"
INSTALL_DIR="$HOME/Applications"
APP_DEST="$INSTALL_DIR/${APP_NAME}.app"
CONFIG_DIR="$HOME/Library/Application Support/${APP_NAME}"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/${BUNDLE_ID}.plist"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    printf "${BLUE}==>${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}✔${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}▲${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✖${NC} %s\n" "$1"
}

show_help() {
    printf "GitHub Contribution Widget for macOS\n\n"
    printf "Usage:\n"
    printf "  sh install.sh [OPTIONS]\n\n"
    printf "Options:\n"
    printf "  --login             Automatically launch on macOS login\n"
    printf "  --build-only        Only compile the .app bundle without installing\n"
    printf "  --uninstall         Uninstall the widget, LaunchAgent, and config\n"
    printf "  --help, -h          Show this help message\n\n"
    printf "Example:\n"
    printf "  sh install.sh\n"
    printf "  sh install.sh --login\n"
    exit 0
}

GITHUB_ID=""
START_AT_LOGIN=false
BUILD_ONLY=false
UNINSTALL=false

while [ $# -gt 0 ]; do
    case "$1" in

        --login)
            START_AT_LOGIN=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# Uninstall Flow
if [ "$UNINSTALL" = true ]; then
    print_info "Uninstalling ${APP_NAME}..."
    
    killall "$APP_NAME" 2>/dev/null || true
    
    if [ -f "$LAUNCH_AGENT_PLIST" ]; then
        launchctl unload "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
        rm -f "$LAUNCH_AGENT_PLIST"
        print_success "Removed LaunchAgent: $LAUNCH_AGENT_PLIST"
    fi
    
    if [ -d "$APP_DEST" ]; then
        rm -rf "$APP_DEST"
        print_success "Removed Application: $APP_DEST"
    fi
    
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        print_success "Removed Config & Cache: $CONFIG_DIR"
    fi
    
    print_success "${APP_NAME} has been completely uninstalled."
    exit 0
fi



# Step 1: Check Swift Compiler
print_info "Checking Swift compiler toolchain..."
if ! command -v swiftc >/dev/null 2>&1; then
    print_error "swiftc compiler not found. Please install Xcode Command Line Tools (xcode-select --install)."
    exit 1
fi
SWIFT_VER=$(swiftc --version | head -n 1)
print_success "Swift compiler detected: $SWIFT_VER"

# Step 2: Prepare App Bundle Directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
TEMP_APP="$BUILD_DIR/${APP_NAME}.app"
MACOS_DIR="$TEMP_APP/Contents/MacOS"
RESOURCES_DIR="$TEMP_APP/Contents/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Step 3: Compile Swift Sources
print_info "Compiling Clean Architecture Swift codebase..."
SWIFT_FILES=$(find "$SCRIPT_DIR/src" -name "*.swift")

swiftc -O \
    -target arm64-apple-macos12.0 \
    -parse-as-library \
    $SWIFT_FILES \
    -o "$MACOS_DIR/$APP_NAME"

print_success "Compilation succeeded -> $MACOS_DIR/$APP_NAME"

# Step 4: Generate Info.plist
print_info "Generating Info.plist..."
cat <<EOF > "$TEMP_APP/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>GitHub Contributions</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF
print_success "Info.plist generated."

if [ "$BUILD_ONLY" = true ]; then
    print_success "Build complete! App bundle located at: $TEMP_APP"
    exit 0
fi

# Step 5: Install App to ~/Applications
print_info "Installing app to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

killall "$APP_NAME" 2>/dev/null || true
sleep 0.5

rm -rf "$APP_DEST"
cp -R "$TEMP_APP" "$APP_DEST"
print_success "App bundle installed at: $APP_DEST"

# Step 6: Configure Initial Settings
print_info "Initializing configuration..."
mkdir -p "$CONFIG_DIR"

# Only create config if it doesn't exist to preserve existing settings
if [ ! -f "$CONFIG_DIR/config.json" ]; then
cat <<EOF > "$CONFIG_DIR/config.json"
{
  "isDesktopWidgetEnabled" : false,
  "isStartAtLoginEnabled" : ${START_AT_LOGIN},
  "refreshIntervalMinutes" : 30,
  "themeId" : "dark_green",
  "username" : ""
}
EOF
print_success "Default configuration saved to: $CONFIG_DIR/config.json"
else
print_success "Existing configuration kept at: $CONFIG_DIR/config.json"
fi

# Step 7: Configure LaunchAgent if enabled
if [ "$START_AT_LOGIN" = true ]; then
    print_info "Registering LaunchAgent for auto-login..."
    mkdir -p "$LAUNCH_AGENT_DIR"
    
    cat <<EOF > "$LAUNCH_AGENT_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_DEST}/Contents/MacOS/${APP_NAME}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF
    launchctl unload "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    launchctl load "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    print_success "LaunchAgent registered: $LAUNCH_AGENT_PLIST"
fi

# Step 8: Launch Application
print_info "Launching ${APP_NAME}..."
open "$APP_DEST"

printf "\n"
printf "${GREEN}======================================================${NC}\n"
printf "${GREEN}  🎉 GitHub Contribution Widget Installed Successfully! ${NC}\n"
printf "${GREEN}======================================================${NC}\n"
printf "Location:   %s\n" "${APP_DEST}"
printf "Status Bar: Click the GitHub icon in your menu bar and open Settings (⚙️) to enter your GitHub ID!\n\n"
