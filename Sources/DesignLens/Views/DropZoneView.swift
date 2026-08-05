import SwiftUI
import AppKit
import UniformTypeIdentifiers

public enum DropZoneType: String, CaseIterable, Identifiable {
    case reference = "Reference Design"
    case actual = "Actual Implementation"
    case customConfig = "Design System JSON"
    
    public var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .reference: return "doc.richtext.fill"
        case .actual: return "macwindow.on.rectangle"
        case .customConfig: return "slider.horizontal.3"
        }
    }
}

public struct DropZoneView: View {
    public let type: DropZoneType
    public let title: String
    public let subtitle: String
    public let image: NSImage?
    public let config: DesignSystemConfig?
    public let onImageSelected: ((NSImage?) -> Void)?
    public let onConfigSelected: ((DesignSystemConfig?) -> Void)?
    
    @State private var isTargeted: Bool = false
    
    public init(
        type: DropZoneType,
        title: String? = nil,
        subtitle: String? = nil,
        image: NSImage? = nil,
        config: DesignSystemConfig? = nil,
        onImageSelected: ((NSImage?) -> Void)? = nil,
        onConfigSelected: ((DesignSystemConfig?) -> Void)? = nil
    ) {
        self.type = type
        self.title = title ?? type.rawValue
        self.subtitle = subtitle ?? (type == .customConfig ? "Drop custom JSON config file" : "Drop PNG/JPG screenshot")
        self.image = image
        self.config = config
        self.onImageSelected = onImageSelected
        self.onConfigSelected = onConfigSelected
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if type == .customConfig {
                configCardView
            } else if let nsImage = image {
                loadedImagePreviewView(nsImage)
            } else {
                emptyDropzoneView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL, .json, .image], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyDropzoneView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0).opacity(0.2) : Color.white.opacity(0.04))
                    .frame(width: 52, height: 52)
                
                Image(systemName: isTargeted ? "arrow.down.doc.fill" : type.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color(red: 0.6, green: 0.65, blue: 0.75))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                selectFileWithOpenPanel()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: type == .customConfig ? "gearshape" : "folder")
                    Text(type == .customConfig ? "Browse JSON Config..." : "Browse Image...")
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(red: 0.17, green: 0.50, blue: 1.0))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Text(type == .customConfig ? "Supports .json Design Systems" : "Supports PNG, JPG, JPEG")
                .font(.system(size: 10))
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(18)
        .background(Color(red: 0.10, green: 0.12, blue: 0.17))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color(red: 0.17, green: 0.21, blue: 0.28),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: [6, 4])
                )
        )
        .cornerRadius(10)
    }
    
    private var configCardView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color(red: 0.66, green: 0.33, blue: 0.97))
                    Text(config?.name ?? "Default Design System")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if config != nil && config != DesignSystemConfig.loadDefault() {
                    Button {
                        onConfigSelected?(nil)
                    } label: {
                        Text("Reset to Default")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let sys = config {
                HStack(spacing: 12) {
                    Label("\(sys.typography.count) Font Tokens", systemImage: "textformat")
                    Label("\(sys.spacingTokens.count) Spacing Tokens", systemImage: "arrow.left.and.right")
                    Label("±\(Int(sys.tolerances.spacingPx))px Tol", systemImage: "checkmark.shield")
                }
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
            }
            
            Button {
                selectFileWithOpenPanel()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Load Custom JSON Config...")
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(red: 0.10, green: 0.12, blue: 0.17))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.17, green: 0.21, blue: 0.28), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    private func loadedImagePreviewView(_ nsImage: NSImage) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(nsImage.size.width))x\(Int(nsImage.size.height)) px")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            
            Button {
                onImageSelected?(nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.white.opacity(0.8))
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.10, green: 0.12, blue: 0.17))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.17, green: 0.21, blue: 0.28), lineWidth: 1)
        )
        .cornerRadius(10)
    }
    
    // MARK: - Handlers
    
    private func selectFileWithOpenPanel() {
        let panel = NSOpenPanel()
        if type == .customConfig {
            panel.allowedContentTypes = [.json]
        } else {
            panel.allowedContentTypes = [.png, .jpeg]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            processURL(url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    
                    DispatchQueue.main.async {
                        processURL(url)
                    }
                }
                return true
            } else if type != .customConfig && provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                    if let nsImage = image as? NSImage {
                        DispatchQueue.main.async {
                            onImageSelected?(nsImage)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func processURL(_ url: URL) {
        if type == .customConfig || url.pathExtension.lowercased() == "json" {
            do {
                let data = try Data(contentsOf: url)
                let decodedConfig = try JSONDecoder().decode(DesignSystemConfig.self, from: data)
                onConfigSelected?(decodedConfig)
            } catch {
                print("Failed to decode JSON design system config: \(error)")
            }
        } else if let image = NSImage(contentsOf: url) {
            onImageSelected?(image)
        }
    }
}
