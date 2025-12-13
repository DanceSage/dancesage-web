import Foundation

struct DanceRecording: Codable, Identifiable {
    let id: String
    let name: String
    let keypoints: [[[CGPoint]]]
    let timestamp: Date
    let frameCount: Int
    
    init(name: String, keypoints: [[[CGPoint]]]) {
        self.id = UUID().uuidString
        self.name = name
        self.keypoints = keypoints
        self.timestamp = Date()
        self.frameCount = keypoints.count
    }
}

// Make CGPoint Codable
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
