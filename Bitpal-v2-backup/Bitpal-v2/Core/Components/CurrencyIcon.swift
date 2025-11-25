//
//  CurrencyIcon.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 21/7/25.
//

import SwiftUI

struct CurrencyIcon: View {
    let currency: Currency?
    let size: CGFloat
    
    init(currency: Currency?, size: CGFloat = 50) {
        self.currency = currency
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(currencyColor)
            .frame(width: size, height: size)
            .overlay {
                Group {
                    if let systemImageName = currencySystemImage {
                        Image(systemName: systemImageName)
                            .font(.system(size: size * 0.5, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text(currencyDisplayText)
                            .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .shadow(color: currencyColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var currencyColor: Color {
        guard let currency = currency else { return .gray }
        
        switch currency.symbol.uppercased() {
        // Major Cryptocurrencies
        case "BTC", "BITCOIN":
            return Color.orange
        case "ETH", "ETHEREUM":
            return Color.indigo
        case "LTC", "LITECOIN":
            return Color.gray
        case "XRP", "RIPPLE":
            return Color.blue
        case "BCH", "BITCOINCASH":
            return Color.green
        case "ETC", "ETHEREUMCLASSIC":
            return Color.green
            
        // Stablecoins
        case "USD", "USDT", "USDC":
            return Color.green
        case "DAI":
            return Color.yellow
            
        // Major Altcoins (from CurrencySearchService)
        case "BNB", "BINANCECOIN":
            return Color.yellow
        case "SOL", "SOLANA":
            return Color.purple
        case "ADA", "CARDANO":
            return Color.blue
        case "DOT", "POLKADOT":
            return Color.pink
        case "LINK", "CHAINLINK":
            return Color.blue
        case "MATIC", "POLYGON":
            return Color.purple
        case "AVAX", "AVALANCHE":
            return Color.red
        case "DOGE", "DOGECOIN":
            return Color.yellow
        case "SHIB", "SHIBAINU":
            return Color.orange
        case "TON", "TONCOIN":
            return Color.blue
        case "UNI", "UNISWAP":
            return Color.pink
        case "ATOM", "COSMOS":
            return Color.purple
        case "XLM", "STELLAR":
            return Color.blue
        case "FIL", "FILECOIN":
            return Color.blue
        case "HBAR", "HEDERA":
            return Color.purple
        case "VET", "VECHAIN":
            return Color.blue
        case "ALGO", "ALGORAND":
            return Color.black
            
        // Fiat Currencies
        case "EUR":
            return Color.blue
        case "GBP":
            return Color.purple
        case "JPY":
            return Color.red
        case "CNY", "YUAN":
            return Color.red
        case "KRW", "WON":
            return Color.blue
            
        default:
            return Color.blue
        }
    }
    
    private var currencySystemImage: String? {
        guard let currency = currency else { return nil }
        
        switch currency.symbol.uppercased() {
        case "BTC", "BITCOIN":
            return "bitcoinsign.circle.fill"
        case "USD", "USDT", "USDC":
            return "dollarsign.circle.fill"
        case "EUR":
            return "eurosign.circle.fill"
        case "GBP":
            return "sterlingsign.circle.fill"
        case "JPY":
            return "yensign.circle.fill"
        default:
            return nil // Use text fallback
        }
    }
    
    private var currencyDisplayText: String {
        guard let currency = currency else { return "?" }
        
        // Use displaySymbol if available and short, otherwise use first 2-3 characters of symbol
        if !currency.displaySymbol.isEmpty && currency.displaySymbol.count <= 3 {
            return currency.displaySymbol
        } else {
            return String(currency.symbol.prefix(3)).uppercased()
        }
    }
}

// Preview helpers
#Preview("Bitcoin") {
    VStack(spacing: 20) {
        CurrencyIcon(currency: .bitcoin(), size: 60)
        CurrencyIcon(currency: .ethereum(), size: 60)
        CurrencyIcon(currency: .usd(), size: 60)
    }
}