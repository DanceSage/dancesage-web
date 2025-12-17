import SwiftUI
import Combine

struct SkeletonPlaybackView: View {
    let keypoints: [[[CGPoint]]]
    let allowSave: Bool  // New parameter to control if save button shows
    @State private var currentFrame = 0
    @State private var isPlaying = false
    @State private var showSaveDialog = false
    @State private var recordingName = ""
    @Environment(\.dismiss) var dismiss
    let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !keypoints.isEmpty && currentFrame < keypoints.count {
                SkeletonOverlay(keypoints: keypoints[currentFrame])
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
                
                Text("Frame \(currentFrame + 1) / \(keypoints.count)")
                    .foregroundColor(.white)
                    .padding()
                
                HStack(spacing: 30) {
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        currentFrame = 0
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(timer) { _ in
            if isPlaying {
                currentFrame = (currentFrame + 1) % keypoints.count
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
}
