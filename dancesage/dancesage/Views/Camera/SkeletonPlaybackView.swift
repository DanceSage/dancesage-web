import SwiftUI
import Combine

struct SkeletonPlaybackView: View {
    let keypoints: [[[CGPoint]]]  // All frames of keypoints
    @State private var currentFrame = 0
    @State private var isPlaying = false
    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect() // ~25fps
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !keypoints.isEmpty && currentFrame < keypoints.count {
                SkeletonOverlay(keypoints: keypoints[currentFrame])
            }
            
            VStack {
                Spacer()
                
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
    }
}
