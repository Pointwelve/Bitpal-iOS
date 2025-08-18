# Mobile App Design Specification

## 1. Design Overview
- **Design Philosophy**: iOS-Native Financial Excellence - A sophisticated mobile-first design system that leverages iOS 17/18 native capabilities with Airbnb-inspired fluid interactions, creating a professional cryptocurrency portfolio platform that feels both powerful and intuitive for mobile users.
- **Target Audience**: Cryptocurrency investors, traders, and social learners who demand professional-grade analytics with mobile-first accessibility across iPhone and iPad platforms.
- **Design Principles**: Clarity, Deference, and Depth (iOS HIG) - prioritizing real-time data clarity, deferential interface that highlights content, and meaningful visual depth through native iOS materials.
- **Experience Goals**: Effortless portfolio monitoring, one-tap trading insights, seamless social learning, and universal accessibility across all iOS devices.

## 2. Visual Design System
### 2.1 Color System

**Primary Palette**
- **Primary Brand**: `#007AFF` - iOS system blue for key actions, navigation bars, and prominent interactive elements.
- **Secondary/Accent**: `#5856D6` - iOS system purple for secondary buttons, highlights, and community features.

**Financial Functional Colors**
- **Success/Profit**: `#30D158` - For profit indicators, positive price changes, successful transactions.
- **Warning/Alert**: `#FF9F0A` - For price alerts, important notifications, and pending states.
- **Error/Loss**: `#FF3B30` - For loss indicators, error states, and destructive actions.
- **Info/Neutral**: `#64D2FF` - For informational content, neutral market data, and tips.

**Neutral & Background System**
- **Primary Text**: `#1D1D1F` - For all main headlines, primary content, and critical data.
- **Secondary Text**: `#8E8E93` - For subtitles, supporting information, and secondary data.
- **Tertiary Text/Hints**: `#C7C7CC` - For placeholder text, disabled states, and inactive elements.
- **Primary Background**: `#FFFFFF` - Main screen background (light mode).
- **Secondary Background**: `#F2F2F7` - For cards, grouped content, and input fields.
- **Separators/Borders**: `#C7C7CC` - For dividers, borders, and content separation.

**Dark Mode Support**
- **Primary Background (Dark)**: `#000000` - Main background in dark mode.
- **Secondary Background (Dark)**: `#1C1C1E` - Cards and grouped content in dark mode.
- **Primary Text (Dark)**: `#FFFFFF` - Main text in dark mode.
- **Secondary Text (Dark)**: `#8E8E93` - Secondary text in dark mode.

**Color Usage & Accessibility**
- All text-to-background contrast ratios meet WCAG AA standards (4.5:1 minimum).
- Color is never the sole indicator of information - icons, text, and patterns provide redundancy.
- Dynamic color support adapts to user's system preferences and accessibility settings.

### 2.2 Typography

**Font Family**
- **iOS**: SF Pro (System Font) with SF Mono for numerical data

**Type Scale (using Dynamic Type points)**
| Style Name    | Font Size | Weight   | Line Height | Use Case                     |
|:--------------|:----------|:---------|:------------|:-----------------------------|
| Large Title   | 34pt      | Bold     | 41pt        | Main portfolio value, app title |
| Title 1       | 28pt      | Bold     | 34pt        | Screen titles, major sections |
| Title 2       | 22pt      | Bold     | 28pt        | Currency names, section headers |
| Headline      | 17pt      | Semibold | 22pt        | Price values, emphasized data |
| Body          | 17pt      | Regular  | 22pt        | Main content, descriptions   |
| Callout       | 16pt      | Regular  | 21pt        | Secondary info, timestamps   |
| Subheadline   | 15pt      | Regular  | 20pt        | Market cap, volume data      |
| Footnote      | 13pt      | Regular  | 18pt        | Fine print, legal disclaimers |
| Caption 1     | 12pt      | Regular  | 16pt        | Chart labels, tiny metadata  |
| Caption 2     | 11pt      | Regular  | 13pt        | Ultra-compact information    |

**Numerical Data Typography**
- **Price Display**: SF Mono, Semibold weight for consistent number alignment
- **Percentage Changes**: SF Mono, Medium weight with appropriate color coding
- **Small Numbers**: SF Mono, Regular weight for compact layouts

### 2.3 Layout & Spacing

**8pt Grid System**
- All spacing and sizing use multiples of 8pt (8, 16, 24, 32, 40, 48...).
- **Screen Margins**: 16pt horizontal padding for main content areas.
- **Component Padding**: 
  - Internal card padding: 16pt
  - Button padding: 12pt vertical, 24pt horizontal
  - List item padding: 16pt vertical, 16pt horizontal
- **Element Gaps**: 
  - Related items: 8pt spacing
  - Distinct sections: 16pt spacing  
  - Major sections: 24pt+ spacing

**Corner Radius**
- **Small**: 8pt - Tags, small buttons, input fields
- **Medium**: 12pt - Cards, standard buttons
- **Large**: 16pt - Modal sheets, large cards
- **Capsule**: `height / 2` - Pill buttons, status indicators
- **Circle**: 50% - Avatars, icon-only buttons

**iOS Safe Areas & Adaptivity**
- Respect all safe area insets (top notch, bottom home indicator, side margins)
- Dynamic layout adaptation for different iPhone sizes (SE to Pro Max)
- iPad-specific layouts with sidebar navigation and multi-column content

## 3. Interaction & Motion
### 3.1 Navigation Model
- **Primary Navigation**: Bottom Tab Bar with 5 tabs (Watchlist, Portfolio, Alerts, Community, Settings)
- **Screen Hierarchy**: NavigationStack with SwiftUI native push/pop transitions
- **Modal Views**: Sheet modals for focused tasks (Add Currency, Create Alert, Portfolio Sharing)
- **Transitions**: Native iOS transitions with contextual shared-element animations for currency navigation

### 3.2 Component States & Feedback
- **Touch States**: 
  - Light haptic feedback on tap
  - Visual scale-down (0.95x) during touch
  - Color state changes for interactive elements
- **Button States**: 
  - Default: Full opacity with primary colors
  - Pressed: Slight scale reduction with haptic feedback
  - Disabled: 40% opacity with desaturated colors
- **List Items**: 
  - Default state with subtle background
  - Highlighted state on touch with selection color
  - Swipe actions for secondary functions
- **Form Fields**: 
  - Default: Secondary background with border
  - Focused: Primary brand color border with subtle glow
  - Filled: Maintained focus styling until next field
  - Error: Red border with error message below
- **Real-time Data Updates**: 
  - Smooth value transitions with color-coded change indicators
  - Pulse animation for significant price movements
  - Loading states with skeleton UI that matches final content
- **System Feedback**: 
  - Success: Toast notifications with success color and checkmark
  - Errors: Alert dialogs for critical errors, toast for minor issues
  - Progress: Native iOS progress indicators and loading states

### 3.3 Haptic Feedback Strategy
- **Selection Feedback**: Light haptic for list selections and tab switches
- **Impact Feedback**: Medium haptic for button taps and confirmations  
- **Notification Feedback**: Success/warning/error haptics for system feedback
- **Custom Feedback**: Subtle haptic patterns for price alert notifications

## 4. Screen Designs (Text-Based Prototypes)

### Screen 1: Watchlist (Primary Tab)

**Screen Information**
- **Screen Name**: `WatchlistView`
- **Navigation Title**: "Watchlist" 
- **Purpose**: Real-time cryptocurrency price monitoring with quick access to detailed analysis

**Screen Layout Structure (iPhone Portrait)**
```
┌───────────────────────────────────┐
│        iOS Status Bar             │ (System managed)
├───────────────────────────────────┤
│        Navigation Bar             │ Height: 44pt
│  "Watchlist" [Search] [Add]       │ Large Title, collapsing
├───────────────────────────────────┤
│        Main Content Area          │ Flex: 1, Scrollable
│  ┌───────────────────────────────┐│ Padding: 16pt horizontal
│  │    [Portfolio Summary Card]   ││ Margin-Top: 8pt
│  ├───────────────────────────────┤│
│  │    [Currency Row: BTC]        ││ Margin-Top: 16pt
│  ├───────────────────────────────┤│
│  │    [Currency Row: ETH]        ││ Margin-Top: 1pt separator
│  ├───────────────────────────────┤│
│  │    [Currency Row: ADA]        ││ Margin-Top: 1pt separator
│  └───────────────────────────────┘│
├───────────────────────────────────┤
│            Tab Bar                │ Height: 49pt + Safe Area
│ [Watch][Portfolio][Alert][💬][⚙️] │ System tab bar styling
└───────────────────────────────────┘
```

**Component Details**
- **Navigation Bar**:
  - Large Title "Watchlist" collapses to inline on scroll
  - Trailing: Search button (magnifying glass) and Add button (+)
  - Primary brand color for interactive elements
- **Portfolio Summary Card**:
  - Secondary background, 12pt corner radius
  - Shows total portfolio value (Large Title style)
  - 24h change percentage with color coding
  - Horizontal layout with values and mini-chart
- **Currency Row**:
  - Height: 72pt minimum for accessibility
  - Leading: Currency icon (40x40pt) with symbol overlay
  - Center: Currency name (Headline) and symbol (Subheadline)
  - Trailing: Current price (Headline, SF Mono) and change % (Callout)
  - Real-time price updates with smooth transitions
  - Swipe actions: Add Alert, Remove from Watchlist

**States & Interactions**
- **Loading State**: Skeleton UI matching final layout structure
- **Empty State**: Illustration + "Add your first cryptocurrency" with CTA button  
- **Error State**: Retry button with clear error explanation
- **Pull to Refresh**: Native iOS refresh control with haptic feedback
- **Real-time Updates**: Smooth price animations with color-coded changes

### Screen 2: Currency Detail

**Screen Information**
- **Screen Name**: `CurrencyDetailView`
- **Navigation Title**: Dynamic (e.g., "Bitcoin")
- **Purpose**: Comprehensive analysis with interactive charts and market data

**Screen Layout Structure (iPhone Portrait)**
```
┌───────────────────────────────────┐
│        iOS Status Bar             │
├───────────────────────────────────┤
│        Navigation Bar             │
│  [←] "Bitcoin" [Alert] [Share]    │
├───────────────────────────────────┤
│        Scrollable Content         │
│  ┌───────────────────────────────┐│
│  │      [Price Header]           ││
│  ├───────────────────────────────┤│
│  │      [Interactive Chart]      ││ Height: 300pt
│  ├───────────────────────────────┤│
│  │      [Time Range Selector]    ││
│  ├───────────────────────────────┤│
│  │      [Market Stats Grid]      ││
│  ├───────────────────────────────┤│
│  │      [News & Analysis]        ││
│  └───────────────────────────────┘│
└───────────────────────────────────┘
```

**Component Details**
- **Price Header**:
  - Current price: Large Title (SF Mono, Bold)
  - 24h change: Headline with color coding and arrow indicator
  - Last updated timestamp: Caption 2 style
- **Interactive Chart**:
  - Line chart with gradient fill for visual appeal
  - Touch interaction shows crosshair with price/time details
  - Smooth zoom and pan gestures
  - Loading state with chart skeleton
- **Time Range Selector**:
  - Horizontal segmented control: 1D, 7D, 1M, 3M, 1Y, ALL
  - Primary brand color for selected state
  - Smooth chart data transitions between ranges
- **Market Stats Grid**:
  - 2x3 grid layout with market cap, volume, supply data
  - Each cell: Label (Subheadline) and Value (Body, SF Mono)
  - Card-style background with subtle borders

### Screen 3: Portfolio

**Screen Information**
- **Screen Name**: `PortfolioView`
- **Navigation Title**: "Portfolio"
- **Purpose**: Track holdings, transactions, and overall portfolio performance

**Screen Layout Structure (iPhone Portrait)**
```
┌───────────────────────────────────┐
│        Navigation Bar             │
│  "Portfolio" [Filter] [Add]       │
├───────────────────────────────────┤
│        Scrollable Content         │
│  ┌───────────────────────────────┐│
│  │    [Total Value Header]       ││
│  ├───────────────────────────────┤│
│  │    [Performance Chart]        ││
│  ├───────────────────────────────┤│
│  │    [Holdings Section]         ││
│  │    ├─ [Holding Row 1]         ││
│  │    ├─ [Holding Row 2]         ││
│  │    └─ [Show All Button]       ││
│  ├───────────────────────────────┤│
│  │    [Recent Transactions]      ││
│  └───────────────────────────────┘│
└───────────────────────────────────┘
```

### Screen 4: Community (Social Features)

**Screen Information**
- **Screen Name**: `CommunityView`
- **Navigation Title**: "Community"
- **Purpose**: Social investment platform with discussions and portfolio sharing

**Component Details**
- **Feed Layout**: Vertical scroll with discussion cards
- **Discussion Cards**: User avatar, post content, engagement metrics
- **Portfolio Sharing**: Anonymized portfolio visualization with privacy controls
- **Topic Navigation**: Segmented control for different discussion topics

### Screen 5: Create Alert

**Screen Information**
- **Screen Name**: `CreateAlertView`
- **Presentation**: Modal sheet
- **Purpose**: Configure price alerts with custom thresholds

**Form Elements**
- Currency selection with search
- Alert type: Above/Below price
- Threshold input with number pad
- Notification preferences
- Alert frequency settings

## 5. Component Library
### 5.1 Base Components

**Buttons**
- **Primary Button**: 
  - Background: Primary brand color (#007AFF)
  - Text: White, Headline weight
  - Padding: 12pt vertical, 24pt horizontal
  - Corner radius: 8pt
  - Minimum touch target: 44x44pt
- **Secondary Button**: 
  - Border: 1pt Primary brand color
  - Text: Primary brand color, Headline weight
  - Background: Clear or secondary background
- **Destructive Button**:
  - Background: Error color (#FF3B30)
  - Text: White, Headline weight
  - Used for dangerous actions like "Remove from Portfolio"

**Text Fields**
- Background: Secondary background (#F2F2F7)
- Border: 1pt separator color, changes to primary brand when focused
- Corner radius: 8pt
- Padding: 12pt internal
- Label: Subheadline style above field
- Error state: Red border with error message below (Footnote style)

**Cards**
- Background: Secondary background (#F2F2F7) or white with subtle shadow
- Corner radius: 12pt
- Padding: 16pt internal
- Shadow: Subtle elevation for depth perception
- Used for currency rows, portfolio summaries, and content grouping

**Navigation Elements**
- **Tab Bar**: Native iOS tab bar with 5 tabs maximum
- **Navigation Bar**: Large title with collapsing behavior
- **Back Button**: iOS-native back button with proper navigation hierarchy
- **Modal Sheets**: Native sheet presentation with drag-to-dismiss

### 5.2 Financial-Specific Components

**Price Display**
- Font: SF Mono for consistent number alignment
- Size: Headline style for prominent prices
- Color: Dynamic based on positive/negative change
- Animation: Smooth transitions for real-time updates

**Percentage Change Indicator**
- Format: "+2.45%" or "-1.32%" with appropriate color
- Background: Subtle colored background for emphasis
- Arrow indicators: ↗️ for gains, ↘️ for losses

**Chart Components**
- Line charts with gradient fills
- Interactive crosshair for detailed data
- Time range selector integration
- Loading states with skeleton UI

**Currency Icon**
- Size: 40x40pt for list items, 60x60pt for headers
- Fallback: First letter of currency name with branded background
- Support for custom cryptocurrency logos

## 6. iPad Enhancements
### 6.1 Layout Adaptations
- **Split View**: Primary-detail layout with watchlist and currency detail
- **Sidebar Navigation**: Collapsible sidebar replacing bottom tabs
- **Multi-Column**: Portfolio and community sections utilize wider screens
- **Stage Manager**: Full window management support with proper sizing

### 6.2 iPad-Specific Interactions
- **Drag & Drop**: Reorder watchlist items and portfolio holdings
- **Apple Pencil**: Chart annotations and community content creation
- **Keyboard Shortcuts**: Full keyboard navigation support
- **External Display**: Support for extended displays and presentations

## 7. Internationalization & Accessibility
### 7.1 Localization Support (Phased Approach)
- **Dynamic Type**: All text scales with user accessibility preferences
- **Phase 1**: English-only with proper Dynamic Type and accessibility support
- **Phase 2**: Basic localization for Spanish, Japanese, German (text translation only)
- **Future Consideration**: RTL support evaluation requires dedicated RTL specialist and significant resources
- **Currency Formatting**: Basic USD formatting initially, locale formatting in later phases

### 7.2 Accessibility Features
- **VoiceOver**: Complete screen reader support with custom rotor controls
- **High Contrast**: Alternative color schemes for accessibility preferences
- **Reduced Motion**: Alternative animations for motion sensitivity
- **Voice Control**: Full voice navigation support

## 8. Developer Handoff
### 8.1 Design Assets
- **SF Symbols**: Consistent iconography using SF Symbols 4+
- **Color Assets**: Semantic color definitions supporting light/dark modes
- **Image Assets**: @2x and @3x resolutions for all custom graphics

### 8.2 SwiftUI Implementation Guide
```swift
// Theme.swift - Design System Implementation
import SwiftUI

enum AppColors {
    static let primaryBrand = Color.blue // iOS system blue
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let secondaryBackground = Color(.systemGroupedBackground)
    static let primaryText = Color.primary
}

enum AppFonts {
    static let largeTitle = Font.largeTitle.bold()
    static let title1 = Font.title.bold()
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let priceDisplay = Font.system(.headline, design: .monospaced).weight(.semibold)
}

enum Spacing {
    static let xs: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
}

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}
```

### 8.3 Performance Considerations (Battery-Conscious Design)
- **HTTP Polling Strategy**: 30-second background updates, 10-second foreground, respecting API limits
- **WebSocket Limitation**: Only during active trading sessions (>5 min continuous use), auto-disconnect after 30s idle
- **Chart Rendering**: 60fps on iPhone 12+, graceful degradation on older devices
- **Memory Management**: Aggressive cleanup of chart data, maximum 100MB working memory
- **Battery Optimization**: Conservative refresh rates, offline-first design with 24-hour cached data

### 8.4 OS Version Compatibility & Fallback Strategy
- **Target iOS**: 17.0+ (leveraging proven SwiftUI features)
- **Minimum iOS**: 16.0 (with feature detection and graceful degradation)
- **iPadOS**: Full feature parity with iPhone, plus iPad-specific enhancements
- **iOS 26 Preparation**: Design system ready for Liquid Glass implementation when available
- **Fallback Materials**: iOS 17/18 native materials (frosted glass, vibrancy effects) provide equivalent visual appeal
- **Progressive Enhancement**: Advanced features detect device capabilities and degrade gracefully
- **Performance Validation**: All animations and effects tested on minimum supported devices
- **watchOS**: Future consideration for basic portfolio monitoring

## 9. Technical Implementation Strategy

### 9.1 Design System Fallback Strategy
```swift
// Adaptive Material System
struct AdaptiveMaterial: View {
    var body: some View {
        if #available(iOS 26, *) {
            // Future: iOS 26 Liquid Glass implementation
            Color.clear.liquidGlassEffect()
        } else if #available(iOS 17, *) {
            // Current: iOS 17/18 materials
            Color.clear
                .background(.ultraThinMaterial)
                .overlay(Material.regular.opacity(0.1))
        } else {
            // Fallback: Basic blur effect
            Color(.systemBackground).opacity(0.9)
        }
    }
}
```

### 9.2 Performance Optimization Patterns
- **Chart Rendering**: Level-of-detail rendering based on device capabilities
- **Real-time Updates**: Intelligent batching and differential updates
- **Memory Management**: Automatic cleanup of unused chart data and price history
- **Battery Optimization**: Adaptive refresh rates based on app state and usage patterns

### 9.3 Accessibility Implementation
- **VoiceOver Integration**: Custom accessibility labels for financial data
- **Dynamic Type Scaling**: All typography scales appropriately with user preferences  
- **High Contrast Support**: Alternative color schemes for accessibility needs
- **Reduced Motion**: Simplified animations for motion sensitivity users

### 9.4 International Design Implementation
- **RTL Layout Detection**: Automatic layout mirroring for supported languages
- **Cultural Color Adaptation**: Region-appropriate color meanings and preferences
- **Typography Scaling**: Support for character-dense languages with appropriate spacing
- **Input Method Support**: Optimized layouts for different keyboard types

This design specification provides a comprehensive, technically feasible foundation for building a professional cryptocurrency portfolio application that feels native to iOS while providing sophisticated financial features and social investment capabilities with proper fallback strategies and performance considerations.