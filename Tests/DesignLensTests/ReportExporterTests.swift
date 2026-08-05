import Testing
import Foundation
import CoreGraphics
@testable import DesignLens

@Suite("Report Exporter Tests")
struct ReportExporterTests {
    
    private func createTestDiffResult() -> DiffResult {
        let item1 = LayoutDiffItem(
            category: .spacing,
            severity: .critical,
            title: "Header Shift",
            issueDescription: "Header block shifted downwards by 12px",
            elementName: "HeaderTitle",
            referenceValue: "(50, 20)",
            actualValue: "(50, 32)",
            delta: 12.0,
            unit: "px",
            boundingBox: CGRect(x: 50, y: 20, width: 300, height: 40)
        )
        
        let item2 = LayoutDiffItem(
            category: .typography,
            severity: .warning,
            title: "Font Size Mismatch",
            issueDescription: "Button text size is 13pt instead of 16pt",
            elementName: "PrimaryButton",
            referenceValue: "16 pt",
            actualValue: "13 pt",
            delta: 3.0,
            unit: "pt",
            boundingBox: CGRect(x: 50, y: 100, width: 120, height: 36)
        )
        
        return DiffResult(
            referenceImageSize: CGSize(width: 800, height: 600),
            actualImageSize: CGSize(width: 800, height: 600),
            diffItems: [item1, item2],
            matchPercentage: 80.0,
            totalBlocksDetected: 10
        )
    }
    
    @Test("JSON Export Serialization")
    func testJSONExport() throws {
        let exporter = ReportExporter()
        let result = createTestDiffResult()
        
        let jsonData = try exporter.exportJSON(result: result)
        #expect(!jsonData.isEmpty)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DiffResult.self, from: jsonData)
        
        #expect(decoded.matchPercentage == 80.0)
        #expect(decoded.totalBlocksDetected == 10)
        #expect(decoded.diffItems.count == 2)
        #expect(decoded.diffItems[0].elementName == "HeaderTitle")
    }
    
    @Test("Markdown Export Output Structure")
    func testMarkdownExport() {
        let exporter = ReportExporter()
        let result = createTestDiffResult()
        
        let md = exporter.exportMarkdown(result: result)
        
        #expect(md.contains("# 🔍 DesignLens Comparison Report"))
        #expect(md.contains("Overall Design Match**: `80.0%`"))
        #expect(md.contains("HeaderTitle"))
        #expect(md.contains("🔴 Critical"))
        #expect(md.contains("🟡 Warning"))
    }
    
    @Test("HTML Export Output Structure & Escape Handling")
    func testHTMLExport() {
        let exporter = ReportExporter()
        let result = createTestDiffResult()
        
        let html = exporter.exportHTML(result: result)
        
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("DesignLens Report"))
        #expect(html.contains("80.0%"))
        #expect(html.contains("HeaderTitle"))
        #expect(html.contains("Critical"))
        #expect(html.contains("Warning"))
    }
    
    @Test("Empty DiffResult Export Handling")
    func testEmptyDiffResultExport() {
        let exporter = ReportExporter()
        let emptyResult = DiffResult(
            referenceImageSize: CGSize(width: 500, height: 500),
            actualImageSize: CGSize(width: 500, height: 500),
            diffItems: [],
            matchPercentage: 100.0,
            totalBlocksDetected: 5
        )
        
        let md = exporter.exportMarkdown(result: emptyResult)
        #expect(md.contains("No visual or layout discrepancies detected"))
        
        let html = exporter.exportHTML(result: emptyResult)
        #expect(html.contains("Perfect Match"))
    }
}
