import Testing
import SwiftUI
import AppKit
@testable import DesignLens

@Suite("Content View & DropZone Integration Tests")
struct ContentViewTests {
    
    @Test("ViewTabMode raw values and icons")
    func testViewTabModes() {
        #expect(ViewTabMode.canvas.rawValue == "Visual Canvas")
        #expect(ViewTabMode.fixList.rawValue == "Fix List")
        
        #expect(!ViewTabMode.canvas.iconName.isEmpty)
        #expect(!ViewTabMode.fixList.iconName.isEmpty)
    }
    
    @Test("DropZoneType enum properties")
    func testDropZoneTypeProperties() {
        #expect(DropZoneType.reference.rawValue == "Reference Design")
        #expect(DropZoneType.actual.rawValue == "Actual Implementation")
        #expect(DropZoneType.customConfig.rawValue == "Design System JSON")
        
        #expect(!DropZoneType.reference.iconName.isEmpty)
        #expect(!DropZoneType.actual.iconName.isEmpty)
        #expect(!DropZoneType.customConfig.iconName.isEmpty)
    }
    
    @Test("DropZoneView initializers")
    @MainActor
    func testDropZoneViewInit() {
        let dropZone = DropZoneView(
            type: .reference,
            title: "Custom Reference Title",
            subtitle: "Custom Subtitle",
            image: nil
        )
        
        #expect(dropZone.type == .reference)
        #expect(dropZone.title == "Custom Reference Title")
        #expect(dropZone.subtitle == "Custom Subtitle")
    }
}
