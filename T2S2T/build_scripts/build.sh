#!/bin/bash
# Build script for T2S2T project
# Usage: ./T2S2T/build_scripts/build.sh [command]
# Commands: build, test, archive, clean, lint

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

PROJECT_NAME="T2S2T"
SCHEME="T2S2T"
CONFIGURATION="Release"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
PROJECT_PATH="$ROOT_DIR/T2S2T.xcodeproj"

case "$1" in
    build)
        echo "Building $PROJECT_NAME..."
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -destination "$DESTINATION" \
            build
        ;;
    test)
        echo "Running tests..."
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            test
        ;;
    archive)
        echo "Creating archive..."
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -configuration "$CONFIGURATION" \
            -destination "generic/platform=iOS" \
            -archivePath "build/$PROJECT_NAME.xcarchive" \
            archive
        ;;
    clean)
        echo "Cleaning build artifacts..."
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            clean
        rm -rf build
        ;;
    lint)
        echo "Running SwiftLint..."
        if which swiftlint >/dev/null; then
            swiftlint --config ../../.swiftlint.yml
        else
            echo "SwiftLint not installed. Installing via Homebrew..."
            brew install swiftlint
            swiftlint --config ../../.swiftlint.yml
        fi
        ;;
    *)
        echo "Usage: $0 {build|test|archive|clean|lint}"
        exit 1
        ;;
esac