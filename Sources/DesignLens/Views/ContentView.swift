import SwiftUI
import AppKit

public enum ViewTabMode: String, CaseIterable, Identifiable {
    case canvas = "Visual Canvas"
    case fixList = "Fix List"
    
    public var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .canvas: return "eye.circle.fill"
        case .fixList: return "list.bullet.rectangle.fill"
        }
    }
}

public struct ContentView: View {
    @State private var referenceImage: NSImage? = nil
    @State private var actualImage: NSImage? = nil
    @State private var customConfig: DesignSystemConfig = .loadDefault()
    @State private var diffResult: DiffResult? = nil
    @State private var selectedDiffId: UUID? = nil
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var exportNotification: String? = nil
    @State private var activeTabMode: ViewTabMode = .canvas
    
    private let analyzer = ImageAnalyzer()
    private let exporter = ReportExporter()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Top Window Header Bar
            headerBar
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Main App Content Container
            HSplitView {
                // Left Panel: Work Area / Canvas
                ZStack {
                    Color(red: 0.07, green: 0.09, blue: 0.12)
                        .edgesIgnoringSafeArea(.all)
                    
                    if referenceImage == nil || actualImage == nil {
                        initialSetupView
                            .padding(24)
                    } else if isAnalyzing {
                        analyzingIndicatorView
                    } else {
                        switch activeTabMode {
                        case .canvas:
                            OverlayView(
                                referenceImage: referenceImage,
                                actualImage: actualImage,
                                diffResult: diffResult,
                                selectedDiffId: $selectedDiffId
                            )
                        case .fixList:
                            fixListFullView
                        }
                    }
                    
                    if let toastText = exportNotification {
                        toastNotificationView(toastText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Right Panel: Inspector Sidebar
                InspectorView(
                    diffResult: diffResult,
                    selectedDiffId: $selectedDiffId
                )
            }
        }
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
        .alert("DesignLens Alert", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack(spacing: 16) {
            // Branding Logo & Title
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.17, green: 0.50, blue: 1.0), Color(red: 0.66, green: 0.33, blue: 0.97)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("DesignLens")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("macOS 2.0 Visual QA Engine")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                }
            }
            
            // Mode Switcher (Tab Buttons)
            if referenceImage != nil && actualImage != nil {
                HStack(spacing: 2) {
                    ForEach(ViewTabMode.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTabMode = mode
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: mode.iconName)
                                Text(mode.rawValue)
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(activeTabMode == mode ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color.clear)
                            .foregroundColor(activeTabMode == mode ? .white : Color(red: 0.7, green: 0.75, blue: 0.85))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Match Score Badge
            if let result = diffResult {
                matchScoreBadge(result)
            }
            
            // Re-Analyze Action Button
            if referenceImage != nil && actualImage != nil {
                Button {
                    Task {
                        await runComparison()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isAnalyzing ? "arrow.triangle.2.circlepath" : "play.fill")
                        Text(isAnalyzing ? "Analyzing..." : "Re-Analyze")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.17, green: 0.50, blue: 1.0))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isAnalyzing)
            }
            
            // Export Dropdown
            if let result = diffResult {
                Menu {
                    Button("Export HTML Report...") {
                        exportHTML(result)
                    }
                    Button("Export Markdown Summary...") {
                        exportMarkdown(result)
                    }
                    Button("Export Raw JSON Data...") {
                        exportJSON(result)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
            }
            
            // Load Demo / Clear Buttons
            HStack(spacing: 8) {
                if referenceImage == nil || actualImage == nil {
                    Button {
                        loadDemoImages()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Load Demo Pair")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(Color(red: 0.66, green: 0.33, blue: 0.97))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        referenceImage = nil
                        actualImage = nil
                        diffResult = nil
                        selectedDiffId = nil
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray)
                    }
                    .buttonStyle(.plain)
                    .help("Clear Workspace")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.10, green: 0.12, blue: 0.17))
    }
    
    // MARK: - Initial Setup Dropzone Panel
    
    private var initialSetupView: some View {
        VStack(spacing: 20) {
            // Section Header
            VStack(spacing: 6) {
                Text("Compare UI Screenshots & Design Specs")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Drop reference design, actual build screenshot, or custom JSON design system rules below.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
            }
            
            // Custom Config Card Dropzone
            DropZoneView(
                type: .customConfig,
                config: customConfig,
                onConfigSelected: { newConfig in
                    if let cfg = newConfig {
                        self.customConfig = cfg
                        showToast("Loaded Design System: \(cfg.name)")
                    } else {
                        self.customConfig = .loadDefault()
                        showToast("Reset to Default Design System")
                    }
                }
            )
            .frame(height: 90)
            
            // Side-by-Side Image Dropzones
            HStack(spacing: 20) {
                DropZoneView(
                    type: .reference,
                    title: "Reference Design",
                    subtitle: "Figma mockup / Figma export",
                    image: referenceImage,
                    onImageSelected: { img in
                        referenceImage = img
                        checkAutoAnalyze()
                    }
                )
                
                DropZoneView(
                    type: .actual,
                    title: "Actual Implementation",
                    subtitle: "Screenshot of build app",
                    image: actualImage,
                    onImageSelected: { img in
                        actualImage = img
                        checkAutoAnalyze()
                    }
                )
            }
        }
    }
    
    // MARK: - Fix List Tab Full View
    
    private var fixListFullView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Discrepancy Summary & Remediation Steps")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let count = diffResult?.diffItems.count {
                    Text("\(count) issues detected")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.66, green: 0.33, blue: 0.97))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if let result = diffResult, !result.diffItems.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(result.diffItems) { item in
                            fixListRowCard(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.51))
                    Text("No Layout Discrepancies Found")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your implementation strictly aligns with the design spec.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func fixListRowCard(_ item: LayoutDiffItem) -> some View {
        let isSelected = selectedDiffId == item.id
        let severityColor: Color
        switch item.severity {
        case .critical: severityColor = Color(red: 0.94, green: 0.27, blue: 0.27)
        case .warning: severityColor = Color(red: 0.96, green: 0.62, blue: 0.04)
        case .info: severityColor = Color(red: 0.17, green: 0.50, blue: 1.0)
        }
        
        return HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(item.category.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)
                        .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.9))
                }
                
                Text(item.issueDescription)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))
                
                HStack(spacing: 12) {
                    Text("Target: \(item.elementName)")
                    Text("Expected: \(item.referenceValue)")
                    Text("Actual: \(item.actualValue)")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.gray)
            }
        }
        .padding(14)
        .background(isSelected ? Color(red: 0.15, green: 0.20, blue: 0.28) : Color(red: 0.10, green: 0.12, blue: 0.17))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
        )
        .cornerRadius(8)
        .onTapGesture {
            selectedDiffId = item.id
        }
    }
    
    // MARK: - Components
    
    private func matchScoreBadge(_ result: DiffResult) -> some View {
        let scoreColor: Color
        if result.matchPercentage >= 90.0 {
            scoreColor = Color(red: 0.06, green: 0.72, blue: 0.51)
        } else if result.matchPercentage >= 75.0 {
            scoreColor = Color(red: 0.96, green: 0.62, blue: 0.04)
        } else {
            scoreColor = Color(red: 0.94, green: 0.27, blue: 0.27)
        }
        
        return HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("MATCH SCORE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.gray)
                Text("\(String(format: "%.1f", result.matchPercentage))%")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(scoreColor)
            }
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.15))
            
            Text("\(result.diffItems.count) issues")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(scoreColor.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(6)
    }
    
    private var analyzingIndicatorView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)
            
            Text("Segmenting Blocks & Analyzing Layout...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.9))
            
            Text("Vision Engine processing element coordinates, typography, and color shifts against '\(customConfig.name)'.")
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
        }
    }
    
    private func toastNotificationView(_ text: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.51))
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.12, green: 0.15, blue: 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
            .padding(.bottom, 24)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Handlers & Demo Helper
    
    private func checkAutoAnalyze() {
        if referenceImage != nil && actualImage != nil {
            Task {
                await runComparison()
            }
        }
    }
    
    @MainActor
    private func runComparison() async {
        guard let ref = referenceImage, let act = actualImage else { return }
        isAnalyzing = true
        diffResult = nil
        
        do {
            let result = try await analyzer.analyze(referenceImage: ref, actualImage: act, config: customConfig)
            self.diffResult = result
        } catch {
            self.errorMessage = "Analysis Failed: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
    
    private func loadDemoImages() {
        let size = CGSize(width: 800, height: 600)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // 1. Create Reference Synthetic Image
        let refCtx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        refCtx.setFillColor(NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).cgColor)
        refCtx.fill(CGRect(origin: .zero, size: size))
        refCtx.setFillColor(NSColor.systemBlue.cgColor)
        refCtx.fill(CGRect(x: 100, y: 400, width: 600, height: 80))
        refCtx.setFillColor(NSColor.systemPurple.cgColor)
        refCtx.fill(CGRect(x: 100, y: 200, width: 280, height: 160))
        refCtx.fill(CGRect(x: 420, y: 200, width: 280, height: 160))
        
        // 2. Create Actual Synthetic Image (with deliberate shift for diff testing)
        let actCtx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        actCtx.setFillColor(NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).cgColor)
        actCtx.fill(CGRect(origin: .zero, size: size))
        actCtx.setFillColor(NSColor.systemBlue.cgColor)
        actCtx.fill(CGRect(x: 100, y: 380, width: 600, height: 80)) // shifted 20px
        actCtx.setFillColor(NSColor.systemPurple.cgColor)
        actCtx.fill(CGRect(x: 100, y: 200, width: 280, height: 160))
        actCtx.setFillColor(NSColor.systemOrange.cgColor) // color shifted
        actCtx.fill(CGRect(x: 420, y: 200, width: 280, height: 160))
        
        if let refCG = refCtx.makeImage(), let actCG = actCtx.makeImage() {
            let refImg = NSImage(cgImage: refCG, size: size)
            let actImg = NSImage(cgImage: actCG, size: size)
            
            self.referenceImage = refImg
            self.actualImage = actImg
            checkAutoAnalyze()
        }
    }
    
    // MARK: - Export Methods
    
    private func exportHTML(_ result: DiffResult) {
        let html = exporter.exportHTML(result: result)
        saveToFile(content: html, defaultName: "DesignLens_Report.html")
    }
    
    private func exportMarkdown(_ result: DiffResult) {
        let md = exporter.exportMarkdown(result: result)
        saveToFile(content: md, defaultName: "DesignLens_Summary.md")
    }
    
    private func exportJSON(_ result: DiffResult) {
        do {
            let data = try exporter.exportJSON(result: result)
            if let jsonString = String(data: data, encoding: .utf8) {
                saveToFile(content: jsonString, defaultName: "DesignLens_Data.json")
            }
        } catch {
            errorMessage = "Export JSON Error: \(error.localizedDescription)"
        }
    }
    
    private func saveToFile(content: String, defaultName: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = defaultName
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                showToast("Saved report to \(url.lastPathComponent)")
            } catch {
                errorMessage = "Failed to write file: \(error.localizedDescription)"
            }
        }
    }
    
    private func showToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            exportNotification = text
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                exportNotification = nil
            }
        }
    }
}
