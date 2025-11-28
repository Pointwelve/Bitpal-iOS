# Quickstart: iOS Home Screen Widgets for Portfolio

**Feature**: 004-portfolio-widgets
**Date**: 2025-11-26

## Prerequisites

- Xcode 17+ with iOS 26 SDK
- Existing Bitpal project with Portfolio feature working
- Apple Developer account (for device testing)

## Setup Steps

### 1. Add Widget Extension Target

```bash
# In Xcode:
# File → New → Target → Widget Extension
# Product Name: BitpalWidget
# Include Configuration App Intent: NO (not using interactive widgets)
# Include Live Activity: NO (out of scope)
```

### 2. Configure App Groups

```bash
# In both Bitpal and BitpalWidget targets:
# Signing & Capabilities → + Capability → App Groups
# Add: group.com.bitpal.shared
```

### 3. Create Shared Framework (Optional)

If extracting shared code to a framework:

```bash
# File → New → Target → Framework
# Product Name: BitpalShared
# Add to both Bitpal and BitpalWidget targets
```

### 4. Project Structure

Create these directories:

```bash
mkdir -p Bitpal/Features/Widget
mkdir -p Bitpal/Shared/Models
mkdir -p Bitpal/Shared/Services
mkdir -p Bitpal/Shared/Calculations
mkdir -p BitpalWidget/Provider
mkdir -p BitpalWidget/Views
mkdir -p BitpalWidget/Entry
```

## Key Files to Create

### Main App Files

| File | Purpose |
|------|---------|
| `Shared/Models/WidgetPortfolioData.swift` | Widget data structure |
| `Shared/Models/WidgetHolding.swift` | Simplified holding |
| `Shared/Services/AppGroupStorage.swift` | Read/write App Group |
| `Features/Widget/WidgetDataProvider.swift` | Prepare and persist data |

### Widget Extension Files

| File | Purpose |
|------|---------|
| `BitpalWidget.swift` | Widget configuration |
| `BitpalWidgetBundle.swift` | Bundle entry point |
| `Provider/PortfolioTimelineProvider.swift` | Timeline generation |
| `Entry/PortfolioEntry.swift` | Timeline entry |
| `Views/SmallWidgetView.swift` | Small widget UI |
| `Views/MediumWidgetView.swift` | Medium widget UI |
| `Views/LargeWidgetView.swift` | Large widget UI |

## Implementation Order

### Phase 1: Infrastructure (Day 1-2)

1. **Create App Group capability** in both targets
2. **Create `AppGroupStorage.swift`** - Read/write JSON to shared container
3. **Create `WidgetPortfolioData.swift`** and `WidgetHolding.swift`
4. **Update `PortfolioViewModel`** to write widget data on update

### Phase 2: Widget Extension (Day 2-3)

5. **Add Widget Extension target** to project
6. **Create `PortfolioEntry.swift`** - Timeline entry model
7. **Create `PortfolioTimelineProvider.swift`** - Read data, generate timeline
8. **Create `BitpalWidget.swift`** - Widget configuration

### Phase 3: Widget Views (Day 3-4)

9. **Create `SmallWidgetView.swift`** - Total value + P&L
10. **Create `MediumWidgetView.swift`** - Add top 2 holdings
11. **Create `LargeWidgetView.swift`** - Add top 5 holdings
12. **Implement deep linking** - URL scheme handling

### Phase 4: Polish & Testing (Day 4-5)

13. **Add empty state** handling
14. **Add offline/stale** indicators
15. **Test all widget sizes** on device
16. **Test Dark Mode** appearance
17. **Verify P&L accuracy** matches main app

## Quick Verification

### Test App Group Access

```swift
// In main app (e.g., AppDelegate or BitpalApp)
let url = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.bitpal.shared")
print("App Group URL: \(url?.path ?? "nil")")
// Should print a valid path, not nil
```

### Test Widget Preview

```swift
// In BitpalWidget.swift
#Preview(as: .systemSmall) {
    BitpalWidget()
} timeline: {
    PortfolioEntry.placeholder()
    PortfolioEntry.entry(data: .sample)
}
```

### Test Deep Link

```swift
// In app
.onOpenURL { url in
    print("Opened with URL: \(url)")
    // Should print: bitpal://portfolio
}
```

## Common Issues

### Widget Shows "Unable to Load"

1. Verify App Group identifier matches exactly
2. Check that widget target links required frameworks
3. Ensure `PortfolioTimelineProvider` returns valid entries

### Data Not Syncing

1. Verify App Group enabled in both targets
2. Check that main app writes data after portfolio update
3. Call `WidgetCenter.shared.reloadAllTimelines()` after write

### Widget Not Appearing in Gallery

1. Clean build folder (Cmd+Shift+K)
2. Delete app from simulator, reinstall
3. Restart simulator

## Sample Data for Testing

```swift
extension WidgetPortfolioData {
    static let sample = WidgetPortfolioData(
        totalValue: 125000.50,
        unrealizedPnL: 15000.00,
        realizedPnL: 5000.00,
        totalPnL: 20000.00,
        holdings: [
            WidgetHolding(
                id: "bitcoin",
                symbol: "BTC",
                name: "Bitcoin",
                currentValue: 100000.00,
                pnlAmount: 12000.00,
                pnlPercentage: 13.64
            ),
            WidgetHolding(
                id: "ethereum",
                symbol: "ETH",
                name: "Ethereum",
                currentValue: 25000.50,
                pnlAmount: 3000.00,
                pnlPercentage: 13.63
            )
        ],
        lastUpdated: Date()
    )
}
```

## Next Steps

After completing setup, run `/speckit.tasks` to generate detailed implementation tasks.
