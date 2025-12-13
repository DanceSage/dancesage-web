import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit
import Combine

class VideoProcessor: ObservableObject {
    @Published var keypoints: [[[CGPoint]]] = []
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    private var videoTransform: CGAffineTransform = .identity
    
    func processVideo(url: URL) {
        print("🎬 STARTING NEW VIDEO PROCESSING")

        isProcessing = true
        keypoints = []
        progress = 0.0
        
        let asset = AVURLAsset(url: url)
        
        Task {
            do {
                guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    print("❌ No video track found")
                    await MainActor.run { self.isProcessing = false }
                    return
                }
                
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                let duration = try await asset.load(.duration).seconds
                let transform = try await videoTrack.load(.preferredTransform)
                
                videoTransform = transform
                
                print("🎬 Video duration: \(duration) seconds, frame rate: \(frameRate) fps")
                print("🎬 Video transform: \(transform)")
                print("🎬 Expected frames: ~\(Int(duration * Double(frameRate)))")
                
                await extractFrames(from: asset, frameRate: frameRate, duration: duration)
            } catch {
                print("❌ Error loading video: \(error)")
                await MainActor.run { self.isProcessing = false }
            }
        }
    }
    
    private func extractFrames(from asset: AVAsset, frameRate: Float, duration: Double) async {
        guard let poseLandmarker = createPoseLandmarker() else {
            await MainActor.run { self.isProcessing = false }
            return
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true  // Apply rotation to extracted images
        
        let frameInterval = 1.0 / Double(frameRate)
        var currentTime = 0.0
        var allKeypoints: [[[CGPoint]]] = []
        var timestampMs = 0
        var frameCount = 0
        
        while currentTime < duration {
            let time = CMTime(seconds: currentTime, preferredTimescale: 600)
            
            do {
                let (cgImage, _) = try await generator.image(at: time)
                let uiImage = UIImage(cgImage: cgImage)
                frameCount += 1
                
                if frameCount % 30 == 0 {
                    print("🖼️ Frame \(frameCount): size=\(uiImage.size.width)x\(uiImage.size.height)")
                }
                
                if let frameKeypoints = detectPose(in: uiImage, timestamp: timestampMs, using: poseLandmarker) {
                    allKeypoints.append(frameKeypoints)
                    
                    if let nose = frameKeypoints.first?.first, let ankle = frameKeypoints.first?.last {
                        if frameCount % 30 == 0 {
                            print("✅ Frame \(frameCount) - Nose: (\(String(format: "%.3f", nose.x)), \(String(format: "%.3f", nose.y))), Ankle: (\(String(format: "%.3f", ankle.x)), \(String(format: "%.3f", ankle.y)))")
                        }
                    }
                }
                
                timestampMs += Int(frameInterval * 1000)
            } catch {
                print("❌ Frame extraction error: \(error)")
            }
            
            currentTime += frameInterval
            
            await MainActor.run {
                self.progress = min(currentTime / duration, 1.0)
            }
        }
        
        await MainActor.run {
            self.keypoints = allKeypoints
            self.isProcessing = false
            print("✅ Processed \(frameCount) frames total, detected poses in \(allKeypoints.count) frames")
        }
    }
    
    private func createPoseLandmarker() -> PoseLandmarker? {
        let modelPath = Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task")
        
        guard let modelPath = modelPath else {
            print("❌ Model file not found")
            return nil
        }
        
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video
        options.numPoses = 1
        
        do {
            let landmarker = try PoseLandmarker(options: options)
            print("✅ PoseLandmarker initialized")
            return landmarker
        } catch {
            print("❌ Error creating PoseLandmarker: \(error)")
            return nil
        }
    }
    
    private func detectPose(in image: UIImage, timestamp: Int, using poseLandmarker: PoseLandmarker) -> [[CGPoint]]? {
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
