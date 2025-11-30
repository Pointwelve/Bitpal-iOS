//
//  ImportPreviewView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import SwiftUI
import SwiftData

/// Preview screen for import data before confirmation
/// Per Constitution Principle II: Follows Liquid Glass design system
struct ImportPreviewView: View {
    let preview: ImportPreview
    let modelContext: ModelContext
    let onImportComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false
    @State private var showError = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                summaryHeader
                    .padding()
                    .background(.ultraThinMaterial)

                // Rows list
                ScrollView {
                    LazyVStack(spacing: Spacing.small) {
                        // Valid rows section
                        if !preview.validRows.isEmpty {
                            Section {
                                ForEach(preview.validRows) { row in
                                    ImportRowView(row: row)
                                }
                            } header: {
                                sectionHeader(
                                    title: "Valid Transactions",
                                    count: preview.validRows.count,
                                    color: .profitGreen
                                )
                            }
                        }

                        // Invalid rows section
                        if !preview.invalidRows.isEmpty {
                            Section {
                                ForEach(preview.invalidRows) { row in
                                    ImportRowView(row: row)
                                }
                            } header: {
                                sectionHeader(
                                    title: "Invalid Rows",
                                    count: preview.invalidRows.count,
                                    color: .lossRed
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        Task {
                            await performImport()
                        }
                    }
                    .disabled(!preview.hasValidData || isImporting)
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to import transactions")
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: Spacing.small) {
            HStack {
                Image(systemName: preview.sourceType == .json ? "doc.text" : "tablecells")
                    .foregroundColor(.textSecondary)
                Text(preview.fileName)
                    .font(Typography.headline)
            }

            HStack(spacing: Spacing.large) {
                VStack {
                    Text("\(preview.validRows.count)")
                        .font(Typography.title2)
                        .foregroundColor(.profitGreen)
                    Text("Valid")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(preview.invalidRows.count)")
                        .font(Typography.title2)
                        .foregroundColor(preview.invalidRows.isEmpty ? .textSecondary : .lossRed)
                    Text("Invalid")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(preview.totalRowCount)")
                        .font(Typography.title2)
                    Text("Total")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // CSV format help - show expected columns
            if preview.sourceType == .csv {
                csvFormatHelp
            }
        }
    }

    // MARK: - CSV Format Help

    private var csvFormatHelp: some View {
        VStack(alignment: .leading, spacing: Spacing.tiny) {
            Text("Expected CSV Columns")
                .font(Typography.caption)
                .fontWeight(.semibold)
            Text("Required: coin_id, type, amount, price, date")
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
            Text("Optional: notes")
                .font(Typography.caption)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.small)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(Typography.headline)
            Spacer()
            Text("\(count)")
                .font(Typography.subheadline)
                .foregroundColor(color)
        }
        .padding(.top, Spacing.medium)
        .padding(.bottom, Spacing.tiny)
    }

    // MARK: - Import Action

    @MainActor
    private func performImport() async {
        isImporting = true

        do {
            // Convert valid rows to transactions and insert
            for row in preview.validRows {
                if let transaction = row.toTransaction() {
                    modelContext.insert(transaction)
                }
            }

            try modelContext.save()

            onImportComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isImporting = false
    }
}

// MARK: - Import Row View

/// Single row display in import preview
private struct ImportRowView: View {
    let row: ImportRow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.tiny) {
            HStack {
                // Row number badge
                Text("#\(row.rowNumber)")
                    .font(Typography.caption)
                    .foregroundColor(.textTertiary)
                    .frame(width: 40, alignment: .leading)

                // Coin ID
                Text(row.coinId.isEmpty ? "—" : row.coinId)
                    .font(Typography.body)
                    .fontWeight(.medium)

                Spacer()

                // Type badge
                if let type = row.type {
                    Text(type.rawValue.uppercased())
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(type == .buy ? .profitGreen : .lossRed)
                        .padding(.horizontal, Spacing.tiny)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(type == .buy ? Color.profitGreen.opacity(0.15) : Color.lossRed.opacity(0.15))
                        )
                }
            }

            HStack {
                // Amount
                if let amount = row.amount {
                    Text("Qty: \(amount.formatted())")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                // Price
                if let price = row.pricePerCoin {
                    Text("@ $\(price.formatted())")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Date
                if let date = row.date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundColor(.textTertiary)
                }
            }

            // Errors (for invalid rows)
            if !row.errors.isEmpty {
                ForEach(row.errors, id: \.self) { error in
                    HStack(spacing: Spacing.tiny) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.lossRed)
                            .font(.caption2)
                        Text(error)
                            .font(Typography.caption)
                            .foregroundColor(.lossRed)
                    }
                }
            }

            // Notes
            if let notes = row.notes, !notes.isEmpty {
                Text(notes)
                    .font(Typography.caption)
                    .foregroundColor(.textTertiary)
                    .italic()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(row.isValid ? Color.clear : Color.lossRed.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    let samplePreview = ImportPreview(
        sourceType: .json,
        fileName: "bitpal-portfolio-2025-01-15.json",
        validRows: [
            ImportRow(
                rowNumber: 1,
                coinId: "bitcoin",
                type: .buy,
                amount: Decimal(string: "1.5")!,
                pricePerCoin: Decimal(45000),
                date: Date(),
                notes: "DCA purchase",
                errors: []
            ),
            ImportRow(
                rowNumber: 2,
                coinId: "ethereum",
                type: .buy,
                amount: Decimal(10),
                pricePerCoin: Decimal(3000),
                date: Date(),
                notes: nil,
                errors: []
            )
        ],
        invalidRows: [
            ImportRow(
                rowNumber: 3,
                coinId: "",
                type: nil,
                amount: nil,
                pricePerCoin: nil,
                date: nil,
                notes: nil,
                errors: ["Missing coin_id", "Invalid type", "Missing amount"]
            )
        ]
    )

    return ImportPreviewView(
        preview: samplePreview,
        modelContext: try! ModelContainer(for: Transaction.self).mainContext,
        onImportComplete: { }
    )
}
