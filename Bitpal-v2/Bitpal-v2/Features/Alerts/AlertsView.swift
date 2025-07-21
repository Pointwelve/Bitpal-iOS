//
//  AlertsView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct AlertsView: View {
    @Environment(AlertService.self) private var alertService
    @Query(sort: \Alert.createdAt, order: .reverse) private var alerts: [Alert]
    
    @State private var showingCreateAlert = false
    @State private var selectedCurrencyPair: CurrencyPair?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if alerts.isEmpty {
                    emptyStateView
                } else {
                    alertsList
                }
                
                if alertService.isLoading {
                    ProgressView("Loading alerts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                }
            }
            .navigationTitle("Price Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateAlert) {
                CreateAlertView()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: alertService.errorMessage) { _, newError in
                if let error = newError {
                    errorMessage = error
                    showingError = true
                }
            }
            .refreshable {
                await alertService.loadAlerts()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Price Alerts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create alerts to get notified when your cryptocurrencies reach target prices")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingCreateAlert = true
            } label: {
                Label("Create Alert", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private var alertsList: some View {
        List {
            ForEach(alerts) { alert in
                AlertRow(alert: alert)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                try? await alertService.deleteAlert(alert)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
                                try? await alertService.updateAlert(alert, isEnabled: !alert.isEnabled)
                            }
                        } label: {
                            Label(
                                alert.isEnabled ? "Disable" : "Enable",
                                systemImage: alert.isEnabled ? "bell.slash" : "bell"
                            )
                        }
                        .tint(alert.isEnabled ? .orange : .green)
                    }
            }
        }
        .listStyle(.plain)
    }
}

struct AlertRow: View {
    let alert: Alert
    @Environment(AlertService.self) private var alertService
    
    var body: some View {
        HStack(spacing: 12) {
            // Alert Status Indicator
            Circle()
                .fill(alert.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Currency Pair
                if let currencyPair = alert.currencyPair {
                    Text(currencyPair.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Unknown Pair")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Alert Condition
                HStack(spacing: 4) {
                    Text("Alert when")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(alert.comparison.symbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(alert.comparison == .above ? .green : .red)
                    
                    Text(alert.targetPrice.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Last Triggered
                if let lastTriggered = alert.lastTriggered {
                    Text("Last triggered: \(lastTriggered.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never triggered")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Current Price vs Target
            if let currencyPair = alert.currencyPair {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyPair.currentPrice.formatted(.currency(code: "USD")))
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    let difference = currencyPair.currentPrice - alert.targetPrice
                    let isClose = abs(difference) / alert.targetPrice < 0.05 // Within 5%
                    
                    HStack(spacing: 4) {
                        Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundColor(difference >= 0 ? .green : .red)
                        
                        Text(abs(difference).formatted(.currency(code: "USD")))
                            .font(.caption)
                            .foregroundColor(isClose ? .orange : .secondary)
                    }
                }
            }
            
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { alert.isEnabled },
                set: { isEnabled in
                    Task {
                        try? await alertService.updateAlert(alert, isEnabled: isEnabled)
                    }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .opacity(alert.isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
    .modelContainer(for: [Alert.self, CurrencyPair.self], inMemory: true)
    .environment(AlertService.shared)
}