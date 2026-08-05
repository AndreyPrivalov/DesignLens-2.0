import Foundation
import CoreGraphics
import Vision
import AppKit

public struct BlockSegmentation: Sendable {
    public init() {}
    
    /// Segment a CGImage into a list of BlockElements using Vision text recognition and rectangle detection.
    public func segment(cgImage: CGImage) async throws -> [BlockElement] {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        guard imageSize.width > 0 && imageSize.height > 0 else { return [] }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 1. Text Recognition Request
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true
        
        // 2. Rectangle Detection Request
        let rectRequest = VNDetectRectanglesRequest()
        rectRequest.minimumConfidence = 0.5
        rectRequest.minimumSize = 0.02
        rectRequest.maximumObservations = 50
        
        try requestHandler.perform([textRequest, rectRequest])
        
        var elements: [BlockElement] = []
        
        // Process Recognized Text Observations
        if let textObservations = textRequest.results {
            for obs in textObservations {
                guard let topCandidate = obs.topCandidates(1).first else { continue }
                let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                
                let pixelRect = ImageCropper.convertVisionRect(obs.boundingBox, imageSize: imageSize)
                let estimatedFontSize = max(10.0, Double(pixelRect.height) * 0.75)
                
                // Heuristic font weight based on confidence and text case
                let isAllCaps = text.count > 1 && text == text.uppercased()
                let isBoldCandidate = isAllCaps || estimatedFontSize >= 18.0
                let fontWeight = isBoldCandidate ? "Bold" : (estimatedFontSize >= 15.0 ? "Semibold" : "Regular")
                
                let label: String
                if estimatedFontSize >= 20.0 {
                    label = "Header: \(text.prefix(20))"
                } else if text.count <= 15 && isAllCaps {
                    label = "Button / Badge: \(text)"
                } else {
                    label = "Text: \(text.prefix(25))"
                }
                
                let dominantColor = ImageCropper.dominantColorHex(cgImage: cgImage, rect: pixelRect)
                
                let element = BlockElement(
                    label: label,
                    boundingBox: pixelRect,
                    extractedText: text,
                    fontSize: estimatedFontSize,
                    fontWeight: fontWeight,
                    dominantColorHex: dominantColor
                )
                elements.append(element)
            }
        }
        
        // Process Detected Rectangles that don't heavily overlap text elements
        if let rectObservations = rectRequest.results {
            for (idx, rectObs) in rectObservations.enumerated() {
                let pixelRect = ImageCropper.convertVisionRect(rectObs.boundingBox, imageSize: imageSize)
                
                // Avoid duplicating boxes that already tightly wrap text
                let matchesExistingText = elements.contains { textElem in
                    textElem.boundingBox.intersection(pixelRect).area > (textElem.boundingBox.area * 0.7)
                }
                
                if !matchesExistingText && pixelRect.width > 20 && pixelRect.height > 20 {
                    let dominantColor = ImageCropper.dominantColorHex(cgImage: cgImage, rect: pixelRect)
                    let element = BlockElement(
                        label: "Container Block #\(idx + 1)",
                        boundingBox: pixelRect,
                        extractedText: nil,
                        fontSize: nil,
                        fontWeight: nil,
                        dominantColorHex: dominantColor
                    )
                    elements.append(element)
                }
            }
        }
        
        // Build hierarchy if some elements are completely inside container blocks
        return groupElementsIntoHierarchy(elements)
    }
    
    /// Groups child elements into their containing parent elements.
    private func groupElementsIntoHierarchy(_ elements: [BlockElement]) -> [BlockElement] {
        var parents: [BlockElement] = []
        var assignedAsChild = Set<UUID>()
        
        // Sort elements by bounding box area descending (containers first)
        let sorted = elements.sorted { $0.boundingBox.area > $1.boundingBox.area }
        
        for (index, candidateParent) in sorted.enumerated() {
            var children: [BlockElement] = []
            
            for child in sorted.dropFirst(index + 1) {
                if candidateParent.boundingBox.contains(child.boundingBox) && candidateParent.id != child.id {
                    children.append(child)
                    assignedAsChild.insert(child.id)
                }
            }
            
            if !children.isEmpty {
                let parentWithChildren = BlockElement(
                    id: candidateParent.id,
                    label: candidateParent.label,
                    boundingBox: candidateParent.boundingBox,
                    extractedText: candidateParent.extractedText,
                    fontSize: candidateParent.fontSize,
                    fontWeight: candidateParent.fontWeight,
                    dominantColorHex: candidateParent.dominantColorHex,
                    children: children
                )
                parents.append(parentWithChildren)
            } else if !assignedAsChild.contains(candidateParent.id) {
                parents.append(candidateParent)
            }
        }
        
        return parents
    }
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
