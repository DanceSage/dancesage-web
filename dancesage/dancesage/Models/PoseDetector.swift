import Foundation
import Combine
import MediaPipeTasksVision
import UIKit

class PoseDetector: NSObject, ObservableObject {
    @Published var keypoints: [[CGPoint]] = []
    @Published var recordedKeypoints: [[[CGPoint]]] = []
    @Published var isRecording = false
    
    private var poseLandmarker: PoseLandmarker?
    
    override init() {
        super.init()
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
        options.runningMode = .liveStream
        options.numPoses = 1
        options.poseLandmarkerLiveStreamDelegate = self
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
            print("✅ PoseLandmarker initialized")
        } catch {
            print("❌ Error creating PoseLandmarker: \(error)")
        }
    }
    
    func detectAsync(image: UIImage, timestamp: Int) {
        guard let poseLandmarker = poseLandmarker else { return }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            print("❌ Failed to convert UIImage to MPImage")
            return
        }
        
        do {
            try poseLandmarker.detectAsync(image: mpImage, timestampInMilliseconds: timestamp)
        } catch {
            print("❌ Detection async error: \(error)")
        }
    }
    
    // Recording controls
    func startRecording() {
        recordedKeypoints = []
        isRecording = true
        print("🔴 Recording started")
    }
    
    func stopRecording() {
        isRecording = false
        print("⏹️ Recording stopped - captured \(recordedKeypoints.count) frames")
    }
    
    func clearRecording() {
        recordedKeypoints = []
        print("🗑️ Recording cleared")
    }
}

// MARK: - PoseLandmarkerLiveStreamDelegate
extension PoseDetector: PoseLandmarkerLiveStreamDelegate {
    func poseLandmarker(_ poseLandmarker: PoseLandmarker,
                       didFinishDetection result: PoseLandmarkerResult?,
                       timestampInMilliseconds: Int,
                       error: Error?) {
        
        if let error = error {
            print("❌ Detection error: \(error)")
            return
        }
        
        guard let result = result, let firstPose = result.landmarks.first else {
            DispatchQueue.main.async {
                self.keypoints = []
            }
            return
        }
        
        // Convert landmarks to CGPoints
        let points = firstPose.map { landmark in
            CGPoint(x: CGFloat(landmark.x), y: CGFloat(landmark.y))
        }
        
        DispatchQueue.main.async {
            self.keypoints = [points]
            
            // If recording, save this frame
            if self.isRecording {
                self.recordedKeypoints.append([points])
            }
        }
    }
}
