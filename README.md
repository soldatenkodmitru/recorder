# Audio Recorder for macOS

A modern, native macOS application for recording, managing, and playing back audio recordings with a clean SwiftUI interface.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue)

## Features

- 🎙️ **High-Quality Audio Recording** - Records in AAC format at 44.1kHz
- 🎵 **Real-Time Waveform Visualization** - Animated waveform display during recording
- ⏱️ **Live Duration Tracking** - Real-time recording duration display
- 🔍 **Smart Search** - Quickly find recordings by name
- ▶️ **Built-in Playback** - Play recordings directly within the app
- 💾 **Export Functionality** - Export recordings to any location
- 🎨 **Modern macOS UI** - Clean, native SwiftUI interface with hover states and context menus

## Requirements

### System Requirements
- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

### Hardware Requirements
- Mac with built-in microphone or external microphone/audio interface
- Sufficient disk space for audio recordings (approximately 1 MB per minute of recording)

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd AudioRecorder
```

### 2. Open in Xcode
```bash
open AudioRecorder.xcodeproj
```

### 3. Configure Code Signing
1. Select the project in Xcode's navigator
2. Select the app target
3. Go to "Signing & Capabilities"
4. Select your development team

### 4. Add Required Entitlements
The app requires the following capabilities:

**App Sandbox** (for macOS App Store distribution):
- Enable "App Sandbox"
- Enable "Audio Input" (Microphone access)
- Enable "User Selected Files" (Read/Write for export functionality)

To add these in Xcode:
1. Select your target → "Signing & Capabilities"
2. Click "+ Capability" → "App Sandbox"
3. Under "App Sandbox", check:
   - ✓ Audio Input
   - ✓ User Selected File (Read/Write)

### 5. Add Privacy Description
Add the following key to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to record audio.</string>
```

Or in Xcode:
1. Open `Info.plist`
2. Add a new row
3. Key: "Privacy - Microphone Usage Description"
4. Value: "This app needs access to your microphone to record audio."

### 6. Build and Run
Press `⌘R` to build and run the application.

## Architecture Overview

The application follows a clean MVVM (Model-View-ViewModel) architecture with SwiftUI:

### Core Components

```
AudioRecorder (macOS App)
├── Models
│   └── Recording.swift          # Data model for individual recordings
├── ViewModels
│   └── AudioRecorder.swift      # Main business logic & state management
└── Views
    ├── ContentView.swift        # Main app interface
    ├── RecordingRow.swift       # Individual recording list item
    └── WaveformView.swift       # Animated waveform visualization
```

### Component Responsibilities

#### **Models**
- **Recording**: Represents a single audio recording with metadata (duration, date, file size, etc.)

#### **ViewModels**
- **AudioRecorder**: 
  - Manages recording state using `AVAudioEngine`
  - Handles microphone permissions via `AVCaptureDevice`
  - Controls playback using `AVAudioPlayer`
  - Persists recording metadata to `UserDefaults`
  - Provides formatted strings for UI display

#### **Views**
- **ContentView**: Main application interface with:
  - Header with app title and recording count
  - Searchable recordings list
  - Recording controls panel
  - Permission handling UI
  - Error banner display

- **RecordingRow**: Individual recording list item with:
  - Play/pause controls
  - Recording metadata display
  - Hover interactions
  - Export and delete actions
  - Context menu support

- **WaveformView**: Animated visualization showing:
  - Real-time amplitude bars during recording
  - Smooth animations using SwiftUI's animation system
  - Task-based continuous updates

## Design Decisions & Trade-offs

### 1. **AVAudioEngine vs AVAudioRecorder**
**Chose**: `AVAudioEngine`

**Reasoning**: 
- Provides real-time access to audio buffers for waveform visualization
- More flexible for future enhancements (e.g., audio effects, level meters)
- Modern API that aligns with Apple's current best practices

**Trade-off**: Slightly more complex setup compared to `AVAudioRecorder`

### 2. **File Format: AAC (M4A)**
**Chose**: MPEG-4 AAC at 44.1kHz, mono, high quality

**Reasoning**:
- Excellent compression ratio (smaller file sizes)
- High audio quality
- Wide compatibility across Apple devices
- Native support in macOS and iOS

**Trade-off**: Not as universally compatible as WAV, but much smaller file sizes

### 3. **Data Persistence: UserDefaults**
**Chose**: `UserDefaults` for metadata, files in Documents directory

**Reasoning**:
- Simple and efficient for small amounts of metadata
- No need for complex database setup
- Metadata is lightweight (URLs, dates, durations)
- Actual audio files stored in Documents directory

**Trade-off**: Not suitable for hundreds/thousands of recordings (consider Core Data or SQLite for scaling)

### 4. **SwiftUI-Only Implementation**
**Chose**: Pure SwiftUI with minimal AppKit bridging

**Reasoning**:
- Modern, declarative UI development
- Easier to maintain and understand
- Native animations and state management
- Future-proof for Apple platform updates

**Trade-off**: Limited to macOS 12.0+ (Monterey), excludes older macOS versions

### 5. **Single Window Design**
**Chose**: Hidden title bar with fixed window resizing

**Reasoning**:
- Clean, modern appearance
- Consistent UI experience
- Optimal layout for the two-panel design

**Trade-off**: Less flexibility for users who prefer custom window sizing

## macOS-Specific Considerations

### Permissions & Privacy

#### **Microphone Access**
The app **requires** microphone access to function:
- Requested at runtime when first needed
- User can grant/deny in System Settings
- App provides UI to guide users to settings if denied
- Permission status checked on app launch

#### **File System Access**
- Recordings stored in app's Documents directory (sandboxed)
- Export uses `NSSavePanel` for user-selected destinations
- No need for additional file system permissions beyond sandbox

### Entitlements

For **development** and **App Store distribution**, enable:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### Sandboxing Implications

The app is **fully sandboxed**, which means:
- ✅ Can access microphone (with permission)
- ✅ Can read/write to its own container
- ✅ Can access user-selected files via `NSSavePanel`
- ❌ Cannot access arbitrary file system locations
- ❌ Cannot access other apps' data


## Known Limitations & Future Improvements

### Current Limitations

1. **Single Recording at a Time**
   - Cannot record while playing back
   - Only one recording session active at a time

2. **No Audio Editing**
   - Cannot trim or edit recordings within the app
   - No waveform scrubbing during playback

3. **Fixed Audio Format**
   - Always records in AAC format
   - No user-configurable quality settings

4. **No Cloud Sync**
   - Recordings only stored locally
   - No iCloud Drive integration

5. **Basic Playback Controls**
   - No seek functionality during playback
   - No playback speed adjustment
   - No volume control within app

### Performance Considerations

- **Memory Usage**: Audio buffers are handled efficiently by AVAudioEngine
- **File Size**: ~1 MB per minute of recording (AAC compression)
- **CPU Usage**: Minimal during recording; timer updates every 0.1 seconds
- **Recommended**: For recordings longer than 1 hour, consider closing other memory-intensive applications

## Project Structure

```
AudioRecorder/
├── AudioRecorderApp.swift       # App entry point
├── Models/
│   └── Recording.swift          # Recording data model
├── ViewModels/
│   └── AudioRecorder.swift      # Core recording logic
├── Views/
│   ├── ContentView.swift        # Main application view
│   ├── RecordingRow.swift       # Recording list item
│   └── WaveformView.swift       # Waveform animation
├── Assets.xcassets/             # App icons and images
├── Info.plist                   # App configuration
└── AudioRecorder.entitlements   # Sandbox & permissions
```

## Troubleshooting

### Microphone Not Working
1. Check System Settings > Privacy & Security > Microphone
2. Ensure your app is listed and enabled
3. Restart the application after granting permission

### No Audio in Recordings
1. Check system sound input in System Settings > Sound
2. Verify correct microphone is selected
3. Test microphone in another app (e.g., Voice Memos)
4. Check input volume level

### Recordings Not Saving
1. Check available disk space
2. Verify app has write permissions
3. Check Console.app for error messages

### Export Fails
1. Ensure destination folder has write permissions
2. Check available disk space at destination
3. Avoid special characters in file names


**Made with ❤️ for macOS**
