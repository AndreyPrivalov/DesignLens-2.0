import Foundation

public struct DesignSystemConfig: Codable, Sendable, Equatable {
    public struct Colors: Codable, Sendable, Equatable {
        public let primaryAccent: String
        public let secondaryAccent: String
        public let success: String
        public let warning: String
        public let error: String
        public let background: String
        public let surfaceCard: String
        public let borderDivider: String
        
        public init(
            primaryAccent: String,
            secondaryAccent: String,
            success: String,
            warning: String,
            error: String,
            background: String,
            surfaceCard: String,
            borderDivider: String
        ) {
            self.primaryAccent = primaryAccent
            self.secondaryAccent = secondaryAccent
            self.success = success
            self.warning = warning
            self.error = error
            self.background = background
            self.surfaceCard = surfaceCard
            self.borderDivider = borderDivider
        }
    }
    
    public struct TypographyToken: Codable, Sendable, Equatable, Identifiable {
        public var id: String { name }
        public let name: String
        public let expectedSize: Double
        public let expectedWeight: String
        public let isMonospace: Bool?
        public let tolerancePt: Double
        
        public init(
            name: String,
            expectedSize: Double,
            expectedWeight: String,
            isMonospace: Bool? = nil,
            tolerancePt: Double = 1.0
        ) {
            self.name = name
            self.expectedSize = expectedSize
            self.expectedWeight = expectedWeight
            self.isMonospace = isMonospace
            self.tolerancePt = tolerancePt
        }
    }
    
    public struct Tolerances: Codable, Sendable, Equatable {
        public let spacingPx: Double
        public let dimensionPx: Double
        public let colorDeltaE: Double
        
        public init(spacingPx: Double = 2.0, dimensionPx: Double = 2.0, colorDeltaE: Double = 5.0) {
            self.spacingPx = spacingPx
            self.dimensionPx = dimensionPx
            self.colorDeltaE = colorDeltaE
        }
    }
    
    public let name: String
    public let version: String
    public let colors: Colors
    public let typography: [TypographyToken]
    public let spacingTokens: [Double]
    public let cornerRadiusTokens: [Double]
    public let tolerances: Tolerances
    
    public init(
        name: String,
        version: String,
        colors: Colors,
        typography: [TypographyToken],
        spacingTokens: [Double],
        cornerRadiusTokens: [Double],
        tolerances: Tolerances
    ) {
        self.name = name
        self.version = version
        self.colors = colors
        self.typography = typography
        self.spacingTokens = spacingTokens
        self.cornerRadiusTokens = cornerRadiusTokens
        self.tolerances = tolerances
    }
    
    public static func loadDefault() -> DesignSystemConfig {
        if let url = Bundle.module.url(forResource: "default_design_system", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(DesignSystemConfig.self, from: data) {
            return decoded
        }
        return fallbackDefault
    }
    
    public static func load(from url: URL) throws -> DesignSystemConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DesignSystemConfig.self, from: data)
    }
    
    public static var fallbackDefault: DesignSystemConfig {
        DesignSystemConfig(
            name: "Default Fallback System",
            version: "1.0.0",
            colors: Colors(
                primaryAccent: "#2B7FFF",
                secondaryAccent: "#A855F7",
                success: "#10B981",
                warning: "#F59E0B",
                error: "#EF4444",
                background: "#12161F",
                surfaceCard: "#1A202C",
                borderDivider: "#2D3748"
            ),
            typography: [
                TypographyToken(name: "Header Large", expectedSize: 22.0, expectedWeight: "Bold", tolerancePt: 2.0),
                TypographyToken(name: "Section Title", expectedSize: 16.0, expectedWeight: "Semibold", tolerancePt: 1.5),
                TypographyToken(name: "Body Text", expectedSize: 13.0, expectedWeight: "Regular", tolerancePt: 1.0),
                TypographyToken(name: "Monospace Code", expectedSize: 12.0, expectedWeight: "Medium", isMonospace: true, tolerancePt: 1.0),
                TypographyToken(name: "Caption / Badge", expectedSize: 11.0, expectedWeight: "Bold", tolerancePt: 1.0)
            ],
            spacingTokens: [4.0, 8.0, 12.0, 16.0, 20.0, 24.0, 32.0, 48.0, 64.0],
            cornerRadiusTokens: [6.0, 10.0, 16.0],
            tolerances: Tolerances()
        )
    }
}
