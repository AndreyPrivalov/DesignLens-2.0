import XCTest
@testable import DesignLens

final class DesignSystemConfigTests: XCTestCase {
    
    func testDefaultConfigLoading() {
        let config = DesignSystemConfig.loadDefault()
        XCTAssertFalse(config.name.isEmpty)
        XCTAssertEqual(config.colors.primaryAccent, "#2B7FFF")
        XCTAssertEqual(config.colors.secondaryAccent, "#A855F7")
        XCTAssertFalse(config.typography.isEmpty)
        XCTAssertTrue(config.spacingTokens.contains(16.0))
    }
    
    func testFallbackConfig() {
        let config = DesignSystemConfig.fallbackDefault
        XCTAssertEqual(config.name, "Default Fallback System")
        XCTAssertEqual(config.tolerances.spacingPx, 2.0)
        XCTAssertEqual(config.tolerances.dimensionPx, 2.0)
    }
    
    func testModelCodableConformances() throws {
        let block = BlockElement(
            label: "Header Button",
            boundingBox: CGRect(x: 10, y: 20, width: 100, height: 40),
            extractedText: "Submit",
            fontSize: 14.0,
            fontWeight: "Bold",
            dominantColorHex: "#2B7FFF"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(block)
        let decodedBlock = try decoder.decode(BlockElement.self, from: data)
        XCTAssertEqual(block.label, decodedBlock.label)
        XCTAssertEqual(block.extractedText, decodedBlock.extractedText)
        
        let diffItem = LayoutDiffItem(
            category: .spacing,
            severity: .warning,
            title: "Top Padding Delta",
            issueDescription: "Expected 16px padding, got 24px",
            elementName: "Submit Button",
            referenceValue: "16px",
            actualValue: "24px",
            delta: 8.0,
            unit: "px",
            boundingBox: CGRect(x: 10, y: 20, width: 100, height: 40)
        )
        
        let diffData = try encoder.encode(diffItem)
        let decodedDiffItem = try decoder.decode(LayoutDiffItem.self, from: diffData)
        XCTAssertEqual(diffItem.title, decodedDiffItem.title)
        XCTAssertEqual(diffItem.severity, decodedDiffItem.severity)
        
        let result = DiffResult(
            referenceImageSize: CGSize(width: 1920, height: 1080),
            actualImageSize: CGSize(width: 1920, height: 1080),
            diffItems: [diffItem],
            matchPercentage: 92.5,
            totalBlocksDetected: 15
        )
        
        let resultData = try encoder.encode(result)
        let decodedResult = try decoder.decode(DiffResult.self, from: resultData)
        XCTAssertEqual(decodedResult.totalIssuesCount, 1)
        XCTAssertEqual(decodedResult.warningCount, 1)
        XCTAssertEqual(decodedResult.criticalCount, 0)
        XCTAssertEqual(decodedResult.matchPercentage, 92.5)
    }
}
