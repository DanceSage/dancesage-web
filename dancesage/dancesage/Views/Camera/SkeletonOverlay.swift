import SwiftUI

struct SkeletonOverlay: View {
    let keypoints: [[CGPoint]]
    var useVisionIndices: Bool = false  // Not used anymore - both use same 17-point format
    
    // Colors for different people - Person 1: Green, Person 2: Red
    private let personColors: [Color] = [.green, .red]
    
    // 17-point format (same for both MediaPipe and Vision now):
    // 0: nose, 1: left eye, 2: right eye, 3: left ear, 4: right ear
    // 5: left shoulder, 6: right shoulder, 7: left elbow, 8: right elbow
    // 9: left wrist, 10: right wrist, 11: left hip, 12: right hip
    // 13: left knee, 14: right knee, 15: left ankle, 16: right ankle
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw ALL detected people
                for (personIndex, personKeypoints) in keypoints.enumerated() {
                    let color = personColors[personIndex % personColors.count]
                    
                    // Draw keypoints (skip invalid points and ears)
                    // Show: nose (0), eyes (1,2), and body (5+)
                    let pointsToShow: Set<Int> = [0, 1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
                    
                    for (index, point) in personKeypoints.enumerated() {
                        guard point.x >= 0 && point.y >= 0 else { continue }
                        guard pointsToShow.contains(index) else { continue }
                        
                        let scaledPoint = CGPoint(
                            x: point.x * size.width,
                            y: point.y * size.height
                        )
                        
                        context.fill(
                            Circle().path(in: CGRect(x: scaledPoint.x - 8, y: scaledPoint.y - 8, width: 16, height: 16)),
                            with: .color(color)
                        )
                    }
                    
                    drawSkeleton(context: context, keypoints: personKeypoints, size: size, color: color)
                }
            }
        }
    }
    
    private func drawSkeleton(context: GraphicsContext, keypoints: [CGPoint], size: CGSize, color: Color) {
        // Universal 17-point connections (works for both MediaPipe and Vision now)
        let connections: [(Int, Int)] = [
            (5, 6),   // shoulders
            (5, 11), (6, 12),  // torso sides
            (11, 12), // hips
            (5, 7), (7, 9),    // left arm
            (6, 8), (8, 10),   // right arm
            (11, 13), (13, 15), // left leg
            (12, 14), (14, 16), // right leg
        ]
        
        for (start, end) in connections {
            guard start < keypoints.count, end < keypoints.count else { continue }
            
            let startKp = keypoints[start]
            let endKp = keypoints[end]
            
            // Skip if either point is invalid
            guard startKp.x >= 0 && startKp.y >= 0 && endKp.x >= 0 && endKp.y >= 0 else { continue }
            
            let startPoint = CGPoint(
                x: startKp.x * size.width,
                y: startKp.y * size.height
            )
            let endPoint = CGPoint(
                x: endKp.x * size.width,
                y: endKp.y * size.height
            )
            
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            context.stroke(path, with: .color(color), lineWidth: 3)
        }
    }
}
