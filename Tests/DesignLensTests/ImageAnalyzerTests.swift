import XCTest
import CoreGraphics
import AppKit
@testable import DesignLens

final class ImageAnalyzerTests: XCTestCase {
    
    // Helper to generate synthetic test CGImages
    private func createTestCGImage(width: Int, height: Int, fillColor: NSColor = .white) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        context.setFillColor(fillColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw a dark blue box representing a UI button/block
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(CGRect(x: 50, y: 50, width: 200, height: 80))
        
        return context.makeImage()!
    }
    
    func testImageCropperCoordinateConversion() {
        let visionRect = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.3)
        let imageSize = CGSize(width: 1000, height: 500)
        
        let converted = ImageCropper.convertVisionRect(visionRect, imageSize: imageSize)
        
        XCTAssertEqual(converted.origin.x, 100.0)
        XCTAssertEqual(converted.width, 500.0)
        XCTAssertEqual(converted.height, 150.0)
        // vision origin y=0.2, height=0.3 -> top-left y = (1.0 - 0.2 - 0.3) * 500 = 0.5 * 500 = 250
        XCTAssertEqual(converted.origin.y, 250.0)
    }
    
    func testImageCropperDominantColor() {
        let cgImage = createTestCGImage(width: 300, height: 300, fillColor: .red)
        let colorHex = ImageCropper.dominantColorHex(cgImage: cgImage, rect: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        XCTAssertFalse(colorHex.isEmpty)
        XCTAssertTrue(colorHex.hasPrefix("#"))
    }
    
    func testBlockSegmentation() async throws {
        let cgImage = createTestCGImage(width: 400, height: 400)
        let segmenter = BlockSegmentation()
        
        let blocks = try await segmenter.segment(cgImage: cgImage)
        XCTAssertNotNil(blocks)
    }
    
    func testImageAnalyzerDiffing() async throws {
        let refImage = createTestCGImage(width: 500, height: 500, fillColor: .white)
        let actImage = createTestCGImage(width: 500, height: 500, fillColor: .black)
        
        let analyzer = ImageAnalyzer()
        let config = DesignSystemConfig.fallbackDefault
        
        let result = try await analyzer.analyze(referenceCGImage: refImage, actualCGImage: actImage, config: config)
        
        XCTAssertEqual(result.referenceImageSize, CGSize(width: 500, height: 500))
        XCTAssertEqual(result.actualImageSize, CGSize(width: 500, height: 500))
        XCTAssertGreaterThanOrEqual(result.matchPercentage, 0.0)
        XCTAssertLessThanOrEqual(result.matchPercentage, 100.0)
    }
}
