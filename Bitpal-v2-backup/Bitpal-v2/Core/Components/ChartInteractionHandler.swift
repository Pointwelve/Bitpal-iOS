//
//  ChartInteractionHandler.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 21/7/25.
//

import SwiftUI
import Charts

// MARK: - Chart Interaction State

@Observable
class ChartInteractionState {
    var selectedDataPoint: ChartData?
    var showCrosshair = false
    var crosshairPosition: CGPoint = .zero
    var dragLocation: CGPoint = .zero
    var isDragging = false
    
    private var lastHapticTime: Date = Date()
    private var lastSelectionTime: Date = Date()
    
    // Performance optimization: Haptic feedback generators
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    init() {
        setupHaptics()
    }
    
    private func setupHaptics() {
        lightImpactGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func handleChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy, data: [ChartData]) {
        let now = Date()
        guard now.timeIntervalSince(lastSelectionTime) > ChartConfiguration.selectionDebounceInterval else { return }
        lastSelectionTime = now
        
        handleChartSelection(location: location, geometry: geometry, proxy: proxy, data: data)
        
        if now.timeIntervalSince(lastHapticTime) > ChartConfiguration.hapticThrottleInterval {
            lightImpactGenerator.impactOccurred()
            lastHapticTime = now
        }
    }
    
    func handleChartDrag(value: DragGesture.Value, geometry: GeometryProxy, proxy: ChartProxy, data: [ChartData]) {
        let now = Date()
        let previousSelection = selectedDataPoint
        
        isDragging = true
        
        guard now.timeIntervalSince(lastSelectionTime) > ChartConfiguration.selectionDebounceInterval else { return }
        lastSelectionTime = now
        
        handleChartSelectionImmediate(location: value.location, geometry: geometry, proxy: proxy, data: data)
        dragLocation = value.location
        
        if let newSelection = selectedDataPoint,
           previousSelection?.id != newSelection.id,
           now.timeIntervalSince(lastHapticTime) > ChartConfiguration.hapticThrottleInterval {
            selectionGenerator.selectionChanged()
            lastHapticTime = now
        }
    }
    
    func handleDragEnd() {
        isDragging = false
        lightImpactGenerator.prepare()
        selectionGenerator.prepare()
        
        withAnimation(.easeOut(duration: 0.3)) {
            showCrosshair = false
            selectedDataPoint = nil // Reset chart selection
        }
    }
    
    private func handleChartSelection(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy, data: [ChartData]) {
        let plotFrame = geometry.frame(in: .local)
        let relativeXPosition = location.x - plotFrame.origin.x
        
        guard let plotValue = proxy.value(atX: relativeXPosition, as: Date.self), !data.isEmpty else {
            return
        }
        
        let closest = ChartDataProcessor.findClosestDataPoint(in: data, to: plotValue)
        
        if closest?.id != selectedDataPoint?.id {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.9)) {
                selectedDataPoint = closest
            }
        }
    }
    
    private func handleChartSelectionImmediate(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy, data: [ChartData]) {
        let plotFrame = geometry.frame(in: .local)
        let relativeXPosition = location.x - plotFrame.origin.x
        
        guard let plotValue = proxy.value(atX: relativeXPosition, as: Date.self), !data.isEmpty else {
            return
        }
        
        let closest = ChartDataProcessor.findClosestDataPoint(in: data, to: plotValue)
        
        if closest?.id != selectedDataPoint?.id {
            selectedDataPoint = closest  // No animation during drag
        }
    }
    
    func clearSelection() {
        selectedDataPoint = nil
        showCrosshair = false
        dragLocation = .zero
        isDragging = false
    }
}

// MARK: - Chart Selection Overlay with iOS 26 Liquid Glass

@ChartContentBuilder
func ChartSelectionOverlay(selectedDataPoint: ChartData?, chartType: ChartDisplayType) -> some ChartContent {
    if let selected = selectedDataPoint {
        // Subtle liquid glass vertical guide line
        RuleMark(x: .value("Time", selected.date))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.15),
                        .gray.opacity(0.1),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        
        // Outer liquid glass aura
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(
            RadialGradient(
                colors: [
                    .white.opacity(0.2),
                    .white.opacity(0.1),
                    .gray.opacity(0.05),
                    .clear
                ],
                center: .center,
                startRadius: 5,
                endRadius: 25
            )
        )
        .symbolSize(400) // Soft liquid glass glow
        
        // Main liquid glass ring
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(.white.opacity(0.4))
        .symbolSize(100)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        
        // Inner glass ring with subtle gradient
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [
                    .white.opacity(0.6),
                    .gray.opacity(0.3),
                    .white.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .symbolSize(50)
        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
        
        // Central liquid glass point
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(.white.opacity(0.9))
        .symbolSize(16)
        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Chart Interaction Area

struct ChartInteractionArea: View {
    @State var interactionState: ChartInteractionState
    let geometry: GeometryProxy
    let proxy: ChartProxy
    let data: [ChartData]
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { location in
                interactionState.handleChartTap(
                    location: location,
                    geometry: geometry,
                    proxy: proxy,
                    data: data
                )
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        interactionState.handleChartDrag(
                            value: value,
                            geometry: geometry,
                            proxy: proxy,
                            data: data
                        )
                    }
                    .onEnded { _ in
                        interactionState.handleDragEnd()
                    }
            )
    }
}

// MARK: - Floater Position

enum FloaterPosition {
    case topLeft, topRight, bottomLeft, bottomRight
    
    var offset: (x: CGFloat, y: CGFloat) {
        switch self {
        case .topLeft: return (-140, -100)
        case .topRight: return (20, -100)
        case .bottomLeft: return (-140, 20)
        case .bottomRight: return (20, 20)
        }
    }
    
    var description: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

// MARK: - Chart Floater View

struct ChartFloaterView: View {
    let dataPoint: ChartData
    let currencyPair: CurrencyPair
    let position: FloaterPosition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Compact date with enhanced styling
            Text(dataPoint.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption2)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // Main price - most important info
            Text(CurrencyFormatter.formatCurrencyEnhanced(dataPoint.close))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Price change if significant
            if abs(dataPoint.priceChange) > 0.01 {
                HStack(spacing: 3) {
                    Image(systemName: dataPoint.isPositive ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(dataPoint.isPositive ? .green : .red)
                    Text("\(dataPoint.isPositive ? "+" : "")\(String(format: "%.2f", dataPoint.priceChange))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(dataPoint.isPositive ? .green : .red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            // Glass morphism effect
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    // Subtle glass border
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .frame(width: 120)
    }
    
    private var pointerAlignment: Alignment {
        switch position {
        case .topLeft, .topRight:
            return .bottom
        case .bottomLeft, .bottomRight:
            return .top
        }
    }
    
    private var pointerRotation: Angle {
        switch position {
        case .topLeft, .topRight:
            return .degrees(180)
        case .bottomLeft, .bottomRight:
            return .degrees(0)
        }
    }
}