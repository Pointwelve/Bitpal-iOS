//
//  ContentView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WatchlistView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Watchlist")
                }
                .tag(0)
            
            AlertsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Alerts")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .task {
            await initializeApp()
        }
    }
    
    private func initializeApp() async {
        // Initialize default data if needed
        await createDefaultConfiguration()
        await setupDefaultCurrencies()
    }
    
    private func createDefaultConfiguration() async {
        let descriptor = FetchDescriptor<Configuration>()
        
        do {
            let configurations = try modelContext.fetch(descriptor)
            if configurations.isEmpty {
                let defaultConfig = Configuration()
                modelContext.insert(defaultConfig)
                try modelContext.save()
            }
        } catch {
            print("Failed to create default configuration: \(error)")
        }
    }
    
    private func setupDefaultCurrencies() async {
        let descriptor = FetchDescriptor<Currency>()
        
        do {
            let currencies = try modelContext.fetch(descriptor)
            if currencies.isEmpty {
                // Add some default currencies
                let bitcoin = Currency.bitcoin()
                let ethereum = Currency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ")
                let usd = Currency.usd()
                
                modelContext.insert(bitcoin)
                modelContext.insert(ethereum)
                modelContext.insert(usd)
                
                // Add default exchange
                let exchange = Exchange(id: "COINDESK", name: "CoinDesk", displayName: "CoinDesk")
                modelContext.insert(exchange)
                
                try modelContext.save()
            }
        } catch {
            print("Failed to setup default currencies: \(error)")
        }
    }
}

// Enhanced Settings View
struct SettingsView: View {
    @Query private var configurations: [Configuration]
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API Configuration") {
                    if let config = configurations.first {
                        SecureField("API Key", text: Binding(
                            get: { config.apiKey },
                            set: { newValue in
                                config.apiKey = newValue
                                try? modelContext.save()
                            }
                        ))
                        .textContentType(.password)
                    }
                }
                
                Section("Appearance") {
                    if let prefs = preferences.first {
                        Picker("Theme", selection: Binding(
                            get: { prefs.theme },
                            set: { newValue in
                                prefs.theme = newValue
                                try? modelContext.save()
                            }
                        )) {
                            ForEach(Theme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        
                        Picker("Currency", selection: Binding(
                            get: { prefs.currency },
                            set: { newValue in
                                prefs.currency = newValue
                                try? modelContext.save()
                            }
                        )) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("JPY").tag("JPY")
                        }
                    }
                }
                
                Section("Notifications") {
                    if let prefs = preferences.first {
                        Toggle("Enable Notifications", isOn: Binding(
                            get: { prefs.notificationsEnabled },
                            set: { newValue in
                                prefs.notificationsEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                        
                        Toggle("Price Alerts", isOn: Binding(
                            get: { prefs.priceAlertsEnabled },
                            set: { newValue in
                                prefs.priceAlertsEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                        
                        Toggle("News Alerts", isOn: Binding(
                            get: { prefs.newsAlertsEnabled },
                            set: { newValue in
                                prefs.newsAlertsEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                        
                        Toggle("Biometric Authentication", isOn: Binding(
                            get: { prefs.biometricAuthEnabled },
                            set: { newValue in
                                prefs.biometricAuthEnabled = newValue
                                try? modelContext.save()
                            }
                        ))
                    }
                }
                
                Section("About") {
                    if let config = configurations.first {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(config.version)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Company")
                            Spacer()
                            Text(config.companyName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Currency.self,
            Exchange.self,
            CurrencyPair.self,
            Alert.self,
            AlertList.self,
            HistoricalPrice.self,
            Watchlist.self,
            Configuration.self,
            UserPreferences.self,
            Item.self
        ], inMemory: true)
}
