import SwiftUI

struct ContentView: View {
    @StateObject private var poseDetector = PoseDetector()
    @State private var showCamera = false
    
    var body: some View {
        if showCamera {
            ZStack {
                CameraView(poseDetector: poseDetector)
                    .ignoresSafeArea()
                
                SkeletonOverlay(keypoints: poseDetector.keypoints)
                    .ignoresSafeArea()
            }
        } else {
            LandingView(showCamera: $showCamera)
        }
    }
}
