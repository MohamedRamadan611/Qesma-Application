# DESIGN.md — Qesma (قسمة) Mobile Design System & Engineering Spec
> **Version:** 1.0 (Developer & AI-Agent Edition / Vibe-Coding Ready)  
> **App Concept:** Social FinTech & Group Expense Ledger for the Arab & Egyptian Market  
> **Core Ethos:** *"Relationships come first; clean accounts keep friendships lasting."* Absolute transparency down to the piastre without social awkwardness.

---

## 1. Architecture & Global Setup

### 1.1 Viewport & Form Factor
* **Target Viewport:** Android Material 3 Mobile — `360px` to `390px` width × `800px` height.
* **Layout Direction:** Strict Right-to-Left (`dir="rtl"`). All flow sequences start from the right.
* **Base Spatial Grid:** 8dp / 8px grid system.
  * **Screen Edge Margins:** `16px` (`p-4` or `px-4`)
  * **Card Spacing:** `12px` to `16px` (`space-y-3` or `gap-3` / `gap-4`)
  * **Card Inner Padding:** `16px` (`p-4`)
  * **Touch Target Size:** Minimum `48×48px` on all buttons, chips, checkboxes, and interactive controls.

### 1.2 Typography & Font Stack
* **Font Family:**
  ```css
  font-family: 'IBM Plex Sans Arabic', 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  ```
* **Numeral Rule (Crucial):** Always use Western / Latin digits (`0-9`) for all monetary values, percentages, phone numbers, and dates. This ensures clean vertical alignment of decimals (`.00`) and tabular data across Arabic text.
* **Type Scale Tokens:**
  * **Display / Big Balance:** `32px` | Bold (`700`) | Line height `1.2`
  * **Screen Title (H1):** `22px` - `24px` | Bold (`700`) | Line height `1.3`
  * **Section / Card Heading (H2):** `18px` - `20px` | SemiBold (`600`) | Line height `1.35`
  * **Subheading / Metric Label:** `15px` - `16px` | Medium (`500`) | Line height `1.4`
  * **Body / Descriptions:** `13px` - `14px` | Regular (`400`) | Line height `1.5`
  * **Caption / Badges / Timestamps:** `11px` - `12px` | Medium (`500`) | Line height `1.2` (`whitespace-nowrap`)

---

## 2. Design Tokens & Color Palette

### 2.1 Brand & Neutral Surfaces
| Token Name | Hex Code | Tailwind Equivalent | Role & Usage |
| :--- | :--- | :--- | :--- |
| `primary` | `#0F766E` | `teal-700` | Primary brand, main CTAs, active tab icons, key frames |
| `primary-hover` | `#115E59` | `teal-800` | Pressed / hover state for primary buttons |
| `primary-light` | `#14B8A6` | `teal-500` | Secondary highlights, gradient stops |
| `primary-container` | `#F0FDFA` | `teal-50` | Soft tinted card backgrounds, info banners |
| `primary-border` | `#CCFBF1` | `teal-100` | Borders on tinted container cards |
| `surface-bg` | `#F8FAFC` | `slate-50` | Canvas body background (cool, glare-free off-white) |
| `surface-card` | `#FFFFFF` | `white` | Cards, modals, bottom sheets, list rows |
| `border-subtle` | `#E2E8F0` | `slate-200` | Card borders, dividers, timeline line |
| `text-primary` | `#0F172A` | `slate-900` | Primary headlines, amounts, bold text |
| `text-secondary` | `#475569` | `slate-600` | Subtitles, labels, descriptions |
| `text-muted` | `#94A3B8` | `slate-400` | Helper text, disabled states, timestamps |

### 2.2 Semantic Financial Tokens
| Financial State | Badge Label | Text / Icon Hex | Soft BG Hex | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Credit / Owed to you** | "لك" or "له" | `#15803D` (`green-700`) | `#DCFCE7` (`green-100`) | Positive net balance, someone owes you money |
| **Debt / You owe** | "عليك" | `#C2410C` (`orange-700`) | `#FEE2E2` (`red-100`) or `#FFEDD5` | Negative net balance, pending amount to pay |
| **Settled / Balanced** | "خالص 0.00 ج.م" | `#475569` (`slate-600`) | `#F1F5F9` (`slate-100`) | Zero balance, account reconciled |
| **Status: Pending** | "في انتظار التأكيد" | `#B45309` (`amber-700`) | `#FEF3C7` (`amber-100`) | Sender tapped "I paid", awaiting creditor approval |
| **Status: Confirmed** | "مؤكّد ومستلم ✔" | `#15803D` (`green-700`) | `#DCFCE7` (`green-100`) | Creditor clicked "Received funds", debt cleared |
| **Status: Disputed** | "فيه خلاف ⚠️" | `#B91C1C` (`red-700`) | `#FEE2E2` (`red-100`) | Creditor flagged "Haven't received", dispute review |

---

## 3. Directionality & RTL Ergonomics

1. **Back Buttons in Top App Bar:** Must point **Right** (`→` / `<svg> pointing right`) because the user navigates backward toward the previous screen in RTL.
2. **Forward / Drill-down Arrows on Cards:** Must point **Left** (`←` / `<svg> pointing left`) for drilling deeper into group or expense details.
3. **Text & Number Flow:**
   * Text labels align to the right (`text-right`).
   * Financial amounts append the currency: `720.00 ج.م` or `+330.00 ج.م`.
   * Date tags use `whitespace-nowrap` paired with a calendar icon to prevent multi-line wrapping.
4. **Action Progression:** Progress bars and timeline steps flow strictly right-to-left.

---

## 4. Component Patterns & UI Library

### 4.1 Group Card
* **Category Eyebrow Tag:** Placed in its own dedicated top chip row (e.g. `🏖️ رحلة`, `🏠 سكن`, `🍔 خروجة`) above the group title to avoid visual crowding.
* **Avatar / Icon:** `48×48px` rounded-2xl or circle with a soft tint.
* **Metrics:** Single-line last activity date + total expenses in bold Western digits + net balance badge on the opposite side.
* **Corner Radius:** `16px` (`rounded-2xl`).
* **Elevation / Shadow:** `shadow-sm` (`box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05)`).

### 4.2 Primary CTA Buttons
* **Full-Width Action Button:**
  * Height: `52px` (`h-[52px]`)
  * Radius: `14px` (`rounded-xl` or `rounded-2xl`)
  * Background: `#0F766E` (`bg-teal-700`), text white bold.
  * Active/Focus: `#115E59`.
* **Outlined Action Button:**
  * Border: `1.5px solid #0F766E` or `#E2E8F0`.
  * Padding: `12px 16px`.

### 4.3 Bottom Sheet Modal
* **Trigger:** Itemized split editor, multi-payer assigner, add member modal, payment drawer.
* **Structure:**
  * Drag handle centered at top: `w-8 h-1 rounded-full bg-slate-300 mx-auto my-3`.
  * Quick dismiss button: `✕` at the top corner.
  * Inner scrollable body with `pb-24` padding.
  * Fixed sticky bottom action bar containing the primary submit button.

### 4.4 Local Payment Handles (InstaPay & Wallets)
* **InstaPay Address (IPA):** Format `username@instapay`. Displayed with bank icon and a 1-tap copy button (`نسخ`).
* **Mobile Wallets:** Egyptian format `010XXXXXXXX` (Vodafone Cash, Orange, Etisalat, WE, Bank Wallet) with 1-tap copy button.
* **Payment Disclaimer:** Always include a reminder banner that Qesma records the ledger balance and does not initiate banking transfers directly.
* **Anti-Awkwardness Remind Rule ("ذكّره"):** Creditors can trigger a payment reminder notification a maximum of **once every 24 hours** to prevent social awkwardness.

---

## 5. Tailwind CSS Configuration Preset

```js
// tailwind.config.js snippet for Qesma
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#F0FDFA',
          100: '#CCFBF1',
          500: '#14B8A6',
          700: '#0F766E', // Primary CTA & Branding
          800: '#115E59',
        },
        financial: {
          owed: '#15803D',      // "له" (Owed to you)
          owedBg: '#DCFCE7',
          owe: '#C2410C',       // "عليك" (You owe)
          oweBg: '#FEE2E2',
          pending: '#B45309',   // Pending confirmation
          pendingBg: '#FEF3C7',
          disputed: '#B91C1C',  // Disputed
          disputedBg: '#FEE2E2',
        }
      },
      fontFamily: {
        arabic: ['"IBM Plex Sans Arabic"', '"IBM Plex Sans"', 'sans-serif'],
      },
      borderRadius: {
        '2xl': '16px',
        'xl': '14px',
      }
    }
  }
}
```

---

## 6. Prompt Engineering Guide for AI Coding Agents ("Vibe Coding")

When prompting Cursor, GitHub Copilot, Claude, or v0 to build Qesma screens, include these mandatory directives:

```markdown
Build a mobile screen for "Qesma" (قسمة), an Arabic group expense app:
1. Viewport: 360px-390px mobile, dir="rtl".
2. Typography: font-family 'IBM Plex Sans Arabic', 'IBM Plex Sans'.
3. Numerals: ALWAYS use Western digits (0-9) for currency, percentages, and dates (e.g. "500.00 ج.م", "2026-10-24").
4. Palette: Primary Deep Emerald Teal #0F766E. Owed to you = Green #15803D (#DCFCE7 bg). You owe = Orange-Red #C2410C (#FEE2E2 bg).
5. Cards: 16px border-radius, pure white (#FFFFFF) on an off-white background (#F8FAFC), 16px outer padding.
6. RTL Navigation: Back arrow in top bar points RIGHT (→). Drill-down arrows point LEFT (←).
```
