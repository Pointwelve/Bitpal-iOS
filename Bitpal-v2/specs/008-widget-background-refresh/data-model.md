# Data Model: Widget Background Refresh

**Feature**: 008-widget-background-refresh
**Date**: 2025-12-11

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        App Group Container                               │
│                    (group.com.bitpal.shared)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────┐      ┌─────────────────────────┐          │
│  │   WidgetRefreshData     │      │  WidgetPortfolioData    │          │
│  │   (refresh_data.json)   │      │   (portfolio.json)      │          │
│  ├─────────────────────────┤      ├─────────────────────────┤          │
│  │ • holdings[]            │      │ • totalValue            │          │
│  │   - coinId              │      │ • unrealizedPnL         │          │
│  │   - symbol              │      │ • realizedPnL           │          │
│  │   - name                │ ──▶  │ • totalPnL              │          │
│  │   - quantity            │      │ • holdings[] (display)  │          │
│  │   - avgCost             │      │ • lastUpdated           │          │
│  │ • realizedPnL           │      │                         │          │
│  └─────────────────────────┘      └─────────────────────────┘          │
│         ▲                                    │                          │
│         │                                    │                          │
│    Written by                          Read by                          │
│    Main App                            Widget Views                     │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Entities

### WidgetRefreshData (NEW)

**Purpose**: Stores the minimal data needed for widget to recalculate portfolio values with fresh prices.

**Location**: `Bitpal/Shared/Models/WidgetRefreshData.swift`

**Storage**: `{AppGroup}/Library/Application Support/WidgetData/refresh_data.json`

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `holdings` | `[RefreshableHolding]` | Array of holdings with quantities | Non-empty array required |
| `realizedPnL` | `Decimal` | Total realized P&L (unchanged during refresh) | Any value |

#### RefreshableHolding (Nested)

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `coinId` | `String` | CoinGecko coin ID (e.g., "bitcoin") | Non-empty |
| `symbol` | `String` | Trading symbol (e.g., "BTC") | Non-empty |
| `name` | `String` | Display name (e.g., "Bitcoin") | Non-empty |
| `quantity` | `Decimal` | Total quantity held | > 0 |
| `avgCost` | `Decimal` | Average cost per coin | >= 0 |

**Relationships**:
- Written by: `WidgetDataProvider` (main app)
- Read by: `PortfolioTimelineProvider` (widget)
- One-to-many: One WidgetRefreshData contains many RefreshableHoldings

**State Transitions**: None (immutable snapshot, replaced on each write)

---

### WidgetPortfolioData (EXISTING - No Changes)

**Purpose**: Display data for widget views. Already exists and is well-documented.

**Location**: `Bitpal/Shared/Models/WidgetPortfolioData.swift`

**Storage**: `{AppGroup}/Library/Application Support/WidgetData/portfolio.json`

| Field | Type | Description |
|-------|------|-------------|
| `totalValue` | `Decimal` | Sum of all holding values |
| `unrealizedPnL` | `Decimal` | Unrealized profit/loss |
| `realizedPnL` | `Decimal` | Realized profit/loss |
| `totalPnL` | `Decimal` | unrealizedPnL + realizedPnL |
| `holdings` | `[WidgetHolding]` | Top 5 holdings for display |
| `lastUpdated` | `Date` | Timestamp of last data update |

**Changes**: Widget will now write updated WidgetPortfolioData after fetching fresh prices.

---

### WidgetHolding (EXISTING - No Changes)

**Purpose**: Individual holding display data for widget.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Coin ID |
| `symbol` | `String` | Symbol (uppercase) |
| `name` | `String` | Display name |
| `currentValue` | `Decimal` | quantity × currentPrice |
| `pnlAmount` | `Decimal` | currentValue - costBasis |
| `pnlPercentage` | `Decimal` | ((currentValue / costBasis) - 1) × 100 |

---

## P&L Calculation Flow

When widget fetches fresh prices, it recalculates using this formula:

```
For each holding in WidgetRefreshData:
    currentValue = quantity × freshPrice
    costBasis = quantity × avgCost
    pnlAmount = currentValue - costBasis
    pnlPercentage = costBasis > 0 ? ((currentValue / costBasis) - 1) × 100 : 0

Aggregate:
    totalValue = sum(currentValue for all holdings)
    unrealizedPnL = sum(pnlAmount for all holdings)
    totalPnL = unrealizedPnL + realizedPnL  (realizedPnL from WidgetRefreshData)
```

---

## File Storage Layout

```
{App Group Container}/
└── Library/
    └── Application Support/
        └── WidgetData/
            ├── portfolio.json        # WidgetPortfolioData (display)
            └── refresh_data.json     # WidgetRefreshData (for recalculation)
```

Both files use:
- JSON encoding with ISO8601 dates
- Atomic writes to prevent corruption
- Pretty-printed for debugging
