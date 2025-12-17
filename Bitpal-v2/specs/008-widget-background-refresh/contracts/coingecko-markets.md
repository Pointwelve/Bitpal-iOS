# API Contract: CoinGecko Markets Endpoint

**Feature**: 008-widget-background-refresh
**Date**: 2025-12-11
**Purpose**: Define the API contract for widget price fetching

## Endpoint

```
GET https://api.coingecko.com/api/v3/coins/markets
```

## Request

### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `vs_currency` | string | Yes | Target currency (always `usd`) |
| `ids` | string | Yes | Comma-separated coin IDs (e.g., `bitcoin,ethereum,cardano`) |
| `price_change_percentage` | string | No | Include price change (use `24h`) |

### Example Request

```
GET /api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum,cardano&price_change_percentage=24h
Host: api.coingecko.com
```

### Constraints

- Maximum 250 coin IDs per request
- Rate limit: 50 requests/minute (free tier)
- No authentication required

## Response

### Success Response (200 OK)

```json
[
  {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin",
    "current_price": 45000.50,
    "price_change_percentage_24h": 2.5,
    "last_updated": "2025-12-11T10:30:00.000Z"
  },
  {
    "id": "ethereum",
    "symbol": "eth",
    "name": "Ethereum",
    "current_price": 3200.75,
    "price_change_percentage_24h": -1.2,
    "last_updated": "2025-12-11T10:30:00.000Z"
  }
]
```

### Response Fields (Used by Widget)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique coin identifier |
| `symbol` | string | Trading symbol (lowercase) |
| `name` | string | Display name |
| `current_price` | number | Current price in USD |
| `price_change_percentage_24h` | number | 24h price change percentage (may be null) |

### Error Responses

| Status | Description | Widget Handling |
|--------|-------------|-----------------|
| 429 | Rate limit exceeded | Use cached data, retry next cycle |
| 500+ | Server error | Use cached data, retry next cycle |
| Network timeout | No response | Use cached data, retry next cycle |

## Widget Implementation

### Swift Struct for Response

```swift
struct CoinMarketData: Codable {
    let id: String
    let symbol: String
    let name: String
    let currentPrice: Decimal
    let priceChange24h: Decimal?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChange24h = "price_change_percentage_24h"
    }
}
```

### Usage in Widget

```swift
// Build URL
let ids = holdings.map { $0.coinId }.joined(separator: ",")
let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(ids)&price_change_percentage=24h")!

// Fetch and decode
let (data, _) = try await URLSession.shared.data(from: url)
let coins = try JSONDecoder().decode([CoinMarketData].self, from: data)

// Convert to dictionary for lookup
let priceMap = Dictionary(uniqueKeysWithValues: coins.map { ($0.id, $0) })
```

## Rate Limit Compliance

- Widget refreshes every 15-30 minutes (iOS controlled)
- Single API call per refresh (batched coin IDs)
- Well under 50 calls/minute limit
- No need for rate limiter in widget
