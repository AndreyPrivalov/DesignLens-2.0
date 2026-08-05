import SwiftUI
import AppKit

public struct DifferenceMaskView: View {
    public let image: NSImage?
    public let imageSize: CGSize
    public let diffItems: [LayoutDiffItem]
    @Binding public var selectedDiffId: UUID?
    
    @State private var hoveredDiffId: UUID? = nil
    
    public init(
        image: NSImage?,
        imageSize: CGSize,
        diffItems: [LayoutDiffItem],
        selectedDiffId: Binding<UUID?> = .constant(nil)
    ) {
        self.image = image
        self.imageSize = imageSize
        self.diffItems = diffItems
        self._selectedDiffId = selectedDiffId
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size
            
            ZStack(alignment: .topLeading) {
                // Background Image
                Color(nsColor: NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1.0))
                    .edgesIgnoringSafeArea(.all)
                
                if let nsImage = image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: viewSize.width, height: viewSize.height)
                }
                
                // Bounding Box Highlights Layer
                let rectScale = calculateScale(imageSize: imageSize, viewSize: viewSize)
                
                ForEach(diffItems) { item in
                    let rect = scaledRect(item.boundingBox, scale: rectScale, viewSize: viewSize, imageSize: imageSize)
                    let isSelected = (selectedDiffId == item.id)
                    let isHovered = (hoveredDiffId == item.id)
                    let itemColor = color(for: item.severity)
                    
                    ZStack(alignment: .topLeading) {
                        // Bounding Box Rect
                        Rectangle()
                            .fill(itemColor.opacity(isSelected ? 0.3 : (isHovered ? 0.25 : 0.12)))
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        itemColor,
                                        style: StrokeStyle(
                                            lineWidth: isSelected || isHovered ? 2.5 : 1.5,
                                            dash: item.severity == .critical ? [] : [4, 3]
                                        )
                                    )
                            )
                            .cornerRadius(4)
                        
                        // Badge Tag
                        HStack(spacing: 4) {
                            Circle()
                                .fill(itemColor)
                                .frame(width: 6, height: 6)
                            
                            Text(item.elementName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if let delta = item.delta {
                                Text("\(delta > 0 ? "+" : "")\(String(format: "%.1f", delta))\(item.unit)")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundColor(itemColor)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.1, green: 0.13, blue: 0.18).opacity(0.9))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(itemColor.opacity(0.5), lineWidth: 1)
                        )
                        .offset(y: -22)
                    }
                    .frame(width: max(10, rect.width), height: max(10, rect.height))
                    .position(x: rect.midX, y: rect.midY)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedDiffId = (selectedDiffId == item.id ? nil : item.id)
                        }
                    }
                    .onHover { hovering in
                        hoveredDiffId = hovering ? item.id : nil
                    }
                    .popover(isPresented: Binding(
                        get: { isSelected },
                        set: { if !$0 { selectedDiffId = nil } }
                    )) {
                        diffDetailPopover(item: item, color: itemColor)
                    }
                }
            }
        }
    }
    
    // Calculate aspect fit image rect scale
    private func calculateScale(imageSize: CGSize, viewSize: CGSize) -> CGFloat {
        guard imageSize.width > 0 && imageSize.height > 0 && viewSize.width > 0 && viewSize.height > 0 else {
            return 1.0
        }
        let widthRatio = viewSize.width / imageSize.width
        let heightRatio = viewSize.height / imageSize.height
        return min(widthRatio, heightRatio)
    }
    
    private func scaledRect(_ box: CGRect, scale: CGFloat, viewSize: CGSize, imageSize: CGSize) -> CGRect {
        // Handle normalized coordinates [0, 1] vs absolute pixel coordinates
        let isNormalized = box.maxX <= 1.0 && box.maxY <= 1.0
        let absBox: CGRect
        if isNormalized {
            absBox = CGRect(
                x: box.origin.x * imageSize.width,
                y: box.origin.y * imageSize.height,
                width: box.width * imageSize.width,
                height: box.height * imageSize.height
            )
        } else {
            absBox = box
        }
        
        let fittedWidth = imageSize.width * scale
        let fittedHeight = imageSize.height * scale
        let offsetX = (viewSize.width - fittedWidth) / 2.0
        let offsetY = (viewSize.height - fittedHeight) / 2.0
        
        return CGRect(
            x: offsetX + (absBox.origin.x * scale),
            y: offsetY + (absBox.origin.y * scale),
            width: absBox.width * scale,
            height: absBox.height * scale
        )
    }
    
    private func color(for severity: LayoutDiffItem.Severity) -> Color {
        switch severity {
        case .critical:
            return Color(red: 0.937, green: 0.266, blue: 0.266) // #EF4444
        case .warning:
            return Color(red: 0.96, green: 0.62, blue: 0.04)   // #F59E0B
        case .info:
            return Color(red: 0.06, green: 0.725, blue: 0.505)  // #10B981
        }
    }
    
    @ViewBuilder
    private func diffDetailPopover(item: LayoutDiffItem, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.category.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(item.severity.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(item.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            
            Text(item.issueDescription)
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reference")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                    Text(item.referenceValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.17, green: 0.5, blue: 1.0))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actual")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                    Text(item.actualValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.66, green: 0.33, blue: 0.97))
                }
                
                if let delta = item.delta {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delta")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.gray)
                        Text("\(delta > 0 ? "+" : "")\(String(format: "%.1f", delta))\(item.unit)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(Color(red: 0.1, green: 0.13, blue: 0.18))
    }
}
