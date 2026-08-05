import Testing
import Foundation
import CoreGraphics
import AppKit
@testable import DesignLens

@Suite("Overlay View Tests")
struct OverlayViewTests {
    
    @Test("Overlay View Modes raw values and icons")
    func testOverlayViewModes() {
        #expect(OverlayViewMode.split.rawValue == "Split Wiper")
        #expect(OverlayViewMode.diffOverlay.rawValue == "Diff Highlights")
        #expect(OverlayViewMode.blend.rawValue == "Opacity Blend")
        
        #expect(!OverlayViewMode.split.iconName.isEmpty)
        #expect(!OverlayViewMode.diffOverlay.iconName.isEmpty)
        #expect(!OverlayViewMode.blend.iconName.isEmpty)
    }
    
    @Test("Diff items filtering by severity")
    @MainActor
    func testDiffItemsFiltering() {
        let item1 = LayoutDiffItem(
            category: .spacing,
            severity: .critical,
            title: "Padding Mismatch",
            issueDescription: "Top padding is 24px instead of 16px",
            elementName: "HeaderContainer",
            referenceValue: "16px",
            actualValue: "24px",
            delta: 8.0,
            unit: "px",
            boundingBox: CGRect(x: 10, y: 10, width: 200, height: 50)
        )
        
        let item2 = LayoutDiffItem(
            category: .typography,
            severity: .warning,
            title: "Font Weight Mismatch",
            issueDescription: "Font weight is Regular instead of Semibold",
            elementName: "TitleLabel",
            referenceValue: "Semibold",
            actualValue: "Regular",
            delta: nil,
            unit: "",
            boundingBox: CGRect(x: 10, y: 70, width: 150, height: 30)
        )
        
        let diffResult = DiffResult(
            referenceImageSize: CGSize(width: 800, height: 600),
            actualImageSize: CGSize(width: 800, height: 600),
            diffItems: [item1, item2],
            matchPercentage: 88.5,
            totalBlocksDetected: 12
        )
        
        let overlayView = OverlayView(
            referenceImage: nil,
            actualImage: nil,
            diffResult: diffResult
        )
        
        #expect(overlayView.filteredDiffItems.count == 2)
    }
}
