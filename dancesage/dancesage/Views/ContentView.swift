import SwiftUI

struct ContentView: View {
    @StateObject private var poseDetector = PoseDetector()
    
    var body: some View {
        ZStack {
            CameraView(poseDetector: poseDetector)
                .ignoresSafeArea()
            
            // Draw skeleton overlay
            SkeletonOverlay(keypoints: poseDetector.keypoints)
                .ignoresSafeArea()
        }
    }
}
