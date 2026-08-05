import Foundation
import CoreGraphics
import AppKit

public final class ImageAnalyzer: @unchecked Sendable {
    private let segmenter: BlockSegmentation
    
    public init(segmenter: BlockSegmentation = BlockSegmentation()) {
        self.segmenter = segmenter
    }
    
    /// Analyzes reference and actual NSImages against a DesignSystemConfig.
    public func analyze(
        referenceImage: NSImage,
        actualImage: NSImage,
        config: DesignSystemConfig = .loadDefault()
    ) async throws -> DiffResult {
        guard let refCG = referenceImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let actCG = actualImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "ImageAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert NSImage to CGImage"])
        }
        return try await analyze(referenceCGImage: refCG, actualCGImage: actCG, config: config)
    }
    
    /// Analyzes reference and actual CGImages against a DesignSystemConfig.
    public func analyze(
        referenceCGImage: CGImage,
        actualCGImage: CGImage,
        config: DesignSystemConfig = .loadDefault()
    ) async throws -> DiffResult {
        let refSize = CGSize(width: referenceCGImage.width, height: referenceCGImage.height)
        let actSize = CGSize(width: actualCGImage.width, height: actualCGImage.height)
        
        let refBlocks = try await segmenter.segment(cgImage: referenceCGImage)
        let actBlocks = try await segmenter.segment(cgImage: actualCGImage)
        
        var diffItems: [LayoutDiffItem] = []
        var matchedActualIDs = Set<UUID>()
        
        // 1. Compare Reference Blocks against Actual Blocks
        for refBlock in refBlocks {
            let matchedActBlock = findMatchingBlock(refBlock: refBlock, actBlocks: actBlocks, matchedIDs: matchedActualIDs)
            
            if let actBlock = matchedActBlock {
                matchedActualIDs.insert(actBlock.id)
                let itemDiffs = compareBlocks(refBlock: refBlock, actBlock: actBlock, config: config)
                diffItems.append(contentsOf: itemDiffs)
            } else {
                // Missing element issue
                let item = LayoutDiffItem(
                    category: .missingElement,
                    severity: .critical,
                    title: "Missing Element: \(refBlock.label)",
                    issueDescription: "Element present in reference design was not detected in actual UI.",
                    elementName: refBlock.label,
                    referenceValue: refBlock.extractedText ?? "Present (\(Int(refBlock.boundingBox.width))x\(Int(refBlock.boundingBox.height))px)",
                    actualValue: "Missing",
                    delta: nil,
                    unit: "px",
                    boundingBox: refBlock.boundingBox,
                    actualBoundingBox: nil
                )
                diffItems.append(item)
            }
        }
        
        // 2. Unmatched Actual Blocks (Added / Extra Elements)
        for actBlock in actBlocks where !matchedActualIDs.contains(actBlock.id) {
            let item = LayoutDiffItem(
                category: .missingElement,
                severity: .info,
                title: "Unexpected Extra Element: \(actBlock.label)",
                issueDescription: "Element detected in actual UI that was not present in reference spec.",
                elementName: actBlock.label,
                referenceValue: "None",
                actualValue: actBlock.extractedText ?? "Added (\(Int(actBlock.boundingBox.width))x\(Int(actBlock.boundingBox.height))px)",
                delta: nil,
                unit: "px",
                boundingBox: actBlock.boundingBox,
                actualBoundingBox: actBlock.boundingBox
            )
            diffItems.append(item)
        }
        
        // 3. Compute overall match percentage
        let criticalPenalty = Double(diffItems.filter { $0.severity == .critical }.count) * 15.0
        let warningPenalty = Double(diffItems.filter { $0.severity == .warning }.count) * 5.0
        let infoPenalty = Double(diffItems.filter { $0.severity == .info }.count) * 1.5
        let totalPenalty = criticalPenalty + warningPenalty + infoPenalty
        let matchPercentage = max(0.0, min(100.0, 100.0 - totalPenalty))
        
        let totalBlocks = refBlocks.count + actBlocks.count
        
        return DiffResult(
            referenceImageSize: refSize,
            actualImageSize: actSize,
            diffItems: diffItems,
            matchPercentage: matchPercentage,
            totalBlocksDetected: totalBlocks
        )
    }
    
    // MARK: - Helper Methods
    
    private func findMatchingBlock(
        refBlock: BlockElement,
        actBlocks: [BlockElement],
        matchedIDs: Set<UUID>
    ) -> BlockElement? {
        // Priority 1: Exact text match
        if let refText = refBlock.extractedText, !refText.isEmpty {
            if let match = actBlocks.first(where: { !matchedIDs.contains($0.id) && $0.extractedText == refText }) {
                return match
            }
        }
        
        // Priority 2: Closest bounding box center distance
        let refCenter = CGPoint(x: refBlock.boundingBox.midX, y: refBlock.boundingBox.midY)
        let candidates = actBlocks.filter { !matchedIDs.contains($0.id) }
        
        return candidates.min(by: { b1, b2 in
            let c1 = CGPoint(x: b1.boundingBox.midX, y: b1.boundingBox.midY)
            let c2 = CGPoint(x: b2.boundingBox.midX, y: b2.boundingBox.midY)
            let d1 = hypot(c1.x - refCenter.x, c1.y - refCenter.y)
            let d2 = hypot(c2.x - refCenter.x, c2.y - refCenter.y)
            return d1 < d2
        })
    }
    
    private func compareBlocks(
        refBlock: BlockElement,
        actBlock: BlockElement,
        config: DesignSystemConfig
    ) -> [LayoutDiffItem] {
        var diffs: [LayoutDiffItem] = []
        
        // A. Spacing & Position Check
        let dx = actBlock.boundingBox.origin.x - refBlock.boundingBox.origin.x
        let dy = actBlock.boundingBox.origin.y - refBlock.boundingBox.origin.y
        let posDelta = max(abs(dx), abs(dy))
        
        if posDelta > config.tolerances.spacingPx {
            let severity: LayoutDiffItem.Severity = posDelta > 8.0 ? .critical : .warning
            diffs.append(LayoutDiffItem(
                category: .spacing,
                severity: severity,
                title: "Position Shift in \(refBlock.label)",
                issueDescription: "Element origin shifted by (\(Int(dx))px, \(Int(dy))px).",
                elementName: refBlock.label,
                referenceValue: "(\(Int(refBlock.boundingBox.origin.x)), \(Int(refBlock.boundingBox.origin.y)))",
                actualValue: "(\(Int(actBlock.boundingBox.origin.x)), \(Int(actBlock.boundingBox.origin.y)))",
                delta: Double(posDelta),
                unit: "px",
                boundingBox: refBlock.boundingBox,
                actualBoundingBox: actBlock.boundingBox
            ))
        }
        
        // B. Dimension Mismatch Check
        let dw = actBlock.boundingBox.width - refBlock.boundingBox.width
        let dh = actBlock.boundingBox.height - refBlock.boundingBox.height
        let dimDelta = max(abs(dw), abs(dh))
        
        if dimDelta > config.tolerances.dimensionPx {
            let severity: LayoutDiffItem.Severity = dimDelta > 10.0 ? .critical : .warning
            diffs.append(LayoutDiffItem(
                category: .dimension,
                severity: severity,
                title: "Size Discrepancy in \(refBlock.label)",
                issueDescription: "Dimensions differ from reference spec (Width delta: \(Int(dw))px, Height delta: \(Int(dh))px).",
                elementName: refBlock.label,
                referenceValue: "\(Int(refBlock.boundingBox.width)) x \(Int(refBlock.boundingBox.height)) px",
                actualValue: "\(Int(actBlock.boundingBox.width)) x \(Int(actBlock.boundingBox.height)) px",
                delta: Double(dimDelta),
                unit: "px",
                boundingBox: refBlock.boundingBox,
                actualBoundingBox: actBlock.boundingBox
            ))
        }
        
        // C. Typography Check
        if let refFontSize = refBlock.fontSize, let actFontSize = actBlock.fontSize {
            let fontDelta = abs(actFontSize - refFontSize)
            
            // Find closest matching token in DesignSystemConfig for reference
            let matchingToken = config.typography.min(by: { abs($0.expectedSize - refFontSize) < abs($1.expectedSize - refFontSize) })
            let tolerance = matchingToken?.tolerancePt ?? 1.0
            
            if fontDelta > tolerance {
                diffs.append(LayoutDiffItem(
                    category: .typography,
                    severity: fontDelta > 3.0 ? .critical : .warning,
                    title: "Typography Font Size Mismatch",
                    issueDescription: "Detected font size (\(Int(actFontSize))pt) deviates from reference (\(Int(refFontSize))pt).",
                    elementName: refBlock.label,
                    referenceValue: "\(Int(refFontSize)) pt",
                    actualValue: "\(Int(actFontSize)) pt",
                    delta: fontDelta,
                    unit: "pt",
                    boundingBox: refBlock.boundingBox,
                    actualBoundingBox: actBlock.boundingBox
                ))
            }
        }
        
        // D. Color Mismatch Check
        if let refColor = refBlock.dominantColorHex, let actColor = actBlock.dominantColorHex, refColor != actColor {
            diffs.append(LayoutDiffItem(
                category: .colorMismatch,
                severity: .info,
                title: "Dominant Color Mismatch",
                issueDescription: "Element dominant hex color shifted from \(refColor) to \(actColor).",
                elementName: refBlock.label,
                referenceValue: refColor,
                actualValue: actColor,
                delta: nil,
                unit: "hex",
                boundingBox: refBlock.boundingBox,
                actualBoundingBox: actBlock.boundingBox
            ))
        }
        
        return diffs
    }
}
