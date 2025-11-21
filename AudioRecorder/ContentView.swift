import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var searchText = ""
    @State private var selectedRecording: Recording?
    @State private var newRecordingName = ""
    
    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return audioRecorder.recordings
        }
        return audioRecorder.recordings.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main Content
            if !audioRecorder.permissionGranted {
                permissionDeniedView
            } else {
                HStack(spacing: 0) {
                    // Recordings List
                    recordingsListView
                    
                    Divider()
                    
                    // Recording Controls
                    recordingControlsView
                        .frame(width: 250)
                }
            }
            
            // Error Alert
            if let errorMessage = audioRecorder.errorMessage {
                errorBanner(message: errorMessage)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text("Audio Recorder")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(audioRecorder.recordings.count) recording\(audioRecorder.recordings.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Permission Denied View
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Microphone Access Required")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("This app needs microphone access to record audio.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Check Permission Again") {
                audioRecorder.checkMicrophonePermission()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Recordings List View
    
    private var recordingsListView: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search recordings...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Recordings List
            if filteredRecordings.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredRecordings) { recording in
                            RecordingRow(
                                recording: recording,
                                isPlaying: audioRecorder.playingRecordingID == recording.id,
                                onPlay: { audioRecorder.playRecording(recording) },
                                onDelete: { audioRecorder.deleteRecording(recording) },
                                onExport: { exportRecording(recording) }
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "music.note.list" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Recordings Yet" : "No Results")
                .font(.title3)
                .fontWeight(.medium)
            
            Text(searchText.isEmpty ? "Start recording to create your first audio file" : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Recording Controls View
    
    private var recordingControlsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Waveform Animation
            if audioRecorder.isRecording {
                WaveformView()
                    .frame(height: 80)
                    .padding(.horizontal)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.3))
                    .frame(height: 80)
            }
            
            // Recording Duration
            Text(audioRecorder.formatDuration(audioRecorder.currentRecordingDuration))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(audioRecorder.isRecording ? .red : .secondary)
            
            // Record Button
            Button(action: {
                if audioRecorder.isRecording {
                    audioRecorder.stopRecording()
                } else {
                    audioRecorder.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(audioRecorder.isRecording ? Color.red : Color.accentColor)
                        .frame(width: 80, height: 80)
                    
                    if audioRecorder.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            
            Text(audioRecorder.isRecording ? "Tap to stop" : "Tap to record")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
            
            Spacer()
            
            Button("Dismiss") {
                audioRecorder.errorMessage = nil
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }
    
    
    // MARK: - Helper Functions
    
    private func exportRecording(_ recording: Recording) {
        let panel = NSSavePanel()
        
        // Add file extension if not present
        let fileExtension = recording.fileURL.pathExtension
        if !recording.fileName.hasSuffix(".\(fileExtension)") {
            panel.nameFieldStringValue = "\(recording.fileName).\(fileExtension)"
        } else {
            panel.nameFieldStringValue = recording.fileName
        }
        
        panel.allowedContentTypes = [.audio]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? FileManager.default.copyItem(at: recording.fileURL, to: url)
            }
        }
    }
}
