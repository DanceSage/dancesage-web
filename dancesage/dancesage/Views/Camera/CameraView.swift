import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var poseDetector: PoseDetector
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
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
            print("✅ Camera input added")
        }
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("✅ Video output added")
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        context.coordinator.captureSession = captureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            print("✅ Camera session started")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(poseDetector: poseDetector)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        let poseDetector: PoseDetector
        private var lastTimestamp = 0
        
        init(poseDetector: PoseDetector) {
            self.poseDetector = poseDetector
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            // Fix orientation - rotate image based on device orientation
            let rotatedImage = ciImage.oriented(.right) // Try .right first
            
            guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else { return }
            let image = UIImage(cgImage: cgImage)
            
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            if timestamp - lastTimestamp > 100 {
                poseDetector.detectAsync(image: image, timestamp: timestamp)
                lastTimestamp = timestamp
            }
        }
    }
}
