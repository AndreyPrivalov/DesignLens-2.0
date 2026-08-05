import SwiftUI
import AppKit

public struct InspectorView: View {
    public let diffResult: DiffResult?
    @Binding public var selectedDiffId: UUID?
    
    @State private var selectedFilter: LayoutDiffItem.Severity? = nil
    
    public init(diffResult: DiffResult?, selectedDiffId: Binding<UUID?>) {
        self.diffResult = diffResult
        self._selectedDiffId = selectedDiffId
    }
    
    public var filteredItems: [LayoutDiffItem] {
        guard let items = diffResult?.diffItems else { return [] }
        guard let filter = selectedFilter else { return items }
        return items.filter { $0.severity == filter }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header & Severity Filter Chips
            inspectorHeader
                .padding(14)
                .background(Color(red: 0.11, green: 0.14, blue: 0.19))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Discrepancy List
            if let result = diffResult, !result.diffItems.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            discrepancyRow(item)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDiffId = item.id
                                    }
                                }
                        }
                    }
                    .padding(10)
                }
            } else if diffResult != nil {
                emptyMatchState
            } else {
                noAnalysisState
            }
            
            // Detailed Inspector Footer Card for selected item
            if let selectedItem = selectedDiffItem {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                selectedItemDetailCard(selectedItem)
                    .padding(12)
                    .background(Color(red: 0.10, green: 0.12, blue: 0.17))
            }
        }
        .frame(minWidth: 320, maxWidth: 380)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
    }
    
    // MARK: - Subviews
    
    private var selectedDiffItem: LayoutDiffItem? {
        guard let selectedId = selectedDiffId, let items = diffResult?.diffItems else { return nil }
        return items.first(where: { $0.id == selectedId })
    }
    
    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DISCREPANCY INSPECTOR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                    .tracking(0.8)
                
                Spacer()
                
                if let count = diffResult?.diffItems.count {
                    Text("\(count) issues")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
            }
            
            // Filter Filter Chips
            HStack(spacing: 6) {
                filterChip(title: "All", count: diffResult?.diffItems.count ?? 0, severity: nil)
                filterChip(title: "Critical", count: count(for: .critical), severity: .critical)
                filterChip(title: "Warning", count: count(for: .warning), severity: .warning)
                filterChip(title: "Info", count: count(for: .info), severity: .info)
            }
        }
    }
    
    private func count(for severity: LayoutDiffItem.Severity) -> Int {
        diffResult?.diffItems.filter { $0.severity == severity }.count ?? 0
    }
    
    private func severityColor(_ severity: LayoutDiffItem.Severity) -> Color {
        switch severity {
        case .critical: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .warning:  return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .info:     return Color(red: 0.23, green: 0.51, blue: 0.96)
        }
    }
    
    private func filterChip(title: String, count: Int, severity: LayoutDiffItem.Severity?) -> some View {
        let isSelected = selectedFilter == severity
        let chipColor: Color
        switch severity {
        case .critical: chipColor = Color(red: 0.94, green: 0.27, blue: 0.27)
        case .warning:  chipColor = Color(red: 0.96, green: 0.62, blue: 0.04)
        case .info:     chipColor = Color(red: 0.23, green: 0.51, blue: 0.96)
        case nil:       chipColor = Color(red: 0.17, green: 0.50, blue: 1.0)
        }
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilter = severity
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.3) : chipColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? chipColor : Color.white.opacity(0.06))
            .foregroundColor(isSelected ? .white : Color(red: 0.8, green: 0.85, blue: 0.9))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func discrepancyRow(_ item: LayoutDiffItem) -> some View {
        let isSelected = selectedDiffId == item.id
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Severity Dot
                Circle()
                    .fill(severityColor(item.severity))
                    .frame(width: 8, height: 8)
                
                Text(item.elementName)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Category Badge
                Text(item.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))
                    .cornerRadius(4)
            }
            
            Text(item.title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.85, green: 0.88, blue: 0.92))
                .lineLimit(2)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Ref:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                    Text(item.referenceValue)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.4, green: 0.85, blue: 0.6))
                }
                
                HStack(spacing: 4) {
                    Text("Act:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.gray)
                    Text(item.actualValue)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.45))
                }
                
                if let delta = item.delta {
                    Spacer()
                    Text("Δ \(String(format: "%.1f", delta))\(item.unit)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor(item.severity))
                }
            }
        }
        .padding(10)
        .background(isSelected ? Color(red: 0.17, green: 0.50, blue: 1.0).opacity(0.18) : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(red: 0.17, green: 0.50, blue: 1.0) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
        )
        .cornerRadius(8)
    }
    
    private func selectedItemDetailCard(_ item: LayoutDiffItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SELECTED ELEMENT DETAILS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                    .tracking(0.6)
                
                Spacer()
                
                Button {
                    selectedDiffId = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
            
            Text(item.issueDescription)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.85, green: 0.88, blue: 0.92))
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REF BOUNDS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.gray)
                    Text("\(Int(item.boundingBox.origin.x)), \(Int(item.boundingBox.origin.y)) (\(Int(item.boundingBox.width))x\(Int(item.boundingBox.height)))")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                if let actBox = item.actualBoundingBox {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACT BOUNDS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.gray)
                        Text("\(Int(actBox.origin.x)), \(Int(actBox.origin.y)) (\(Int(actBox.width))x\(Int(actBox.height)))")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var emptyMatchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0.06, green: 0.72, blue: 0.51))
            
            Text("Perfect Match!")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text("No layout or visual discrepancies were detected between the reference and implementation.")
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noAnalysisState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No Analysis Data")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.gray)
            
            Text("Load reference and actual screenshots, then click 'Run Comparison'.")
                .font(.system(size: 11))
                .foregroundColor(Color.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
