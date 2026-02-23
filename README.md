# 📱 QuickSplit

**Platform:** Mobile (Android/iOS)  
**Framework:** Flutter + Dart

---

## Overview

QuickSplit is a mobile app that solves the friction of splitting restaurant bills among groups. It handles complex scenarios — shared appetizers, individual orders, and proportional tax/tip distribution — allowing users to generate a fair split in **under 60 seconds**.

---

## Features (MVP)

| Feature | Description |
|---|---|
| **Bill Management** | Create, view history, and delete bills stored locally |
| **Participant Management** | Add people manually or from "Recent Friends" |
| **Item Entry** | Add/edit menu items with names and prices |
| **Smart Assignment** | Assign items to one person or split among many (2-tap flow) |
| **Proportional Calculation** | Tax & service charge distributed by each person's share (not flat) |
| **Rounding Logic** | Handles the "penny problem" so no cents are lost |
| **Share Text** | Generate copy-paste summary for LINE/WhatsApp |

---

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter 3.41 (Dart 3.11) |
| State Management | Provider |
| Navigation | GoRouter |
| Local Database | SQLite (sqflite) |
| Architecture | Feature-First |

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/Kanthi6731503004/QuickSplit.git
cd QuickSplit

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run tests
flutter test
```

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── theme/app_theme.dart           # Design system (colors, fonts, spacing)
│   ├── models/                        # Data models (Bill, Person, BillItem)
│   ├── database/database_helper.dart  # SQLite CRUD operations
│   ├── providers/bill_provider.dart   # Central state management
│   ├── services/split_calculator.dart # Pure calculation engine
│   └── router/app_router.dart         # GoRouter configuration
└── features/
    ├── home/screens/home_screen.dart  # Bill history list
    └── bill/
        ├── screens/
        │   ├── create_bill_screen.dart
        │   ├── add_people_screen.dart
        │   ├── bill_editor_screen.dart
        │   ├── tax_tip_screen.dart
        │   └── summary_screen.dart
        └── widgets/
            ├── add_item_sheet.dart
            └── assign_item_sheet.dart
```

---

## Screen Flow

```
Home → Create Bill → Add People → Bill Editor → Tax & Tip → Summary → Share/Close
```

---

## UX/UI Design

### Design Philosophy

QuickSplit follows a **"Speed-First"** design philosophy:

> **Split any bill in under 60 seconds.**

| Principle | How It's Applied |
|---|---|
| **Minimal Taps** | Assigning an item takes ≤ 2 taps (tap item → tap person avatars) |
| **Progressive Disclosure** | Only show tax/tip controls when user is ready to calculate |
| **Forgiving Design** | Undo/edit at any step; no destructive actions without confirmation |
| **Visual Feedback** | Real-time subtotals update as items are assigned |
| **Accessibility** | High-contrast text, minimum 44px touch targets, readable fonts |

---

### Design System

#### Color Palette

| Token | Hex | Usage |
|---|---|---|
| Primary | `#1B5E20` | Deep Green — trust, money |
| Primary Light | `#4CAF50` | Buttons, active states |
| Accent | `#FF9800` | CTAs, highlights |
| Error | `#F44336` | Warnings, delete |
| Background | `#FAFAFA` | Main background |
| Surface | `#FFFFFF` | Cards |
| On Surface | `#212121` | Primary text |
| Subtle Text | `#757575` | Secondary text |
| Divider | `#E0E0E0` | Separators |

#### Typography (Google Fonts)

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| Heading 1 | Poppins | 28sp | Bold (700) | Screen titles |
| Heading 2 | Poppins | 22sp | SemiBold (600) | Section headers |
| Heading 3 | Poppins | 18sp | Medium (500) | Card titles |
| Body 1 | Inter | 16sp | Regular (400) | Primary content |
| Body 2 | Inter | 14sp | Regular (400) | Secondary content |
| Caption | Inter | 12sp | Regular (400) | Labels, hints |
| Amount | Poppins | 20sp | Bold (700) | Money amounts |
| Total | Poppins | 32sp | Bold (700) | Final totals |

#### Spacing & Grid

- Base unit: **8dp**
- Screen padding: **16dp** horizontal
- Card padding: **16dp** all sides
- Item spacing: **8dp** (tight), **12dp** (default), **16dp** (loose)
- Card corner radius: **12dp**
- Button corner radius: **16dp** (squircle)

#### Component Library

| Component | Spec |
|---|---|
| **Primary Button** | Green (#4CAF50), white text, 52dp height, squircle (16dp radius), flat (0 elevation) |
| **Secondary Button** | Outlined, green border, green text, 52dp height, squircle |
| **Extended FAB** | Orange (#FF9800), white icon + label, squircle, flat, bottom-right |
| **Input Field** | Outlined style, 48dp height, 12dp radius, grey border → green on focus |
| **Card** | White, 12dp radius, elevation 1, 16dp padding |
| **Avatar Chip** | 36dp circle with initial letter, colored bg, 8dp right margin |
| **Bottom Sheet** | White, 16dp top radius, drag handle 40×4dp centered |
| **Snackbar** | Bottom, 8dp margin, 8dp radius, dark bg (#323232) |

---

**Share text format:**
```
🧾 QuickSplit: Pizza Night
📅 Feb 13, 2026

🟢 Poom: ฿159.90
🔵 Mint: ฿159.90
🟡 Kanthi: ฿312.45
🟣 Alex: ฿315.45

💰 Grand Total: ฿947.70
(incl. 7% VAT + 10% Service)

Split with QuickSplit ⚡
```

---

### Interaction Patterns

#### 2-Tap Assignment Flow

```
1. Tap item in list   → Bottom sheet opens
2. Tap person avatars → Toggle on/off (live calculation)
3. Tap "Done"         → Assignment saved
```

#### Swipe Actions

| Direction | Target | Action |
|---|---|---|
| Swipe Left | Bill card (Home) | Reveal Delete |
| Swipe Left | Item card (Editor) | Reveal Edit + Delete |
| Swipe Left | Person chip | Reveal Remove |

---

### Person Color Palette

Each participant gets a deterministic color (wraps around for 8+ people):

| # | Color | Hex |
|---|---|---|
| 0 | Green | `#4CAF50` |
| 1 | Blue | `#2196F3` |
| 2 | Amber | `#FFC107` |
| 3 | Purple | `#9C27B0` |
| 4 | Teal | `#009688` |
| 5 | Red Orange | `#FF5722` |
| 6 | Indigo | `#3F51B5` |
| 7 | Pink | `#E91E63` |

---

### Error States & Edge Cases

| Scenario | UX Response |
|---|---|
| 0 people added | "Next" button disabled + helper text |
| 0 items added | "Calculate" button disabled + helper text |
| Unassigned items | Warning dialog before proceeding to tax |
| Rounding (3-way split) | Round to 2 decimal places; remainder added to first person |
| Empty bill name | "Next" disabled, input shows error border |
| Delete bill | Confirmation dialog: "Delete 'Pizza Night'? This cannot be undone." |
| Network offline | No impact — app is offline-first |

---

### Animations & Micro-interactions

| Element | Animation |
|---|---|
| Bill card appear | Fade in + slide up, staggered 50ms |
| Add person | Chip slides in from right |
| Remove person | Chip fades + shrinks out |
| FAB press | Scale down 90% → spring back |
| Bottom sheet | Slide up with spring physics |
| Avatar toggle | Scale bounce 1.0 → 1.2 → 1.0 |
| Number change | Count-up animation (200ms) |
| Page transition | Shared axis (horizontal) |

---

### Accessibility

- All interactive elements: minimum **44×44dp** touch target
- Color is never the only indicator — icons + labels always paired
- Screen reader labels on all buttons and avatars
- System font scaling support (up to 200%)
- Contrast ratio: ≥ 4.5:1 for text, ≥ 3:1 for large text

---

### Responsive Layout

| Screen Width | Layout |
|---|---|
| < 360dp | Compact — stack elements vertically |
| 360–411dp | Default — standard layout |
| 412dp+ | Comfortable — extra padding, larger cards |
| Tablet 600dp+ | Two-column (items left, assignments right) |

---

## License

This project is for educational purposes.
