import Foundation
import CoreGraphics

public struct DiffResult: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let referenceImageSize: CGSize
    public let actualImageSize: CGSize
    public let diffItems: [LayoutDiffItem]
    public let matchPercentage: Double
    public let totalBlocksDetected: Int
    
    public var totalIssuesCount: Int {
        diffItems.count
    }
    
    public var criticalCount: Int {
        diffItems.filter { $0.severity == .critical }.count
    }
    
    public var warningCount: Int {
        diffItems.filter { $0.severity == .warning }.count
    }
    
    public var infoCount: Int {
        diffItems.filter { $0.severity == .info }.count
    }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        referenceImageSize: CGSize,
        actualImageSize: CGSize,
        diffItems: [LayoutDiffItem],
        matchPercentage: Double,
        totalBlocksDetected: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.referenceImageSize = referenceImageSize
        self.actualImageSize = actualImageSize
        self.diffItems = diffItems
        self.matchPercentage = matchPercentage
        self.totalBlocksDetected = totalBlocksDetected
    }
}
