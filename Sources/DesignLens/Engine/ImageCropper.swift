import Foundation
import CoreGraphics
import AppKit

public struct ImageCropper: Sendable {
    public init() {}
    
    /// Converts a normalized Vision bounding box (origin bottom-left, values 0..1)
    /// to standard pixel coordinates (origin top-left).
    public static func convertVisionRect(_ visionRect: CGRect, imageSize: CGSize) -> CGRect {
        let x = visionRect.origin.x * imageSize.width
        let width = visionRect.size.width * imageSize.width
        let height = visionRect.size.height * imageSize.height
        let y = (1.0 - visionRect.origin.y - visionRect.size.height) * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// Crops a `CGImage` to the given rect (in standard top-left pixel coordinates).
    public static func crop(cgImage: CGImage, rect: CGRect, padding: CGFloat = 0) -> CGImage? {
        let expandedRect = rect.insetBy(dx: -padding, dy: -padding)
        let bounds = CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let finalRect = expandedRect.intersection(bounds)
        
        guard finalRect.width > 0 && finalRect.height > 0 else { return nil }
        return cgImage.cropping(to: finalRect)
    }
    
    /// Crops an `NSImage` to the given rect (in standard top-left pixel coordinates).
    public static func crop(image: NSImage, rect: CGRect, padding: CGFloat = 0) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        guard let croppedCG = crop(cgImage: cgImage, rect: rect, padding: padding) else {
            return nil
        }
        return NSImage(cgImage: croppedCG, size: NSSize(width: croppedCG.width, height: croppedCG.height))
    }
    
    /// Extracts the dominant color (as a hex string "#RRGGBB") from a CGImage rect.
    public static func dominantColorHex(cgImage: CGImage, rect: CGRect) -> String {
        guard let cropped = crop(cgImage: cgImage, rect: rect) else {
            return "#000000"
        }
        
        let width = min(cropped.width, 32)
        let height = min(cropped.height, 32)
        let totalPixels = width * height
        guard totalPixels > 0 else { return "#000000" }
        
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return "#000000"
        }
        
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var rTotal: UInt64 = 0
        var gTotal: UInt64 = 0
        var bTotal: UInt64 = 0
        
        for i in 0..<totalPixels {
            let offset = i * 4
            rTotal += UInt64(rawData[offset])
            gTotal += UInt64(rawData[offset + 1])
            bTotal += UInt64(rawData[offset + 2])
        }
        
        let rAvg = Int(rTotal / UInt64(totalPixels))
        let gAvg = Int(gTotal / UInt64(totalPixels))
        let bAvg = Int(bTotal / UInt64(totalPixels))
        
        return String(format: "#%02X%02X%02X", rAvg, gAvg, bAvg)
    }
}
