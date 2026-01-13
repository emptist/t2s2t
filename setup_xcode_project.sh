#!/bin/bash
# T2S2T Xcode Project Setup Script
# This script generates the Xcode project using XcodeGen

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================"
echo "T2S2T Xcode Project Setup"
echo "======================================"
echo ""

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen is not installed."
    echo "Installing XcodeGen via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is not installed. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install xcodegen
fi

echo "Step 1: Generating Xcode project..."
echo "------------------------------------"
xcodegen generate

if [ -d "T2S2T.xcodeproj" ]; then
    echo "✓ Xcode project generated successfully at: T2S2T.xcodeproj"
else
    echo "✗ Error: Xcode project was not generated"
    exit 1
fi

echo ""
echo "Step 2: Verifying project structure..."
echo "----------------------------------------"
REQUIRED_FILES=(
    "T2S2T/App/T2S2TApp.swift"
    "T2S2T/Info.plist"
    "T2S2T/T2S2T.entitlements"
    "Shared/Models/DataController.swift"
    "Shared/Models/UserProfile+CoreData.swift"
    "Shared/Models/Conversation+CoreData.swift"
    "Shared/Models/ProgressEntry+CoreData.swift"
    "Shared/Models/T2S2T.xcdatamodeld/contents"
    "Shared/Services/SpeechService.swift"
    "Shared/Services/LLMService.swift"
    "Shared/Utilities/Configuration.swift"
)

ALL_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ Missing: $file"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo ""
    echo "Warning: Some required files are missing. The project may not build correctly."
fi

echo ""
echo "Step 3: Build Verification"
echo "--------------------------"
echo "To verify the build, run:"
echo "  ./T2S2T/build_scripts/build.sh build"
echo ""
echo "Or build manually:"
echo "  xcodebuild -project T2S2T.xcodeproj -scheme T2S2T -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build"

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Open T2S2T.xcodeproj in Xcode"
echo "2. Configure signing certificates for each target"
echo "3. Set your Apple Developer Team in Xcode preferences"
echo "4. Build and run the project"
echo ""
echo "For LLM functionality, set environment variables:"
echo "  export OPENAI_API_KEY='your-api-key'"
echo "  export ANTHROPIC_API_KEY='your-api-key'"
echo ""