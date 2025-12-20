import SwiftUI

struct VideoProcessingView: View {
    @StateObject private var videoProcessor = VideoProcessor()
    let videoURL: URL
    @Environment(\.dismiss) var dismiss
    @State private var showPlayback = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Processing Video")
                .font(.title)
                .bold()
            
            if videoProcessor.isProcessing {
                ProgressView(value: videoProcessor.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)
                
                Text("\(Int(videoProcessor.progress * 100))%")
                    .font(.headline)
            } else if !videoProcessor.keypoints.isEmpty {
                Text("✅ Processing Complete!")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Detected \(videoProcessor.keypoints.count) frames")
                    .font(.subheadline)
                
                Button("View Skeleton") {
                    showPlayback = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            } else {
                // Processing finished but no poses detected
                Text("⚠️ No poses detected")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text("Try a video with a person clearly visible")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onAppear {
            videoProcessor.processVideo(url: videoURL)
        }
        .fullScreenCover(isPresented: $showPlayback) {
            SkeletonPlaybackView(keypoints: videoProcessor.keypoints, allowSave: true)
        }
    }
}
