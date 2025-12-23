import SwiftUI
import Combine
import AVFoundation

struct SkeletonPlaybackView: View {
    let keypoints: [[[CGPoint]]]
    let allowSave: Bool  // New parameter to control if save button shows
    var useVisionIndices: Bool = false  // For Vision vs MediaPipe joint mapping
    var beats: [Double] = []  // Beat timestamps in seconds
    var bpm: Double = 0
    var fps: Double = 15  // Frames per second (matches VideoProcessor targetFPS)
    var videoURL: URL? = nil  // Optional video URL for audio playback
    
    @State private var currentFrame = 0
    @State private var isPlaying = false
    @State private var showSaveDialog = false
    @State private var recordingName = ""
    @State private var currentBeat = 0  // Which beat in the 8-count (1-8)
    @State private var beatFlash = false  // For visual pulse on beat
    @State private var audioPlayer: AVPlayer? = nil
    @Environment(\.dismiss) var dismiss
    let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()
    
    // Calculate current time from frame number
    var currentTime: Double {
        Double(currentFrame) / fps
    }
    
    // Find which beat we're on (1-8 in the salsa count)
    var beatNumber: Int {
        guard !beats.isEmpty else { return 0 }
        
        // Find how many beats have passed
        let beatsPasssed = beats.filter { $0 <= currentTime }.count
        
        // Salsa counts 1-8, then repeats
        return beatsPasssed > 0 ? ((beatsPasssed - 1) % 8) + 1 : 0
    }
    
    // Check if we just hit a beat
    var isOnBeat: Bool {
        guard !beats.isEmpty else { return false }
        
        let tolerance = 0.05  // 50ms tolerance
        return beats.contains { abs($0 - currentTime) < tolerance }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !keypoints.isEmpty && currentFrame < keypoints.count {
                SkeletonOverlay(keypoints: keypoints[currentFrame], useVisionIndices: useVisionIndices)
            }
            
            VStack {
                // Top buttons
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Beat counter display
                    if !beats.isEmpty {
                        VStack(spacing: 4) {
                            Text("Beat")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(beatNumber)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(beatFlash ? .yellow : .white)
                            if bpm > 0 {
                                Text("\(Int(bpm)) BPM")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Save button (only show if allowSave is true)
                    if allowSave {
                        Button(action: {
                            showSaveDialog = true
                        }) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                }
                
                Spacer()
                
                // 8-count visual indicator
                if !beats.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(1...8, id: \.self) { beat in
                            Circle()
                                .fill(beat == beatNumber ? Color.yellow : Color.gray.opacity(0.5))
                                .frame(width: beat == beatNumber ? 20 : 12, height: beat == beatNumber ? 20 : 12)
                                .animation(.easeInOut(duration: 0.1), value: beatNumber)
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                Text("Frame \(currentFrame + 1) / \(keypoints.count)")
                    .foregroundColor(.white)
                Text(String(format: "%.2fs", currentTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
                
                HStack(spacing: 30) {
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        resetPlayback()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            audioPlayer?.pause()
            audioPlayer = nil
        }
        .onReceive(timer) { _ in
            if isPlaying {
                currentFrame = (currentFrame + 1) % keypoints.count
                
                // Loop back to start
                if currentFrame == 0 {
                    resetPlayback()
                    return
                }
            }
        }
        .alert("Save Recording", isPresented: $showSaveDialog) {
            TextField("Dance name", text: $recordingName)
            Button("Save") {
                saveRecording()
            }
            Button("Cancel", role: .cancel) {
                recordingName = ""
            }
        } message: {
            Text("Enter a name for this dance recording")
        }
    }
    
    func saveRecording() {
        guard !recordingName.isEmpty else { return }
        
        let recording = DanceRecording(name: recordingName, keypoints: keypoints)
        
        do {
            var savedRecordings = loadAllRecordings()
            savedRecordings.append(recording)
            
            let allData = try JSONEncoder().encode(savedRecordings)
            UserDefaults.standard.set(allData, forKey: "savedDances")
            
            print("✅ Saved recording: \(recordingName)")
            recordingName = ""
            dismiss()  // Close playback after saving
            
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }
    
    func loadAllRecordings() -> [DanceRecording] {
        guard let data = UserDefaults.standard.data(forKey: "savedDances"),
              let recordings = try? JSONDecoder().decode([DanceRecording].self, from: data) else {
            return []
        }
        return recordings
    }
    
    // MARK: - Audio Playback
    
    func setupAudioPlayer() {
        guard let url = videoURL else {
            print("⚠️ No video URL for audio playback")
            return
        }
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 Audio session configured")
        } catch {
            print("❌ Audio session error: \(error)")
        }
        
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.volume = 1.0
        print("🔊 Audio player ready for: \(url.lastPathComponent)")
    }
    
    func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            // Sync audio to current frame position
            let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            audioPlayer?.seek(to: targetTime) { _ in
                self.audioPlayer?.play()
            }
        } else {
            audioPlayer?.pause()
        }
    }
    
    func resetPlayback() {
        isPlaying = false
        currentFrame = 0
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
    }
}
