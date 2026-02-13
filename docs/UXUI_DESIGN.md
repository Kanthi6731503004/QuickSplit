# 🎨 QuickSplit — UX/UI Design Document

**Version:** 1.0  
**Date:** February 13, 2026  
**Author:** Kanthi  

---

## 1. Design Philosophy

QuickSplit follows a **"Speed-First"** design philosophy. The app's primary UX goal is:

> **Split any bill in under 60 seconds.**

### Design Principles
| Principle | How It's Applied |
|---|---|
| **Minimal Taps** | Assigning an item takes ≤ 2 taps (tap item → tap person avatars) |
| **Progressive Disclosure** | Only show tax/tip controls when user is ready to calculate |
| **Forgiving Design** | Undo/edit at any step; no destructive actions without confirmation |
| **Visual Feedback** | Real-time subtotals update as items are assigned |
| **Accessibility** | High-contrast text, minimum 44px touch targets, readable fonts |

---

## 2. Design System

### 2.1 Color Palette

```
Primary:       #1B5E20  (Deep Green — trust, money)
Primary Light: #4CAF50  (Green 500 — buttons, active states)
Accent:        #FF9800  (Orange — CTAs, highlights)
Error:         #F44336  (Red — warnings, delete)
Background:    #FAFAFA  (Off-white — main bg)
Surface:       #FFFFFF  (White — cards)
On Surface:    #212121  (Near-black — primary text)
Subtle Text:   #757575  (Grey 600 — secondary text)
Divider:       #E0E0E0  (Grey 300 — separators)
```

### 2.2 Typography (Google Fonts)

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

### 2.3 Spacing & Grid

- Base unit: **8dp**
- Screen padding: **16dp** horizontal
- Card padding: **16dp** all sides
- Item spacing: **8dp** (tight), **12dp** (default), **16dp** (loose)
- Card corner radius: **12dp**
- Button corner radius: **24dp** (pill shape)

### 2.4 Component Library

| Component | Spec |
|---|---|
| **Primary Button** | Green (#4CAF50), white text, 48dp height, pill shape, elevation 2 |
| **Secondary Button** | Outlined, green border, green text, 48dp height |
| **FAB (Floating Action Button)** | Orange (#FF9800), white icon, 56dp, bottom-right |
| **Input Field** | Outlined style, 48dp height, 12dp radius, grey border → green on focus |
| **Card** | White, 12dp radius, elevation 1, 16dp padding |
| **Avatar Chip** | 36dp circle with initial letter, colored bg, 8dp right margin |
| **Bottom Sheet** | White, 16dp top radius, drag handle 40×4dp centered |
| **Snackbar** | Bottom, 8dp margin, 8dp radius, dark bg (#323232) |

---

## 3. Screen-by-Screen Wireframes & Specs

---

### Screen 1: 🏠 Home Screen (Bill History)

**Route:** `/`  
**Purpose:** Entry point. Shows past bills and the primary CTA to create a new one.

```
┌─────────────────────────────────┐
│  ≡                    QuickSplit│  ← AppBar (green gradient)
│                                 │
│  ┌─────────────────────────────┐│
│  │  🔍 Search bills...         ││  ← Search bar (optional v2)
│  └─────────────────────────────┘│
│                                 │
│  Recent Bills                   │  ← Section header
│  ─────────────────────────────  │
│  ┌─────────────────────────────┐│
│  │ 🍕 Pizza Night              ││  ← Bill card
│  │ Feb 10, 2026 · 4 people     ││
│  │ Total: ฿1,240.00    ✅ Closed││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 🍜 Lunch with Team          ││
│  │ Feb 8, 2026 · 6 people      ││
│  │ Total: ฿2,100.00    📝 Draft ││
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │ 🥘 BBQ Party                ││
│  │ Feb 1, 2026 · 8 people      ││
│  │ Total: ฿4,560.00    ✅ Closed││
│  └─────────────────────────────┘│
│                                 │
│                                 │
│                                 │
│                          [ + ]  │  ← FAB (Orange) → Create Bill
│                                 │
│  ┌────┬────┬────┬────┐          │
│  │ 🏠 │ 📊 │ 👥 │ ⚙  │          │  ← Bottom Nav (optional v2)
│  │Home │Stats│Frnds│Set │          │
│  └────┴────┴────┴────┘          │
└─────────────────────────────────┘
```

**Interactions:**
- **Tap bill card** → Navigate to Bill Editor (`/bill/:id`)
- **Swipe left on card** → Reveal red "Delete" button
- **Tap FAB (+)** → Navigate to Create Bill screen
- **Long press bill** → Context menu (Edit, Delete, Duplicate)

**Empty State:**
```
┌─────────────────────────────────┐
│                                 │
│         🧾                      │
│                                 │
│    No bills yet!                │
│    Tap + to split your          │
│    first bill                   │
│                                 │
│       [ + New Bill ]            │  ← Primary button
│                                 │
└─────────────────────────────────┘
```

---

### Screen 2: 📝 Create Bill

**Route:** `/bill/new`  
**Purpose:** Quick setup — just name & date, get started fast.

```
┌─────────────────────────────────┐
│  ←                  Create Bill │  ← AppBar
│                                 │
│                                 │
│  Bill Name                      │  ← Label
│  ┌─────────────────────────────┐│
│  │  e.g. Pizza Night           ││  ← Text input (auto-focus)
│  └─────────────────────────────┘│
│                                 │
│  Date                           │  ← Label
│  ┌─────────────────────────────┐│
│  │  📅 Feb 13, 2026            ││  ← Date picker (defaults today)
│  └─────────────────────────────┘│
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│  ┌─────────────────────────────┐│
│  │       Next: Add People   →  ││  ← Primary button (full width)
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Validation:** Button disabled until bill name is non-empty.

---

### Screen 3: 👥 Add People

**Route:** `/bill/:id/people`  
**Purpose:** Add participants. Designed for speed with quick-add.

```
┌─────────────────────────────────┐
│  ←                   Add People │  
│                                 │
│  Who's splitting?               │  ← Heading
│                                 │
│  ┌──────────────────────┬──────┐│
│  │  Enter name...       │  +  ││  ← Input + Add button
│  └──────────────────────┴──────┘│
│                                 │
│  Added (4)                      │  ← Counter
│  ─────────────────────────────  │
│  ┌─────────────────────────────┐│
│  │ 🟢 P  Poom              ✕   ││  ← Person chip (removable)
│  ├─────────────────────────────┤│
│  │ 🔵 M  Mint              ✕   ││
│  ├─────────────────────────────┤│
│  │ 🟡 K  Kanthi            ✕   ││
│  ├─────────────────────────────┤│
│  │ 🟣 A  Alex              ✕   ││
│  └─────────────────────────────┘│
│                                 │
│  Recent Friends                 │  ← Section (from past bills)
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │ Na │ │ Bo │ │ Joy│ │ Tan│   │  ← Quick-add chips
│  └────┘ └────┘ └────┘ └────┘   │
│                                 │
│  ┌─────────────────────────────┐│
│  │      Next: Add Items    →   ││  ← Primary button
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

**Interactions:**
- **Type + tap "+"** → Add person to list
- **Press Enter** → Also adds person (keyboard submit)
- **Tap ✕** → Remove person (with undo snackbar)
- **Tap Recent chip** → Instantly add that person

**Validation:** Must have ≥ 2 people to proceed.

---

### Screen 4: 🧾 Bill Editor (Main Workspace)

**Route:** `/bill/:id`  
**Purpose:** The primary workspace. Shows items, assignments, and running totals.

```
┌─────────────────────────────────┐
│  ←  Pizza Night      📊 Summary │  ← AppBar with shortcut
│                                 │
│  ┌────┐┌────┐┌────┐┌────┐      │
│  │ 🟢P ││ 🔵M ││ 🟡K ││ 🟣A │      │  ← People bar (horizontal scroll)
│  │฿320 ││฿280 ││฿340 ││฿300 │      │  ← Running subtotals
│  └────┘└────┘└────┘└────┘      │
│  ─────────────────────────────  │
│                                 │
│  Items (5)                      │
│  ┌─────────────────────────────┐│
│  │ Margherita Pizza    ฿350    ││  ← Item card
│  │ 🟢P 🔵M 🟡K               ││  ← Assigned avatars
│  │ Split 3 ways · ฿116.67 each││  ← Split info
│  ├─────────────────────────────┤│
│  │ Pad Thai            ฿120    ││
│  │ 🟣A                        ││
│  │ Solo · ฿120.00             ││
│  ├─────────────────────────────┤│
│  │ ⚠️ Green Curry      ฿180   ││  ← Warning: unassigned!
│  │ Tap to assign people        ││  ← Hint text (orange)
│  ├─────────────────────────────┤│
│  │ Som Tum             ฿80     ││
│  │ 🟡K 🟣A                    ││
│  │ Split 2 ways · ฿40.00 each ││
│  ├─────────────────────────────┤│
│  │ Water (4x)          ฿80     ││
│  │ 🟢P 🔵M 🟡K 🟣A           ││
│  │ Split 4 ways · ฿20.00 each ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │    Calculate Split    →     ││  ← Primary button
│  └─────────────────────────────┘│
│                          [ + ]  │  ← FAB → Add Item bottom sheet
└─────────────────────────────────┘
```

**Interactions:**
- **Tap item card** → Opens assignment bottom sheet
- **Tap FAB (+)** → Opens "Add Item" bottom sheet
- **Swipe left on item** → Reveal "Edit" and "Delete" buttons
- **Tap person avatar in top bar** → Shows that person's items
- **Tap "Calculate Split"** → Checks for unassigned items, then → Tax & Tip

---

### Screen 4a: 📦 Add Item (Bottom Sheet)

```
┌─────────────────────────────────┐
│           ────                  │  ← Drag handle
│                                 │
│  Add Item                       │  ← Title
│                                 │
│  Item Name                      │
│  ┌─────────────────────────────┐│
│  │  e.g. Pad Thai              ││  ← Auto-focus
│  └─────────────────────────────┘│
│                                 │
│  Price (฿)                      │
│  ┌─────────────────────────────┐│
│  │  0.00                       ││  ← Numeric keyboard
│  └─────────────────────────────┘│
│                                 │
│  Quick assign (optional)        │  ← Assign right away
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │ 🟢P │ │ 🔵M │ │ 🟡K │ │ 🟣A │   │  ← Toggle-able avatars
│  └────┘ └────┘ └────┘ └────┘   │
│                                 │
│  ┌─────────────────────────────┐│
│  │         Add Item            ││  ← Primary button
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

---

### Screen 4b: 🔗 Assign Item (Bottom Sheet)

**Purpose:** The 2-tap assignment flow. Tap item → tap people.

```
┌─────────────────────────────────┐
│           ────                  │  ← Drag handle
│                                 │
│  Assign: Margherita Pizza       │  ← Item name
│  ฿350.00                        │  ← Price
│                                 │
│  Who's sharing this?            │
│                                 │
│  ┌─────────┐  ┌─────────┐      │
│  │  🟢 P   │  │  🔵 M   │      │  ← Large toggle buttons
│  │  Poom   │  │  Mint   │      │
│  │  ✓      │  │  ✓      │      │  ← Selected state
│  └─────────┘  └─────────┘      │
│  ┌─────────┐  ┌─────────┐      │
│  │  🟡 K   │  │  🟣 A   │      │
│  │  Kanthi │  │  Alex   │      │
│  │  ✓      │  │         │      │
│  └─────────┘  └─────────┘      │
│                                 │
│  Split: ฿116.67 each (3 ppl)   │  ← Live calculation
│                                 │
│  ┌──────────┐ ┌────────────────┐│
│  │ Everyone │ │     Done       ││
│  └──────────┘ └────────────────┘│
└─────────────────────────────────┘
```

**Key UX Decision:** "Everyone" button instantly selects all — optimized for shared items like water/appetizers.

---

### Screen 5: 💰 Tax & Tip

**Route:** `/bill/:id/tax`  
**Purpose:** Set tax and service charge with real-time preview.

```
┌─────────────────────────────────┐
│  ←                  Tax & Tip   │
│                                 │
│  Subtotal              ฿810.00  │  ← Sum of all items
│  ─────────────────────────────  │
│                                 │
│  VAT / Tax                      │
│  ┌─────────────────────────────┐│
│  │  ○───────●──────────── 7%   ││  ← Slider (0-20%)
│  └─────────────────────────────┘│
│  Tax amount:           ฿56.70   │
│                                 │
│  Service Charge                 │
│  ┌─────────────────────────────┐│
│  │  ○──────────●─────── 10%    ││  ← Slider (0-25%)
│  └─────────────────────────────┘│
│  Service amount:       ฿81.00   │
│                                 │
│  ─────────────────────────────  │
│  Grand Total           ฿947.70  │  ← Bold, large
│                                 │
│  Proportional split:            │
│  🟢 Poom    ฿320 → ฿374.40     │  ← Subtotal → with tax
│  🔵 Mint    ฿280 → ฿327.60     │
│  🟡 Kanthi  ฿340 → ฿397.80     │
│  🟣 Alex    ฿300 → ฿351.00     │
│  ─────────────────────────────  │
│  Check: ฿1,450.80 ✓            │  ← Verify sum matches
│                                 │
│  ┌─────────────────────────────┐│
│  │      See Full Summary   →  ││  ← Primary button
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

**Performance Req:** Slider moves must update all amounts in < 200ms.

---

### Screen 6: 📊 Summary Screen

**Route:** `/bill/:id/summary`  
**Purpose:** Final breakdown. The "screenshot-worthy" screen.

```
┌─────────────────────────────────┐
│  ←               Pizza Night 📤│  ← Share icon
│                                 │
│  ┌─────────────────────────────┐│
│  │  🍕 Pizza Night             ││  ← Bill header card
│  │  Feb 13, 2026               ││
│  │  4 people · 5 items         ││
│  │  VAT 7% + Service 10%      ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🟢 Poom                     ││  ← Person breakdown card
│  │ ──────────────────────────  ││
│  │  · Pizza (1/3)    ฿116.67  ││
│  │  · Water (1/4)    ฿20.00   ││
│  │  ──────────────────────────  ││
│  │  Subtotal         ฿136.67  ││
│  │  Tax (7%)         ฿9.57    ││
│  │  Service (10%)    ฿13.67   ││
│  │  ══════════════════════════  ││
│  │  TOTAL            ฿159.90  ││  ← Bold, green
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🔵 Mint                     ││
│  │  · Pizza (1/3)    ฿116.67  ││
│  │  · Water (1/4)    ฿20.00   ││
│  │  TOTAL            ฿159.90  ││
│  └─────────────────────────────┘│
│  ... (more cards)               │
│                                 │
│  ─────────────────────────────  │
│  Grand Total         ฿947.70   │
│  ─────────────────────────────  │
│                                 │
│  ┌──────────┐ ┌────────────────┐│
│  │ 📋 Copy  │ │ ✅ Close Bill  ││
│  └──────────┘ └────────────────┘│
└─────────────────────────────────┘
```

**Share Text Format:**
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

## 4. Interaction Patterns

### 4.1 The 2-Tap Assignment Flow
```
Step 1: Tap item in list → Bottom sheet opens
Step 2: Tap person avatars → Toggle on/off
Auto:   Amount updates in real-time
Close:  Tap "Done" or swipe down
```

### 4.2 Swipe Actions
| Direction | Target | Action |
|---|---|---|
| Swipe Left | Bill card (Home) | Reveal Delete |
| Swipe Left | Item card (Editor) | Reveal Edit + Delete |
| Swipe Left | Person chip | Reveal Remove |

### 4.3 Real-time Updates
- **People bar:** Subtotals update immediately when items are assigned
- **Tax sliders:** All amounts recalculate on drag (not just on release)
- **Item cards:** Show split info immediately after assignment

---

## 5. Color Assignment for People

Each person gets a deterministic color from this palette (wraps around):

| Index | Color | Hex |
|---|---|---|
| 0 | Green | #4CAF50 |
| 1 | Blue | #2196F3 |
| 2 | Amber | #FFC107 |
| 3 | Purple | #9C27B0 |
| 4 | Teal | #009688 |
| 5 | Red Orange | #FF5722 |
| 6 | Indigo | #3F51B5 |
| 7 | Pink | #E91E63 |

---

## 6. Error States & Edge Cases

| Scenario | UX Response |
|---|---|
| 0 people added | "Next" button disabled + helper text |
| 0 items added | "Calculate" button disabled + helper text |
| Unassigned items | Warning dialog before proceeding to tax |
| Item split 3 ways (rounding) | Round to 2 decimal places; add remainder to first person |
| Empty bill name | "Next" disabled, input shows error border |
| Delete bill | Confirmation dialog: "Delete 'Pizza Night'? This cannot be undone." |
| Network offline | No impact (offline-first) — no message needed |

---

## 7. Animation & Micro-interactions

| Element | Animation |
|---|---|
| Bill card appear | Fade in + slide up, staggered 50ms |
| Add person | Chip slides in from right |
| Remove person | Chip fades + shrinks out |
| FAB press | Scale down 90% on press, spring back |
| Bottom sheet | Slide up with spring physics |
| Avatar toggle (assign) | Scale bounce 1.0 → 1.2 → 1.0 |
| Number change (amounts) | Count-up animation (200ms) |
| Page transition | Shared axis (horizontal) |

---

## 8. Accessibility

- All interactive elements: minimum **44×44dp** touch target
- Color is never the only indicator (icons + labels always paired)
- Screen reader labels on all buttons and avatars
- Support for system font scaling (up to 200%)
- Sufficient contrast ratio: ≥ 4.5:1 for text, ≥ 3:1 for large text

---

## 9. Responsive Layout

| Screen Width | Layout |
|---|---|
| < 360dp | Compact: Stack elements vertically |
| 360-411dp | Default: Standard layout |
| 412dp+ | Comfortable: Extra padding, larger cards |
| Tablet 600dp+ | Two-column layout (items left, assignments right) |
