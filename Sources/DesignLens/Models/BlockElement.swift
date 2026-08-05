import Foundation
import CoreGraphics

public struct BlockElement: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let label: String
    public let boundingBox: CGRect
    public let extractedText: String?
    public let fontSize: Double?
    public let fontWeight: String?
    public let dominantColorHex: String?
    public let children: [BlockElement]
    
    public init(
        id: UUID = UUID(),
        label: String,
        boundingBox: CGRect,
        extractedText: String? = nil,
        fontSize: Double? = nil,
        fontWeight: String? = nil,
        dominantColorHex: String? = nil,
        children: [BlockElement] = []
    ) {
        self.id = id
        self.label = label
        self.boundingBox = boundingBox
        self.extractedText = extractedText
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.dominantColorHex = dominantColorHex
        self.children = children
    }
}
