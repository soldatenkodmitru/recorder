import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordings: [Recording] = []
    @Published var currentRecordingDuration: TimeInterval = 0
    @Published var permissionGranted = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private var timer: Timer?
    
    override init() {
        super.init()
        loadRecordings()
        checkMicrophonePermission()
    }
    
    // MARK: - Permission Handling
    
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        case .denied, .restricted:
            permissionGranted = false
            errorMessage = "Microphone access denied. Please enable it in System Settings > Privacy & Security > Microphone."
        @unknown default:
            permissionGranted = false
        }
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Microphone permission required"
            return
        }
        
        guard !isRecording else { return }
        
        do {
            // Create audio engine
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            inputNode.volume = 1.0
         
            // Create file URL
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let fileName = "Recording_\(timestamp).m4a"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            
            // Setup audio file
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioFile = try AVAudioFile(forWriting: fileURL, settings: settings)
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                try? self?.audioFile?.write(from: buffer)
            }
            
            // Start engine
            try audioEngine.start()
            
            recordingStartTime = Date()
            isRecording = true
            errorMessage = nil
            
            // Start timer for duration updates
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateRecordingDuration()
            }
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        timer?.invalidate()
        timer = nil
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        isRecording = false
        
        if let audioFile = audioFile,
           let startTime = recordingStartTime {
            let duration = Date().timeIntervalSince(startTime)
            let recording = Recording(
                id: UUID(),
                fileURL: audioFile.url,
                date: startTime,
                duration: duration
            )
            recordings.insert(recording, at: 0)
            saveRecordings()
        }
        
        audioFile = nil
        recordingStartTime = nil
        currentRecordingDuration = 0
    }
    
    // MARK: - Playback
    
    private var audioPlayer: AVAudioPlayer?
    @Published var playingRecordingID: UUID?
    
    func playRecording(_ recording: Recording) {
        if playingRecordingID == recording.id {
            stopPlayback()
            return
        }
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            playingRecordingID = recording.id
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingRecordingID = nil
    }
    
    // MARK: - Recording Management
    
    func deleteRecording(_ recording: Recording) {
        if playingRecordingID == recording.id {
            stopPlayback()
        }
        
        try? FileManager.default.removeItem(at: recording.fileURL)
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    // MARK: - Persistence
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveRecordings() {
        let data = recordings.map { recording in
            [
                "id": recording.id.uuidString,
                "path": recording.fileURL.lastPathComponent,
                "date": recording.date.timeIntervalSince1970,
                "duration": recording.duration
            ] as [String: Any]
        }
        UserDefaults.standard.set(data, forKey: "recordings")
    }
    
    private func loadRecordings() {
        guard let data = UserDefaults.standard.array(forKey: "recordings") as? [[String: Any]] else {
            return
        }
        
        let documentsDir = getDocumentsDirectory()
        recordings = data.compactMap { dict in
            guard let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let path = dict["path"] as? String,
                  let dateInterval = dict["date"] as? TimeInterval,
                  let duration = dict["duration"] as? TimeInterval else {
                return nil
            }
            
            let fileURL = documentsDir.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
            }
            
            return Recording(
                id: id,
                fileURL: fileURL,
                date: Date(timeIntervalSince1970: dateInterval),
                duration: duration
            )
        }
    }
    
    private func updateRecordingDuration() {
        if let startTime = recordingStartTime {
            currentRecordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Formatting Helpers
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.playingRecordingID = nil
        }
    }
}
