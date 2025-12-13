import SwiftUI

struct ContentView: View {
    @StateObject private var poseDetector = PoseDetector()
    @State private var showCamera = false
    @State private var showPlayback = false
    
    var body: some View {
        if showCamera {
            ZStack {
                CameraView(poseDetector: poseDetector)
                    .ignoresSafeArea()
                
                SkeletonOverlay(keypoints: poseDetector.keypoints)
                    .ignoresSafeArea()
                
                VStack {
                    // Back button at top
                    HStack {
                        Button(action: {
                            showCamera = false
                            poseDetector.clearRecording()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Recording controls at bottom
                    HStack(spacing: 30) {
                        // View Recording button
                        if !poseDetector.recordedKeypoints.isEmpty && !poseDetector.isRecording {
                            Button(action: {
                                showPlayback = true
                            }) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // Record button
                        Button(action: {
                            if poseDetector.isRecording {
                                poseDetector.stopRecording()
                            } else {
                                poseDetector.startRecording()
                            }
                        }) {
                            Image(systemName: poseDetector.isRecording ? "stop.circle.fill" : "record.circle")
                                .font(.system(size: 70))
                                .foregroundColor(poseDetector.isRecording ? .red : .white)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                let saved = loadAllRecordings()
                print("📚 Loaded \(saved.count) saved recordings:")
                for recording in saved {
                    print("  - \(recording.name) (\(recording.frameCount) frames)")
                }
            }
            .fullScreenCover(isPresented: $showPlayback) {
                SkeletonPlaybackView(keypoints: poseDetector.recordedKeypoints, allowSave: true)
            }
        } else {
            LandingView(showCamera: $showCamera)
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
