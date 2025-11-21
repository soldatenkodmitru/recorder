import SwiftUI

struct WaveformView: View {
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 20)
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4)
                    .frame(height: amplitudes[index] * 60)
                    .animation(.easeInOut(duration: 0.1), value: amplitudes[index])
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                updateAmplitudes()
            }
        }
    }
    
    private func updateAmplitudes() {
        for index in amplitudes.indices {
            amplitudes[index] = CGFloat.random(in: 0.2...1.0)
        }
    }
}
