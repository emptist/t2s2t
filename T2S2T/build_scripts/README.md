# Build Scripts for T2S2T

## Project Structure

The T2S2T Xcode project is located at the **ROOT** of the t2s2t folder:

```
t2s2t/                      <- Open this folder in Xcode
├── T2S2T.xcodeproj/        <- Xcode project file
├── T2S2T/                  <- iOS target source
│   ├── App/
│   ├── Views/
│   ├── build_scripts/      <- This folder
│   └── ...
├── T2S2TMac/               <- macOS target source
├── T2S2TWatch/             <- watchOS target source
└── Shared/                 <- Shared code for all targets
```

## Usage

Run scripts from the `build_scripts` directory:

```bash
cd T2S2T/build_scripts
./build.sh build   # Build the project
./build.sh test    # Run tests
./build.sh archive # Create archive for App Store
./build.sh clean   # Clean build artifacts
./build.sh lint    # Run SwiftLint
```

## Scripts

### build.sh
Main build script that invokes `xcodebuild` with appropriate parameters.
- Uses `../T2S2T.xcodeproj` to reference the Xcode project from this directory.
- Default destination: iPhone 15 Pro simulator
- Default configuration: Release

## Notes

- The scripts assume the Xcode project is at `../T2S2T.xcodeproj` (relative to this folder)
- SwiftLint configuration is at `../.swiftlint.yml`
- All scripts use `set -e` to exit on errors