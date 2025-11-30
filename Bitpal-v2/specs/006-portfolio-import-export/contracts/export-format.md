# Export Format Specification

**Feature**: 006-portfolio-import-export
**Version**: 1.0
**Date**: 2025-11-28

## Overview

This document defines the file formats for Bitpal portfolio export and import. Two formats are supported:

1. **JSON** - Primary format for export and import (lossless round-trip)
2. **CSV** - Import only, for external data sources

---

## JSON Format (v1.0)

### File Extension
`.json`

### MIME Type
`application/json`

### Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BitpalExportFile",
  "type": "object",
  "required": ["version", "exportDate", "appVersion", "transactions"],
  "properties": {
    "version": {
      "type": "string",
      "description": "Format version for compatibility",
      "const": "1.0"
    },
    "exportDate": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of export"
    },
    "appVersion": {
      "type": "string",
      "description": "Bitpal app version that created export"
    },
    "transactions": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Transaction"
      }
    }
  },
  "definitions": {
    "Transaction": {
      "type": "object",
      "required": ["id", "coinId", "type", "amount", "pricePerCoin", "date"],
      "properties": {
        "id": {
          "type": "string",
          "format": "uuid",
          "description": "Transaction UUID"
        },
        "coinId": {
          "type": "string",
          "description": "CoinGecko coin identifier (lowercase)",
          "examples": ["bitcoin", "ethereum", "cardano"]
        },
        "type": {
          "type": "string",
          "enum": ["buy", "sell"],
          "description": "Transaction type"
        },
        "amount": {
          "type": "string",
          "pattern": "^[0-9]+(\\.[0-9]+)?$",
          "description": "Quantity as decimal string (positive)"
        },
        "pricePerCoin": {
          "type": "string",
          "pattern": "^[0-9]+(\\.[0-9]+)?$",
          "description": "USD price per coin as decimal string"
        },
        "date": {
          "type": "string",
          "format": "date-time",
          "description": "Transaction date (ISO 8601)"
        },
        "notes": {
          "type": ["string", "null"],
          "description": "Optional user notes"
        }
      }
    }
  }
}
```

### Example

```json
{
  "version": "1.0",
  "exportDate": "2025-11-28T10:30:00Z",
  "appVersion": "1.0.0",
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "coinId": "bitcoin",
      "type": "buy",
      "amount": "0.5",
      "pricePerCoin": "45000.00",
      "date": "2025-01-15T00:00:00Z",
      "notes": "DCA purchase"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "coinId": "ethereum",
      "type": "buy",
      "amount": "2.0",
      "pricePerCoin": "3200.50",
      "date": "2025-01-20T00:00:00Z",
      "notes": null
    }
  ]
}
```

### Decimal Precision

All numeric values (`amount`, `pricePerCoin`) are encoded as **strings** to preserve decimal precision. This ensures lossless round-trip for financial data.

**Encoding Rule**: Use `String(describing: decimal)` or equivalent.

**Decoding Rule**: Use `Decimal(string:)` initializer.

### Date Format

All dates use ISO 8601 format with timezone: `YYYY-MM-DDTHH:mm:ssZ`

---

## CSV Format (Import Only)

### File Extension
`.csv`

### MIME Type
`text/csv`

### Column Specification

| Column       | Required | Format                   | Description                    |
|--------------|----------|--------------------------|--------------------------------|
| coin_id      | Yes      | String (lowercase)       | CoinGecko coin identifier      |
| type         | Yes      | "buy" or "sell"          | Transaction type               |
| amount       | Yes      | Positive decimal         | Quantity of coins              |
| price        | Yes      | Positive decimal         | USD price per coin             |
| date         | Yes      | YYYY-MM-DD               | Transaction date               |
| notes        | No       | String                   | Optional notes                 |

### Rules

1. **Header row required**: First row must contain column names
2. **Column order flexible**: Columns matched by header name, not position
3. **Case insensitive headers**: `coin_id`, `COIN_ID`, `Coin_Id` all valid
4. **Empty rows skipped**: Rows containing only whitespace are ignored
5. **Quoted values supported**: Values with commas must be quoted: `"Note with, comma"`
6. **Empty notes allowed**: Trailing comma or empty field for notes is valid

### Example

```csv
coin_id,type,amount,price,date,notes
bitcoin,buy,0.5,45000.00,2025-01-15,DCA purchase
ethereum,buy,2.0,3200.50,2025-01-20,
cardano,sell,100,0.52,2025-01-25,Taking profits
solana,buy,10,98.75,2025-01-30,"Big purchase, going long"
```

### Validation Errors

| Error Condition | Message |
|-----------------|---------|
| Missing header row | "CSV file must have a header row" |
| Missing required column | "Missing required column: {column}" |
| Empty coin_id | "Row {n}: Coin ID is required" |
| Invalid type | "Row {n}: Type must be 'buy' or 'sell'" |
| Invalid amount | "Row {n}: Amount must be a positive number" |
| Invalid price | "Row {n}: Price must be a positive number" |
| Invalid date | "Row {n}: Date must be in YYYY-MM-DD format" |

---

## Version Migration

### Future Versions

When introducing format changes:

1. Increment version number (e.g., "1.0" → "1.1" or "2.0")
2. Maintain backward compatibility for reading older versions
3. Always export in latest format
4. Document migration path

### Version Detection

On import, check `version` field:
- "1.0": Current format, process directly
- Unknown: Show warning, attempt to parse, fail gracefully if incompatible

---

## File Naming Convention

### Export Filename

Format: `bitpal-portfolio-{date}.json`

Example: `bitpal-portfolio-2025-11-28.json`

### Import

Accept any filename with `.json` or `.csv` extension.

---

## Security Considerations

1. **No sensitive data**: Export contains only transaction data, no credentials
2. **Local only**: Files are stored/shared by user, not uploaded to servers
3. **Validation required**: All imported data must be validated before processing
4. **No code execution**: JSON is data only, no executable content
