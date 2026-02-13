# 📱 QuickSplit

**Student Name:** Kanthi  
**Platform:** Mobile (Android/iOS)  
**Framework:** Flutter + Dart

## Overview

QuickSplit is a mobile app that solves the friction of splitting restaurant bills among groups. It handles complex scenarios — shared appetizers, individual orders, and proportional tax/tip distribution — allowing users to generate a fair split in under 60 seconds.

## Features (MVP)

- **Bill Management** — Create, view history, and delete bills stored locally
- **Participant Management** — Add people manually or from "Recent Friends"
- **Item Entry** — Add/edit menu items with names and prices
- **Smart Assignment** — Assign items to one person or split among many (2-tap flow)
- **Proportional Calculation** — Tax & service charge distributed by each person's share (not flat)
- **Rounding Logic** — Handles the "penny problem" so no cents are lost
- **Share Text** — Generate copy-paste summary for LINE/WhatsApp

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter 3.41 (Dart 3.11) |
| State Management | Provider |
| Navigation | GoRouter |
| Local Database | SQLite (sqflite) |
| Architecture | Feature-First |

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
├── features/
│   ├── home/screens/home_screen.dart  # Bill history list
│   └── bill/
│       ├── screens/
│       │   ├── create_bill_screen.dart
│       │   ├── add_people_screen.dart
│       │   ├── bill_editor_screen.dart
│       │   ├── tax_tip_screen.dart
│       │   └── summary_screen.dart
│       └── widgets/
│           ├── add_item_sheet.dart
│           └── assign_item_sheet.dart
└── docs/
    └── UXUI_DESIGN.md                 # Complete UX/UI design document
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run tests
flutter test
```

## Screen Flow

```
Home → Create Bill → Add People → Bill Editor → Tax & Tip → Summary → Share/Close
```
