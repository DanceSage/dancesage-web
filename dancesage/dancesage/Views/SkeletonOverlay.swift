import SwiftUI

struct SkeletonOverlay: View {
    let keypoints: [[CGPoint]]
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let firstPerson = keypoints.first else { return }
                
                // Draw circles for each keypoint (mirrored)
                for (index, point) in firstPerson.enumerated() {
                    let scaledPoint = CGPoint(
                        x: (1.0 - point.x) * size.width,  // ← Flip horizontally
                        y: point.y * size.height
                    )
                    
                    if index < 17 {
                        context.fill(
                            Circle().path(in: CGRect(x: scaledPoint.x - 8, y: scaledPoint.y - 8, width: 16, height: 16)),
                            with: .color(.green)
                        )
                    }
                }
                
                drawSkeleton(context: context, keypoints: firstPerson, size: size)
            }
        }
    }
    
    private func drawSkeleton(context: GraphicsContext, keypoints: [CGPoint], size: CGSize) {
        let connections: [(Int, Int)] = [
            (11, 12), (11, 23), (12, 24), (23, 24),
            (11, 13), (13, 15),
            (12, 14), (14, 16),
            (23, 25), (25, 27), (27, 29),
            (24, 26), (26, 28), (28, 30)
        ]
        
        for (start, end) in connections {
            guard start < keypoints.count, end < keypoints.count else { continue }
            
            let startPoint = CGPoint(
                x: (1.0 - keypoints[start].x) * size.width,  // ← Flip horizontally
                y: keypoints[start].y * size.height
            )
            let endPoint = CGPoint(
                x: (1.0 - keypoints[end].x) * size.width,  // ← Flip horizontally
                y: keypoints[end].y * size.height
            )
            
            var path = Path()
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            context.stroke(path, with: .color(.green), lineWidth: 3)
        }
    }
}
