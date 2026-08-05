import Foundation
import CoreGraphics

public struct LayoutDiffItem: Identifiable, Codable, Sendable, Equatable {
    public enum IssueCategory: String, Codable, Sendable, CaseIterable {
        case spacing = "Spacing & Padding"
        case dimension = "Dimensions"
        case typography = "Typography"
        case missingElement = "Missing / Added Element"
        case colorMismatch = "Color Mismatch"
    }
    
    public enum Severity: String, Codable, Sendable, Comparable {
        case info = "Info"
        case warning = "Warning"
        case critical = "Critical"
        
        private var rank: Int {
            switch self {
            case .info: return 1
            case .warning: return 2
            case .critical: return 3
            }
        }
        
        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rank < rhs.rank
        }
    }
    
    public let id: UUID
    public let category: IssueCategory
    public let severity: Severity
    public let title: String
    public let issueDescription: String
    public let elementName: String
    public let referenceValue: String
    public let actualValue: String
    public let delta: Double?
    public let unit: String
    public let boundingBox: CGRect
    public let actualBoundingBox: CGRect?
    
    public init(
        id: UUID = UUID(),
        category: IssueCategory,
        severity: Severity,
        title: String,
        issueDescription: String,
        elementName: String,
        referenceValue: String,
        actualValue: String,
        delta: Double? = nil,
        unit: String = "px",
        boundingBox: CGRect,
        actualBoundingBox: CGRect? = nil
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.title = title
        self.issueDescription = issueDescription
        self.elementName = elementName
        self.referenceValue = referenceValue
        self.actualValue = actualValue
        self.delta = delta
        self.unit = unit
        self.boundingBox = boundingBox
        self.actualBoundingBox = actualBoundingBox
    }
}
