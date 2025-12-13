import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit
import Combine

class VideoProcessor: ObservableObject {
    @Published var keypoints: [[[CGPoint]]] = [] // Array of frames, each containing array of poses
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    private var poseLandmarker: PoseLandmarker?
    
    init() {
        setupPoseLandmarker()
    }
    
    private func setupPoseLandmarker() {
        let modelPath = Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task")
        
        guard let modelPath = modelPath else {
            print("❌ Model file not found")
            return
        }
        
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video
        options.numPoses = 1
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
            print("✅ VideoProcessor PoseLandmarker initialized")
        } catch {
            print("❌ Error creating PoseLandmarker: \(error)")
        }
    }
    
    func processVideo(url: URL) {
        isProcessing = true
        keypoints = []
        progress = 0.0
        
        let asset = AVAsset(url: url)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("❌ No video track found")
            isProcessing = false
            return
        }
        
        let frameRate = videoTrack.nominalFrameRate
        let duration = asset.duration.seconds
        
        Task {
            await extractFrames(from: asset, frameRate: frameRate, duration: duration)
        }
    }
    
    private func extractFrames(from asset: AVAsset, frameRate: Float, duration: Double) async {
        let generator = AVAssetImageGenerator(asset: asset)
        
        let frameInterval = 1.0 / Double(frameRate)
        var currentTime = 0.0
        var allKeypoints: [[[CGPoint]]] = []
        
        while currentTime < duration {
            let time = CMTime(seconds: currentTime, preferredTimescale: 600)
            
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                let uiImage = UIImage(cgImage: cgImage)
                
                if let frameKeypoints = detectPose(in: uiImage, timestamp: Int(currentTime * 1000)) {
                    allKeypoints.append(frameKeypoints)
                }
            }
            
            currentTime += frameInterval
            
            await MainActor.run {
                self.progress = currentTime / duration
            }
        }
        
        DispatchQueue.main.async {
            self.keypoints = allKeypoints
            self.isProcessing = false
            print("✅ Processed \(allKeypoints.count) frames")
        }
    }
    
    private func detectPose(in image: UIImage, timestamp: Int) -> [[CGPoint]]? {
        guard let poseLandmarker = poseLandmarker else { return nil }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            print("❌ Failed to convert UIImage to MPImage")
            return nil
        }
        
        do {
            let result = try poseLandmarker.detect(videoFrame: mpImage, timestampInMilliseconds: timestamp)
            
            guard let firstPose = result.landmarks.first else { return nil }
            
            let points = firstPose.map { landmark in
                CGPoint(x: CGFloat(landmark.x), y: CGFloat(landmark.y))
            }
            
            return [points]
        } catch {
            print("❌ Detection error: \(error)")
            return nil
        }
    }
}
