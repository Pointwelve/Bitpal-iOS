//
//  CoinDetailView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI
import SwiftData

/// Main coin detail screen showing price chart, header, and market stats
/// Coinbase-style layout with prominent header and full-bleed chart
/// Per Constitution Principle I: Uses .task for async loading, pull-to-refresh support
struct CoinDetailView: View {
    // MARK: - Properties

    let coinId: String

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CoinDetailViewModel

    // MARK: - Initialization

    init(coinId: String) {
        self.coinId = coinId
        self._viewModel = State(initialValue: CoinDetailViewModel(coinId: coinId))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                // Coin Header - Coinbase style (large, prominent)
                if let coinDetail = viewModel.coinDetail {
                    coinHeader(coinDetail)
                        .padding(.horizontal, Spacing.medium)
                } else if viewModel.isLoading {
                    headerPlaceholder
                        .padding(.horizontal, Spacing.medium)
                }

                // Price Chart with time range selector
                PriceChartView(
                    dataPoints: viewModel.lineChartData,
                    statistics: viewModel.chartStatistics,
                    isLoading: viewModel.isLoadingChart,
                    availableRanges: ChartTimeRange.lineRanges,
                    selectedRange: $viewModel.selectedTimeRange,
                    onRangeChange: { range in
                        viewModel.switchTimeRange(to: range)
                    }
                )
                .padding(.horizontal, Spacing.medium)

                // Chart Performance Section
                if let stats = viewModel.chartStatistics {
                    performanceSection(stats)
                        .padding(.horizontal, Spacing.medium)
                }

                // Market Stats
                if let coinDetail = viewModel.coinDetail {
                    MarketStatsView(coinDetail: coinDetail)
                        .padding(.horizontal, Spacing.medium)
                }

                // About Section
                if let coinDetail = viewModel.coinDetail {
                    aboutSection(coinDetail)
                        .padding(.horizontal, Spacing.medium)
                }
            }
            .padding(.vertical, Spacing.medium)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle(viewModel.coinDetail?.symbol.uppercased() ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadInitialData()
        }
        .overlay(alignment: .top) {
            errorBanner
        }
    }

    // MARK: - Coin Header (Coinbase Style)

    private func coinHeader(_ coinDetail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Coin name with logo
            HStack(spacing: Spacing.small) {
                AsyncImage(url: coinDetail.image) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .overlay {
                                Text(coinDetail.symbol.prefix(1).uppercased())
                                    .font(Typography.headline)
                                    .foregroundColor(.textSecondary)
                            }
                    @unknown default:
                        Circle().fill(Color.backgroundSecondary)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                Text(coinDetail.name)
                    .font(Typography.title3)
                    .foregroundColor(.textPrimary)
            }

            // Current price - large and prominent
            Text(Formatters.formatPrice(coinDetail.currentPrice))
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.textPrimary)
                .monospacedDigit()

            // Price change
            HStack(spacing: Spacing.tiny) {
                Image(systemName: coinDetail.priceChange24h >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)

                Text(formatPriceChange(coinDetail))
                    .font(Typography.body)
            }
            .foregroundColor(coinDetail.priceChange24h >= 0 ? .profitGreen : .lossRed)
        }
    }

    // MARK: - Helpers

    private func formatPriceChange(_ coinDetail: CoinDetail) -> String {
        let absChange = abs(coinDetail.priceChange24h)
        let priceChange = coinDetail.currentPrice * (absChange / 100)
        let sign = coinDetail.priceChange24h >= 0 ? "+" : "-"
        return "\(sign)\(Formatters.formatPrice(priceChange)) (\(Formatters.formatPercentage(coinDetail.priceChange24h)))"
    }

    // MARK: - Performance Section

    private func performanceSection(_ stats: ChartStatistics) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Section header with time range
                HStack {
                    Text("\(viewModel.selectedTimeRange.displayName) Performance")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    // Period change badge
                    HStack(spacing: Spacing.tiny) {
                        Image(systemName: stats.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(Formatters.formatPercentage(stats.percentageChange))
                            .font(Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(stats.isPositive ? .profitGreen : .lossRed)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.tiny)
                    .background(
                        Capsule()
                            .fill((stats.isPositive ? Color.profitGreen : Color.lossRed).opacity(0.15))
                    )
                }

                // Low/High stats (aligned with progress bar: Low left, High right)
                HStack(spacing: Spacing.large) {
                    // Period Low (left side)
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text("Low")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.formatPrice(stats.periodLow))
                            .font(Typography.numericBody)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    // Period High (right side)
                    VStack(alignment: .trailing, spacing: Spacing.tiny) {
                        Text("High")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.formatPrice(stats.periodHigh))
                            .font(Typography.numericBody)
                            .foregroundColor(.textPrimary)
                    }
                }

                // Range bar visualization
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.textTertiary.opacity(0.2))
                            .frame(height: 4)

                        // Current position indicator
                        if let coinDetail = viewModel.coinDetail {
                            let range = stats.periodHigh - stats.periodLow
                            let position = range > 0
                                ? (coinDetail.currentPrice - stats.periodLow) / range
                                : 0.5
                            let clampedPosition = min(max(Double(truncating: position as NSDecimalNumber), 0), 1)

                            Circle()
                                .fill(stats.isPositive ? Color.profitGreen : Color.lossRed)
                                .frame(width: 10, height: 10)
                                .offset(x: CGFloat(clampedPosition) * (geometry.size.width - 10))
                        }
                    }
                }
                .frame(height: 10)
            }
        }
    }

    // MARK: - About Section

    private func aboutSection(_ coinDetail: CoinDetail) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("About \(coinDetail.name)")
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                Text(coinDescription(for: coinDetail.id))
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .lineLimit(4)
            }
        }
    }

    /// Static descriptions for popular coins
    private func coinDescription(for coinId: String) -> String {
        switch coinId.lowercased() {
        case "bitcoin":
            return "Bitcoin is a decentralized digital currency that enables peer-to-peer transactions without intermediaries. Created in 2009, it's the world's first and largest cryptocurrency by market cap."
        case "ethereum":
            return "Ethereum is a decentralized platform that enables smart contracts and decentralized applications. It introduced programmable blockchain technology and powers the DeFi ecosystem."
        case "solana":
            return "Solana is a high-performance blockchain platform designed for decentralized apps and crypto-currencies, known for its fast transaction speeds and low costs."
        case "cardano":
            return "Cardano is a proof-of-stake blockchain platform founded on peer-reviewed research. It aims to provide a secure and scalable infrastructure for smart contracts."
        case "ripple", "xrp":
            return "XRP is the native cryptocurrency of the XRP Ledger, designed for fast and low-cost international payments and cross-border transactions."
        case "dogecoin":
            return "Dogecoin started as a meme cryptocurrency but has grown into a widely recognized digital asset, known for its active community and use in tipping online."
        default:
            return "A cryptocurrency tradeable on major exchanges. View the chart above to see recent price performance and market statistics below for more details."
        }
    }

    // MARK: - Subviews

    private var headerPlaceholder: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 32, height: 32)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.backgroundSecondary)
                    .frame(width: 80, height: 20)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.backgroundSecondary)
                .frame(width: 150, height: 36)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.backgroundSecondary)
                .frame(width: 120, height: 18)
        }
        .redacted(reason: .placeholder)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.lossRed)

                Text(error)
                    .font(Typography.caption)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button {
                    viewModel.errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(Spacing.small)
            .background(.ultraThinMaterial)
            .cornerRadius(Spacing.small)
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.small)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3), value: viewModel.errorMessage)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CoinDetailView(coinId: "bitcoin")
    }
}
