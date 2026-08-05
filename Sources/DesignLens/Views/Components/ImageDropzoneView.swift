import SwiftUI
import AppKit

public struct ImageDropzoneView: View {
    public let title: String
    public let subtitle: String
    public let image: NSImage?
    public let onImageSelected: (NSImage?) -> Void
    
    @State private var isTargeted: Bool = false
    
    public init(
        title: String,
        subtitle: String,
        image: NSImage?,
        onImageSelected: @escaping (NSImage?) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.onImageSelected = onImageSelected
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let nsImage = image {
                loadedPreviewView(nsImage)
            } else {
                emptyDropzoneView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL, .image], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyDropzoneView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0).opacity(0.2) : Color.white.opacity(0.04))
                    .frame(width: 56, height: 56)
                
                Image(systemName: isTargeted ? "arrow.down.doc.fill" : "photo.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color(red: 0.6, green: 0.65, blue: 0.75))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
            }
            
            Button {
                selectFileWithOpenPanel()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("Browse Image...")
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(red: 0.17, green: 0.50, blue: 1.0))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Text("Supports PNG, JPG, JPEG")
                .font(.system(size: 10))
                .foregroundColor(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(Color(red: 0.09, green: 0.11, blue: 0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isTargeted ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: [6, 4])
                )
        )
        .cornerRadius(12)
    }
    
    private func loadedPreviewView(_ nsImage: NSImage) -> some View {
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
            
            // Clear Button
            Button {
                onImageSelected(nil)
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
        .background(Color(red: 0.09, green: 0.11, blue: 0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Actions & Drop Handlers
    
    private func selectFileWithOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                onImageSelected(image)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          let image = NSImage(contentsOf: url) else { return }
                    
                    DispatchQueue.main.async {
                        onImageSelected(image)
                    }
                }
                return true
            } else if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                    if let nsImage = image as? NSImage {
                        DispatchQueue.main.async {
                            onImageSelected(nsImage)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
