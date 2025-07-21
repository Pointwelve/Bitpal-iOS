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

// MARK: - Chart Selection Overlay

@ChartContentBuilder
func ChartSelectionOverlay(selectedDataPoint: ChartData?, chartType: ChartDisplayType) -> some ChartContent {
    if let selected = selectedDataPoint {
        // Vertical crosshair line
        RuleMark(x: .value("Time", selected.date))
            .foregroundStyle(.primary.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
        
        // Horizontal crosshair line
        RuleMark(y: .value("Price", selected.close))
            .foregroundStyle(.primary.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
        
        // Enhanced selection point with multiple layers
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(.white)
        .symbolSize(150)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(.blue)
        .symbolSize(100)
        
        PointMark(
            x: .value("Time", selected.date),
            y: .value("Price", selected.close)
        )
        .foregroundStyle(.white)
        .symbolSize(50)
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
            Text(dataPoint.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Close:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.formatCurrencyEnhanced(dataPoint.close))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                if dataPoint.open != dataPoint.close {
                    HStack {
                        Text("Open:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(CurrencyFormatter.formatCurrencyEnhanced(dataPoint.open))
                            .font(.caption2)
                    }
                }
                
                if dataPoint.high != dataPoint.low {
                    HStack {
                        Text("Range:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(CurrencyFormatter.formatCurrencyEnhanced(dataPoint.low)) - \(CurrencyFormatter.formatCurrencyEnhanced(dataPoint.high))")
                            .font(.caption2)
                    }
                }
            }
            
            if dataPoint.isPositive {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("+\(CurrencyFormatter.formatCurrencyEnhanced(abs(dataPoint.priceChange)).replacingOccurrences(of: "$", with: ""))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else if dataPoint.priceChange < 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("-\(CurrencyFormatter.formatCurrencyEnhanced(abs(dataPoint.priceChange)).replacingOccurrences(of: "$", with: ""))")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary.opacity(0.1), lineWidth: 0.5)
        )
        .frame(width: 130)
        .overlay(
            Triangle()
                .fill(.regularMaterial)
                .frame(width: 12, height: 8)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                .rotationEffect(pointerRotation),
            alignment: pointerAlignment
        )
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