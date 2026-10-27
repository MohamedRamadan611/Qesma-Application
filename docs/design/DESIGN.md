---
name: Social FinTech & Shared Ledger
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3e4947'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6e7977'
  outline-variant: '#bdc9c6'
  surface-tint: '#006a63'
  primary: '#005c55'
  on-primary: '#ffffff'
  primary-container: '#0f766e'
  on-primary-container: '#a3faef'
  inverse-primary: '#80d5cb'
  secondary: '#565e74'
  on-secondary: '#ffffff'
  secondary-container: '#dae2fd'
  on-secondary-container: '#5c647a'
  tertiary: '#7d4200'
  on-tertiary: '#ffffff'
  tertiary-container: '#a15600'
  on-tertiary-container: '#ffe6d5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9cf2e8'
  primary-fixed-dim: '#80d5cb'
  on-primary-fixed: '#00201d'
  on-primary-fixed-variant: '#00504a'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  display-lg-mobile:
    fontFamily: IBM Plex Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: IBM Plex Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The brand personality merges high-trust consumer fintech with the relaxed, communal intimacy of Egyptian social gatherings—from weekend Sahel beach trips and shared Cairo flats to impromptu group dinners. It replaces awkward conversations about money with transparency, fairness, and effortless clarity.

The visual style is rooted in a refined **Modern Material 3** language, accented with subtle tactile affordances. It avoids sterile corporate banking tropes in favor of an inviting, human-centered aesthetic: crisp white modular surfaces, tactile pill chips, soft minted tints, and clear visual signposting. The experience balances financial precision with social warmth, projecting reliability, casual confidence, and modern Egyptian social connectivity.

## Colors

The palette delivers financial clarity while maintaining an approachable social atmosphere:

- **Primary (`#0F766E` Deep Emerald Teal):** Anchors primary action buttons, Floating Action Buttons (FAB), active bottom navigation indicators, and key structural headers.
- **Primary Container (`#CCFBF1` Mint Tint):** Paired with `#115E59` (Dark Teal text) for selected filters, group tags, and soft promotional panels.
- **Secondary (`#0F172A` Deep Slate):** Drives foundational structure, high-contrast headings, and high-emphasis body text, supported by `#334155` for secondary content.
- **Tertiary (`#D97706` Warm Amber):** Handles reminders, settlement alerts, receipt verification notices, and uneven split discrepancies, paired with `#FEF3C7` container backgrounds.
- **Neutral (`#64748B` Slate Grey):** Manages inactive icons, helper text, and subtle dividers against the `#F8FAFC` canvas base.

### Semantic Balances
Financial status tokens must remain visually distinct and culturally unambiguous:
- **Positive Net Balance ("له" / Lent / Is Owed):** Text `#059669`, background `#ECFDF5`.
- **Negative Net Balance ("عليه" / Borrowed / Owes):** Text `#E11D48`, background `#FFF1F2`.
- **Neutral / Settled ("خالص" / Zero Balance):** Text `#64748B`, background `#F1F5F9`.

Surfaces sit on `#F8FAFC`, with elevated components rendered in pure white (`#FFFFFF`) framed by hairline borders (`#E2E8F0`).

## Typography

Typography relies on IBM Plex Sans (with full Arabic glyph fidelity) to ensure balanced character heights, contemporary aesthetics, and strong legibility across dense data tables and receipts.

### Strict Numeral Rules
- **Western Arabic Numerals Exclusively:** All monetary numbers, split tallies, fractions, phone numbers, and dates must render using Western Arabic numerals (`0, 1, 2, 3, 4, 5, 6, 7, 8, 9`). Eastern digits (`٠-٩`) are explicitly disallowed.
- **Tabular Lining:** All numeric amounts, split percentages, and receipt calculations must enforce `font-feature-settings: "tnum" 1` for vertical column alignment.
- **Currency Suffix:** The Egyptian Pound currency token (`ج.م`) must always appear after the Western numerical value separated by a non-breaking space (e.g., `561.79 ج.م`).

## Layout & Spacing

The layout is built for Android mobile screens with a primary 4-column fluid grid, extending to 8 columns on tablets. Spacing is strictly based on an 8pt architectural rhythm, with 4pt micro-steps reserved for tight inline tags and icon-to-text gaps.

### RTL Grid & Alignment Rules
- **Native Right-to-Left (RTL):** The canvas reads right-to-left. Layout margins, trailing chevrons, card headers, and lead icons must invert automatically under RTL.
- **Amount & Action Anchoring:** In feed rows and member cards, user identification and profile avatars anchor to the right margin, while financial balances, directional badges ("له" / "عليه"), and disclosure chevrons anchor to the left margin.
- **Safe Margins:** Standard canvas edge margin is set to `1rem` (16px) on mobile viewports, expanding to `1.5rem` (24px) on tablet viewports.

## Elevation & Depth

Visual hierarchy uses clean surface separation, low-opacity ambient shadows, and hairline structural borders to preserve battery life and prevent visual noise under bright outdoor sunlight.

- **Level 0 (Base Canvas):** App canvas renders flat `#F8FAFC`.
- **Level 1 (Cards & Feed Items):** Pure `#FFFFFF` surface accompanied by a hairline border (`1px solid #E2E8F0`) and an ambient shadow: `box-shadow: 0px 1px 3px rgba(15, 23, 42, 0.04), 0px 4px 8px rgba(15, 23, 42, 0.02)`.
- **Level 2 (Active Cards, Filters, Popovers):** Elevated surface with `box-shadow: 0px 4px 12px rgba(15, 23, 42, 0.06), 0px 2px 4px rgba(15, 23, 42, 0.03)`.
- **Level 3 (Modal Sheets & Navigation Bars):** `#FFFFFF` surface bounded by an inverted top-edge border (`1px solid #E2E8F0`) and depth shadow: `box-shadow: 0px -4px 16px rgba(15, 23, 42, 0.08)`.
- **Level 4 (Floating Action Button):** Teal primary `#0F766E` with an ambient glow shadow: `box-shadow: 0px 4px 14px rgba(15, 118, 110, 0.35)`.

## Shapes

The interface embraces a friendly yet orderly geometry. Standard UI elements utilize 8px corners, while large touchpoints, cards, and bottom sheets adopt softer profiles:

- **Buttons & Input Fields:** `rounded-lg` (8px to 12px) for balanced finger tap targets.
- **Cards, Activity Containers, & Modals:** `rounded-2xl` (16px) for interior list cards; `rounded-3xl` (24px) for trip summary hero panels and Material 3 bottom sheets.
- **Pill Elements:** Interactive filter chips, status badges ("له", "عليه", "خالص"), and participant avatars use full round pills (`rounded-full`).

## Components

### Buttons
- **Primary Action:** Solid `#0F766E` background with `#FFFFFF` text. Height is 48px, corner radius is 12px, font is `label-lg`. Active tap states show a slight scale-down (`0.98`) with a darker overlay `#0D5D57`.
- **Secondary Action:** Outlined with `1.5px solid #CBD5E1`, text color `#0F172A`. In dark container contexts, use `#CCFBF1` surface with `#115E59` text.
- **Floating Action Button (FAB):** 56x56px pill or rounded square (16px radius) centered or anchored to the bottom-left in RTL layouts, sporting a vibrant white split icon (`+`).

### Financial Status Chips & Badges
- **"له" (Is Owed):** Emerald badge (`#ECFDF5` background, `#059669` label, `rounded-full`, 4px vertical / 10px horizontal padding).
- **"عليه" (Owes):** Coral badge (`#FFF1F2` background, `#E11D48` label, `rounded-full`, 4px vertical / 10px horizontal padding).
- **"خالص" (Settled):** Slate badge (`#F1F5F9` background, `#64748B` label, `rounded-full`, 4px vertical / 10px horizontal padding).

### Input Fields
- **Amount Inputs:** Prominently sized fields displaying tabular Western numerals in `headline-lg` weight with a static `ج.م` prefix/suffix positioned in accordance with RTL.
- **Form Fields:** Height of 52px, surface `#FFFFFF`, outline `1px solid #CBD5E1`. Focus transitions to a `2px solid #0F766E` border with no harsh glow. Error state uses `#E11D48` text and border.

### Expense & Group Cards
- **Feed Item Card:** 16px internal padding, `rounded-2xl`, `#FFFFFF` surface with hairline border `#E2E8F0`. Features member avatar or category icon on the right, title and payer in the center, and amount/balance status aligned strictly on the left.
- **Hero Balance Card:** Displayed at the top of group views. Deep Teal surface (`#0F766E`) or light mint container (`#CCFBF1`) presenting the user's personal net share prominently, followed by quick action buttons for "تسوية" (Settle Up) and "إضافة مصاريف" (Add Expense).

### Lists & Split Breakdown Rows
- Items are divided by subtle lines (`#F1F5F9`). Checkboxes and participant toggles sit on the right margin in RTL mode, followed by user avatar, display name, and auto-calculated proportional share on the left.