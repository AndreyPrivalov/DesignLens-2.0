import SwiftUI
import AppKit

public enum OverlayViewMode: String, CaseIterable, Identifiable {
    case split = "Split Wiper"
    case diffOverlay = "Diff Highlights"
    case blend = "Opacity Blend"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .split: return "slider.horizontal.below.rectangle"
        case .diffOverlay: return "square.on.square.squareshape.controlshapes"
        case .blend: return "square.2.layers.3d.bottom.filled"
        }
    }
}

public struct OverlayView: View {
    public let referenceImage: NSImage?
    public let actualImage: NSImage?
    public let diffResult: DiffResult?
    @Binding public var selectedDiffId: UUID?
    
    @State private var viewMode: OverlayViewMode = .split
    @State private var sliderPosition: CGFloat = 0.5
    @State private var blendOpacity: Double = 0.5
    @State private var selectedSeverityFilter: LayoutDiffItem.Severity? = nil
    
    public init(
        referenceImage: NSImage?,
        actualImage: NSImage?,
        diffResult: DiffResult?,
        selectedDiffId: Binding<UUID?> = .constant(nil)
    ) {
        self.referenceImage = referenceImage
        self.actualImage = actualImage
        self.diffResult = diffResult
        self._selectedDiffId = selectedDiffId
    }
    
    public var filteredDiffItems: [LayoutDiffItem] {
        guard let items = diffResult?.diffItems else { return [] }
        guard let filter = selectedSeverityFilter else { return items }
        return items.filter { $0.severity == filter }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar / Controls
            topControlBar
            
            // Main Canvas Area
            ZStack {
                Color(nsColor: NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1.0))
                    .edgesIgnoringSafeArea(.all)
                
                switch viewMode {
                case .split:
                    SplitSliderView(
                        referenceImage: referenceImage,
                        actualImage: actualImage,
                        sliderPosition: $sliderPosition
                    )
                    
                case .diffOverlay:
                    DifferenceMaskView(
                        image: actualImage ?? referenceImage,
                        imageSize: diffResult?.actualImageSize ?? referenceImage?.size ?? .zero,
                        diffItems: filteredDiffItems,
                        selectedDiffId: $selectedDiffId
                    )
                    
                case .blend:
                    opacityBlendView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Status Bar
            bottomStatusBar
        }
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
    }
    
    // MARK: - Subviews
    
    private var topControlBar: some View {
        HStack(spacing: 16) {
            // Mode Segmented Picker
            HStack(spacing: 2) {
                ForEach(OverlayViewMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            viewMode == mode ?
                            Color(red: 0.17, green: 0.5, blue: 1.0) :
                            Color.clear
                        )
                        .foregroundColor(viewMode == mode ? .white : Color.gray)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(red: 0.1, green: 0.13, blue: 0.18))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            Spacer()
            
            // Dynamic Mode Controls
            if viewMode == .blend {
                HStack(spacing: 8) {
                    Text("Blend:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Slider(value: $blendOpacity, in: 0...1)
                        .frame(width: 120)
                    
                    Text("\(Int(blendOpacity * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 38)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(red: 0.1, green: 0.13, blue: 0.18))
                .cornerRadius(6)
            } else if viewMode == .diffOverlay {
                // Severity Filter Buttons
                HStack(spacing: 6) {
                    filterChip(title: "All", count: diffResult?.diffItems.count ?? 0, severity: nil)
                    filterChip(title: "Critical", count: diffResult?.criticalCount ?? 0, severity: .critical)
                    filterChip(title: "Warning", count: diffResult?.warningCount ?? 0, severity: .warning)
                    filterChip(title: "Info", count: diffResult?.infoCount ?? 0, severity: .info)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.1, green: 0.13, blue: 0.18))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.08)),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func filterChip(title: String, count: Int, severity: LayoutDiffItem.Severity?) -> some View {
        let isSelected = (selectedSeverityFilter == severity)
        let chipColor: Color = {
            switch severity {
            case .critical: return Color(red: 0.937, green: 0.266, blue: 0.266)
            case .warning: return Color(red: 0.96, green: 0.62, blue: 0.04)
            case .info: return Color(red: 0.06, green: 0.725, blue: 0.505)
            case nil: return Color(red: 0.17, green: 0.5, blue: 1.0)
            }
        }()
        
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                selectedSeverityFilter = severity
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                Text("(\(count))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? chipColor.opacity(0.25) : Color.white.opacity(0.05))
            .foregroundColor(isSelected ? chipColor : Color.gray)
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? chipColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var opacityBlendView: some View {
        GeometryReader { geometry in
            ZStack {
                if let refImg = referenceImage {
                    Image(nsImage: refImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                if let actImg = actualImage {
                    Image(nsImage: actImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(blendOpacity)
                }
            }
        }
    }
    
    private var bottomStatusBar: some View {
        HStack(spacing: 16) {
            // Match Percentage Badge
            if let result = diffResult {
                let match = result.matchPercentage
                let scoreColor: Color = match >= 90.0 ? Color(red: 0.06, green: 0.725, blue: 0.505) :
                                       (match >= 75.0 ? Color(red: 0.96, green: 0.62, blue: 0.04) :
                                                        Color(red: 0.937, green: 0.266, blue: 0.266))
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(scoreColor)
                    Text("Match:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f%%", match))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(scoreColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(scoreColor.opacity(0.12))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Issues Summary Pill
            if let result = diffResult {
                HStack(spacing: 8) {
                    Text("\(result.totalIssuesCount) Discrepancies Detected")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if result.criticalCount > 0 {
                        Text("\(result.criticalCount) Critical")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.937, green: 0.266, blue: 0.266))
                    }
                    if result.warningCount > 0 {
                        Text("\(result.warningCount) Warning")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                    }
                }
            } else {
                Text("No Analysis Result Available")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Image Resolution Badges
            if let ref = referenceImage {
                Text("Ref: \(Int(ref.size.width))×\(Int(ref.size.height))px")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            if let act = actualImage {
                Text("Act: \(Int(act.size.width))×\(Int(act.size.height))px")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.08, green: 0.1, blue: 0.14))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.08)),
            alignment: .top
        )
    }
}
