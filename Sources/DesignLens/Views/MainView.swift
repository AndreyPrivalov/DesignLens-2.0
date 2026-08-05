import SwiftUI
import AppKit

public struct MainView: View {
    @State private var referenceImage: NSImage? = nil
    @State private var actualImage: NSImage? = nil
    @State private var diffResult: DiffResult? = nil
    @State private var selectedDiffId: UUID? = nil
    @State private var isAnalyzing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var exportNotification: String? = nil
    
    private let analyzer = ImageAnalyzer()
    private let exporter = ReportExporter()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Navigation Header Bar
            headerBar
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Main Content Area (Canvas + Inspector Sidebar)
            HSplitView {
                // Left Area: Dropzones or Interactive Canvas
                ZStack {
                    Color(red: 0.07, green: 0.09, blue: 0.12)
                        .edgesIgnoringSafeArea(.all)
                    
                    if referenceImage == nil || actualImage == nil {
                        imageSetupDropzones
                            .padding(24)
                    } else if isAnalyzing {
                        analyzingProgressView
                    } else {
                        OverlayView(
                            referenceImage: referenceImage,
                            actualImage: actualImage,
                            diffResult: diffResult,
                            selectedDiffId: $selectedDiffId
                        )
                    }
                    
                    if let notification = exportNotification {
                        notificationToast(notification)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Right Area: Inspector Sidebar
                InspectorView(
                    diffResult: diffResult,
                    selectedDiffId: $selectedDiffId
                )
            }
        }
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Subviews
    
    private var headerBar: some View {
        HStack(spacing: 16) {
            // App Title & Logo
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
                    Text("2.0 Visual QA")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                }
            }
            
            Spacer()
            
            // Score Summary Pill (When analyzed)
            if let result = diffResult {
                matchScoreBadge(result)
            }
            
            // Action Button: Run Comparison
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
            
            // Export Menu
            if let result = diffResult {
                Menu {
                    Button("Export HTML Report...") {
                        exportReportHTML(result)
                    }
                    Button("Export Markdown Summary...") {
                        exportReportMarkdown(result)
                    }
                    Button("Export Raw JSON Data...") {
                        exportReportJSON(result)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Report")
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
            
            // Reset Workspace Button
            if referenceImage != nil || actualImage != nil {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.10, green: 0.12, blue: 0.17))
    }
    
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
    
    private var imageSetupDropzones: some View {
        HStack(spacing: 20) {
            ImageDropzoneView(
                title: "Reference Design Spec",
                subtitle: "Upload baseline design or Figma export",
                image: referenceImage
            ) { image in
                referenceImage = image
                checkAutoAnalyze()
            }
            
            ImageDropzoneView(
                title: "Actual Implementation",
                subtitle: "Upload screenshot of build / app",
                image: actualImage
            ) { image in
                actualImage = image
                checkAutoAnalyze()
            }
        }
    }
    
    private var analyzingProgressView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)
            
            Text("Segmenting Blocks & Analyzing Layout...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.8, green: 0.85, blue: 0.9))
            
            Text("Vision Engine processing element coordinates, typography, and color shifts.")
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
        }
    }
    
    private func notificationToast(_ text: String) -> some View {
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
    
    // MARK: - Engine Handlers
    
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
            let result = try await analyzer.analyze(referenceImage: ref, actualImage: act)
            self.diffResult = result
        } catch {
            self.errorMessage = "Analysis Failed: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Export Handlers
    
    private func exportReportHTML(_ result: DiffResult) {
        let htmlContent = exporter.exportHTML(result: result)
        saveToFile(content: htmlContent, defaultName: "DesignLens_Report.html", allowedType: "html")
    }
    
    private func exportReportMarkdown(_ result: DiffResult) {
        let mdContent = exporter.exportMarkdown(result: result)
        saveToFile(content: mdContent, defaultName: "DesignLens_Summary.md", allowedType: "md")
    }
    
    private func exportReportJSON(_ result: DiffResult) {
        do {
            let jsonData = try exporter.exportJSON(result: result)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                saveToFile(content: jsonString, defaultName: "DesignLens_Data.json", allowedType: "json")
            }
        } catch {
            errorMessage = "JSON Export Failed: \(error.localizedDescription)"
        }
    }
    
    private func saveToFile(content: String, defaultName: String, allowedType: String) {
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
    
    private func showToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            exportNotification = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                exportNotification = nil
            }
        }
    }
}
