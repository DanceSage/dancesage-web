import SwiftUI
import AVFoundation
import Vision

struct VisionCameraView: UIViewRepresentable {
    @ObservedObject var visionDetector: VisionPoseDetector
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium  // Lower resolution for faster processing
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Camera not found")
            return view
        }
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ Cannot create camera input")
            return view
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            print("✅ Vision Camera input added")
        }
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "visionVideoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("✅ Vision Video output added")
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        context.coordinator.captureSession = captureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            print("✅ Vision Camera session started")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(visionDetector: visionDetector)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        let visionDetector: VisionPoseDetector
        private var lastTimestamp = 0
        
        init(visionDetector: VisionPoseDetector) {
            self.visionDetector = visionDetector
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            // Process every 50ms (~20fps) for good multi-person tracking
            if timestamp - lastTimestamp > 50 {
                // Use pixel buffer directly with proper orientation for accurate coordinates
                visionDetector.detectPoses(in: pixelBuffer, orientation: .right)
                lastTimestamp = timestamp
            }
        }
    }
}

