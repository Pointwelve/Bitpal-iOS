//
//  CurrencyDetailComponents.swift
//  Bitpal-v2
//
//  Created by Claude on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Modern Price Display

struct ModernPriceDisplay: View {
    let currentPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
    let flashColor: Color?
    let onPriceChange: ((Double) -> Void)?
    
    @State private var isFlashing = false
    @State private var lastPrice: Double = 0
    
    private var isPositive: Bool {
        priceChangePercent >= 0
    }
    
    private var changeColor: Color {
        isPositive ? .green : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main price display - cleaner without sparkline
            Text(CurrencyFormatter.formatPriceCompact(currentPrice))
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(isFlashing ? flashColor ?? .primary : .primary)
                .scaleEffect(isFlashing ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isFlashing)
                .minimumScaleFactor(0.8) // Allow scaling down to prevent wrapping
                .lineLimit(1)
                .onChange(of: currentPrice) { oldValue, newValue in
                    if oldValue != newValue && oldValue > 0 {
                        triggerFlash()
                        onPriceChange?(newValue)
                    }
                }
            
            // Price change badge
            HStack(spacing: 8) {
                PriceChangeBadge(
                    change: priceChange,
                    changePercent: priceChangePercent,
                    isPositive: isPositive
                )
                
                Spacer()
                
                Text("24h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func triggerFlash() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isFlashing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isFlashing = false
            }
        }
    }
}

// MARK: - Price Change Badge

struct PriceChangeBadge: View {
    let change: Double
    let changePercent: Double
    let isPositive: Bool
    
    private var changeColor: Color {
        isPositive ? .green : .red
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.caption2)
                .fontWeight(.semibold)
            
            Text("\(CurrencyFormatter.formatCurrencyEnhanced(abs(change))) (\(String(format: "%.2f", abs(changePercent)))%)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(changeColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(changeColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Sparkline View (Removed for cleaner design)

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    let currencyPair: CurrencyPair
    let onAddAlert: () -> Void
    let onToggleWatchlist: () -> Void
    let onAddToPortfolio: () -> Void
    let onShare: () -> Void
    
    @State private var isInWatchlist = false
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "bell",
                title: "Alert",
                action: onAddAlert
            )
            
            QuickActionButton(
                icon: isInWatchlist ? "star.fill" : "star",
                title: "Watch",
                isSelected: isInWatchlist,
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isInWatchlist.toggle()
                    }
                    onToggleWatchlist()
                }
            )
            
            QuickActionButton(
                icon: "briefcase",
                title: "Portfolio",
                action: onAddToPortfolio
            )
            
            QuickActionButton(
                icon: "square.and.arrow.up",
                title: "Share",
                action: onShare
            )
        }
        .padding(.horizontal, 20)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color(.systemGray6))
                    )
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Horizontal Stat Cards

struct HorizontalStatCards: View {
    let currencyPair: CurrencyPair
    
    private var stats: [StatItem] {
        [
            StatItem(
                title: "Market Cap",
                value: "41,375.00 BTC",
                icon: "chart.pie"
            ),
            StatItem(
                title: "24h Volume",
                value: CurrencyFormatter.formatCurrencyEnhanced(98669.59),
                icon: "arrow.up.arrow.down"
            ),
            StatItem(
                title: "Circulating Supply",
                value: "17.332.275",
                icon: "circle.grid.2x2"
            ),
            StatItem(
                title: "24h High",
                value: CurrencyFormatter.formatCurrencyEnhanced(11669.59),
                icon: "arrow.up.circle",
                isPositive: true
            ),
            StatItem(
                title: "24h Low",
                value: CurrencyFormatter.formatCurrencyEnhanced(8669.59),
                icon: "arrow.down.circle",
                isPositive: false
            ),
            StatItem(
                title: "All Time High",
                value: CurrencyFormatter.formatCurrencyEnhanced(69000.00),
                icon: "crown"
            )
        ]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(stats, id: \.title) { stat in
                    ModernStatCard(stat: stat)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct StatItem {
    let title: String
    let value: String
    let icon: String
    var isPositive: Bool? = nil
}

struct ModernStatCard: View {
    let stat: StatItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let isPositive = stat.isPositive {
                    Circle()
                        .fill(isPositive ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(stat.value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140, height: 80)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Header

struct ModernDetailHeader: View {
    let currencyPair: CurrencyPair
    let onBack: () -> Void
    let onMenu: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemGray6)))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(currencyPair.baseCurrency?.symbol ?? "N/A")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(currencyPair.baseCurrency?.name ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onMenu) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.systemGray6)))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Enhanced Chart Header

struct EnhancedChartHeader: View {
    @Binding var chartType: ChartDisplayType
    let onExpand: () -> Void
    
    var body: some View {
        HStack {
            Text("Price Chart")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        chartType = chartType == .line ? .candlestick : .line
                    }
                }) {
                    Image(systemName: chartType.systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(chartType == .candlestick ? .white : .secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(chartType == .candlestick ? Color.blue : Color(.systemGray5))
                        )
                }
                
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                }
            }
        }
    }
}

// MARK: - Price Alerts Section

struct PriceAlertsSection: View {
    let currencyPair: CurrencyPair
    let onAddAlert: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price Alerts")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Get notified when price reaches your target")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onAddAlert) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.blue))
                }
            }
            
            // Placeholder for active alerts
            AlertPlaceholderView()
        }
        .padding(.horizontal, 20)
    }
}

struct AlertPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No active alerts")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Set price alerts to stay informed about market movements")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}