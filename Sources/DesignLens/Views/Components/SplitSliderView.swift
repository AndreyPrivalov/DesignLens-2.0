import SwiftUI
import AppKit

public struct SplitSliderView: View {
    public let referenceImage: NSImage?
    public let actualImage: NSImage?
    @Binding public var sliderPosition: CGFloat
    
    @State private var isDragging: Bool = false
    
    public init(
        referenceImage: NSImage?,
        actualImage: NSImage?,
        sliderPosition: Binding<CGFloat>
    ) {
        self.referenceImage = referenceImage
        self.actualImage = actualImage
        self._sliderPosition = sliderPosition
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let splitX = width * max(0.0, min(1.0, sliderPosition))
            
            ZStack(alignment: .leading) {
                // Background & Reference Image
                Color(nsColor: NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1.0))
                    .edgesIgnoringSafeArea(.all)
                
                if let refImg = referenceImage {
                    Image(nsImage: refImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                } else {
                    placeholderView(title: "Reference Image Missing")
                }
                
                // Actual Image Clipped to Left Portion (up to splitX)
                if let actImg = actualImage {
                    Image(nsImage: actImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: splitX)
                                Spacer(minLength: 0)
                            }
                        )
                }
                
                // Split Line Divider & Handle
                ZStack(alignment: .center) {
                    // Divider Line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.17, green: 0.5, blue: 1.0),
                                    Color(red: 0.66, green: 0.33, blue: 0.97)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 0)
                    
                    // Handle Pill
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.1, green: 0.13, blue: 0.18).opacity(0.85))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isDragging ? Color(red: 0.17, green: 0.5, blue: 1.0) : Color.white.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
                }
                .offset(x: splitX - 1.5)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let newPos = gesture.location.x / max(1.0, width)
                            sliderPosition = max(0.0, min(1.0, newPos))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                
                // Overlay Header Labels
                VStack {
                    HStack {
                        // Left Label (Actual)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: 0.66, green: 0.33, blue: 0.97))
                                .frame(width: 8, height: 8)
                            Text("Actual UI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow))
                        .cornerRadius(6)
                        .padding(.leading, 12)
                        
                        Spacer()
                        
                        // Right Label (Reference)
                        HStack(spacing: 6) {
                            Text("Reference UI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Circle()
                                .fill(Color(red: 0.17, green: 0.5, blue: 1.0))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow))
                        .cornerRadius(6)
                        .padding(.trailing, 12)
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private func placeholderView(title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36))
                .foregroundColor(Color.gray.opacity(0.5))
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper for NSVisualEffectView glassmorphism in SwiftUI
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    
    public init(
        material: NSVisualEffectView.Material = .headerView,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
