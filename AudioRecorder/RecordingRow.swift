import SwiftUI

struct RecordingRow: View {
    let recording: Recording
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause Button
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isPlaying ? .green : .accentColor)
            }
            .buttonStyle(.plain)
            
            // Recording Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.fileName)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(recording.formattedDate, systemImage: "calendar")
                    Label(recording.formattedDuration, systemImage: "clock")
                    Label(recording.fileSizeString, systemImage: "doc")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons (shown on hover)
            if isHovering {
                HStack(spacing: 8) {
                    Button(action: onExport) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)
                    .help("Export recording")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete recording")
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovering ? Color.accentColor.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Play", systemImage: "play.fill") {
                onPlay()
            }
            
            Divider()
            
            
            Button("Export", systemImage: "square.and.arrow.up") {
                onExport()
            }
            
            Divider()
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }
}
