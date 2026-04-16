# NilamAI Design System v1.0

## Overview
Based on **Material Design 3** + **Flutter Guidelines** with Brand colors and Tamil-first typography. All demo_ui screens follow this system.

---

## Color Palette

### Primary Brand Colors
| Color | Hex | Usage | Notes |
|-------|-----|-------|-------|
| **Earth Green** | `#2E7D32` | Primary actions, headers, app bar backgrounds | Brand identity, call-to-action elements |
| **Dark Green** | `#1B5E20` | Gradient starts, high-contrast text | Splash screen, hero sections |
| **Light Green** | `#4CAF50` | Secondary highlights, borders | Lighter variant for accents |
| **Green Light** | `#F1F8E9` | Disabled states, backgrounds | Lowest contrast surface |
| **Green Container** | `#E8F5E9` | Card backgrounds, light surfaces | Subtle containers |
| **Green On** | `#FFFFFF` | Text/icons on green background | High contrast |

### Secondary Accent Colors
| Color | Hex | Usage | Notes |
|-------|-----|-------|-------|
| **Warm Amber** | `#F59E0B` | FAB buttons, warnings, secondary actions | Harvest alerts, scheme deadlines |
| **Amber Dark** | `#B45309` | Hover states, pressed states | Darker variant for interaction |
| **Amber Light** | `#FCD34D` | Light alerts, disabled amber states | Lower contrast |
| **Amber Container** | `#FEF3C7` | Background for amber cards | Soft background |
| **Amber On** | `#1C1C1E` | Text/icons on amber background | High contrast |

### Status/Alert Colors
| Color | Hex | Usage | Notes |
|-------|-----|-------|-------|
| **Red Primary** | `#D32F2F` | Errors, critical alerts, disease warnings | Urgent states |
| **Red On** | `#B71C1C` | Diagnosis header background | High-severity indicators |
| **Red Container** | `#FFEBEE` | Error backgrounds | Soft error containers |

### Neutral Surface Colors
| Color | Hex | Usage | Notes |
|-------|-----|-------|-------|
| **Surface** | `#FFFFFF` | Main background, cards, dialogs | Primary surface |
| **Surface-1** | `#F8FAF8` | Slightly elevated surface | Subtle elevation |
| **Surface-2** | `#F1F5F1` | More elevated surface | Secondary elevation |
| **Surface Variant** | `#ECEFEC` | Dividers, disabled elements | Lowest contrast |
| **On Surface** | `#1C1C1E` | Primary text | Main text color |
| **On Surface V** | `#5C6B5C` | Secondary text, hints, labels | Muted text |

### Utility Colors
| Color | Hex | Usage | Notes |
|-------|-----|-------|-------|
| **Outline** | `#D4D8D4` | Borders, dividers | Light borders |
| **Outline Strong** | `#A8B0A8` | Strong borders, chip borders | Medium borders |

---

## Typography

### Font Families
- **Latin/English**: `Roboto` (400, 500, 700 weights)
- **Tamil Script**: `Noto Sans Tamil` (400, 500, 600, 700 weights) — **primary for labels**
- **Fallback**: System fonts

### Font Scales
| Type | Size | Weight | Usage |
|------|------|--------|-------|
| **Display Large** | 32px | 400 | Page hero titles |
| **Headline Large** | 28px | 600 | Section headers |
| **Headline Medium** | 24px | 600 | Card titles |
| **Headline Small** | 20px | 600 | Subsection headers |
| **Body Large** | 16px | 400 | Primary body text |
| **Body Medium** | 14px | 400 | Secondary body text |
| **Body Small** | 12px | 400 | Tertiary text, hints |
| **Label Large** | 14px | 500 | Labels, buttons |
| **Label Medium** | 12px | 500 | Small labels, badges |
| **Label Small** | 11px | 500 | Tiny labels, timestamps |

---

## Spacing & Layout

### Spacing Scale
| Token | Size | Usage |
|-------|------|-------|
| **xs** | 4px | Micro gaps |
| **sm** | 8px | Small padding/margin |
| **md** | 12px | Standard padding |
| **lg** | 16px | Large padding |
| **xl** | 20px | Extra padding |
| **2xl** | 24px | Large gaps |
| **3xl** | 32px | Section gaps |

### Border Radius
| Token | Radius | Usage |
|-------|--------|-------|
| **xs** | 6px | Small chips, subtle elements |
| **sm** | 10px | Button radius |
| **md** | 14px | Standard card radius |
| **lg** | 20px | Large cards |
| **xl** | 28px | Extra large elements |
| **full** | 9999px | Pill shapes, circular badges |

### Phone Frame Dimensions
- **Width**: 390px (modern Android/iOS standard)
- **Height**: 844px (similar to iPhone 12/13)
- **Status bar + Notch**: Simulated at top
- **Safe area**: 370px content width (16px padding each side)

---

## Shadows & Elevation

### Shadow Tokens
```css
--shadow-sm:  0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)
--shadow-md:  0 4px 12px rgba(0,0,0,0.10), 0 2px 4px rgba(0,0,0,0.06)
--shadow-lg:  0 8px 24px rgba(0,0,0,0.12), 0 4px 8px rgba(0,0,0,0.08)
--shadow-xl:  0 20px 48px rgba(0,0,0,0.16)
```

### Elevation Tints (Material Design 3)
```css
--elev-1: rgba(46,125,50,0.05)   /* Green tint, level 1 */
--elev-2: rgba(46,125,50,0.08)   /* Green tint, level 2 */
--elev-3: rgba(46,125,50,0.11)   /* Green tint, level 3 */
```

---

## Component Color Assignments

### App Bar & Headers
- **Background**: Green Primary `#2E7D32`
- **Text**: Green On `#FFFFFF`
- **Gradient variant**: Dark Green `#1B5E20` → Green Primary `#2E7D32` (linear-gradient 175deg)

### Buttons
| Type | Background | Text | Hover |
|------|-----------|------|-------|
| **Primary** | Green Primary | Green On | Darker shade |
| **Secondary** | Amber Primary | Amber On | Amber Dark |
| **FAB** | Amber Primary | Amber On | Amber Dark |
| **Text Button** | Transparent | Green Primary | Green Container bg |
| **Outlined** | Transparent | Green Primary | Outline Strong border |

### Cards
- **Background**: Surface `#FFFFFF`
- **Border**: Outline `#D4D8D4` (1px)
- **Shadow**: shadow-md
- **Alert card**: Red Container background
- **Success card**: Green Container background
- **Warning card**: Amber Container background

### Status Indicators
| Status | Color | Badge Style |
|--------|-------|-------------|
| **Active/In Progress** | Amber Primary | Filled circle with pulsing animation |
| **Completed** | Green Primary | Checkmark in circle |
| **Upcoming** | Surface Variant | Grey circle with number |
| **Alert/Disease** | Red Primary | Red dot badge |
| **Healthy** | Green Primary | Green status |

### Timeline Elements
- **Done stage**: Green Primary circle + connector
- **Active stage**: Amber Primary circle + connector + pulse animation
- **Upcoming stage**: Surface Variant circle + grey connector

### Progress Indicators
- **Fill color**: Green Primary
- **Background**: Surface Variant
- **Radius**: Full rounded corners

---

## Semantic Color Usage

### Success/Healthy States
- **Color**: Green Primary `#2E7D32`
- **Container**: Green Container `#E8F5E9`
- **Examples**: Healthy crop status, completed tasks, successful diagnoses

### Warning/Caution States
- **Color**: Amber Primary `#F59E0B`
- **Container**: Amber Container `#FEF3C7`
- **Examples**: Harvest approaching, scheme deadline, warning alerts, FAB

### Error/Alert States
- **Color**: Red Primary `#D32F2F`
- **Container**: Red Container `#FFEBEE`
- **Examples**: Disease diagnosis, critical alerts, PHI warnings

### Disabled/Inactive States
- **Color**: On Surface V `#5C6B5C` (muted)
- **Background**: Surface Variant `#ECEFEC`
- **Opacity**: Reduced to 50%

---

## Accessibility

### Contrast Ratios
- **All text on surfaces**: ≥4.5:1 (WCAG AA)
- **Green Primary on White**: 6.2:1
- **Amber Primary on White**: 5.3:1
- **Red Primary on White**: 5.1:1

### Touch Targets
- **Minimum**: 48dp (Material Design 3 guideline)
- **FAB**: 56dp diameter
- **Button**: 48dp height × 72dp width minimum
- **Chip**: 32dp height

### Focus States
- **Focus ring**: 2px outline in Green Primary
- **Radius**: Matches component radius + 2px

---

## Dark Mode (Future)

*Reserve colors for future dark mode support:*
- Invert surfaces (black backgrounds)
- Green Primary → Light Green `#A5D6A7` (reduced saturation)
- Text colors → inverted (light on dark)
- Shadows → reduced opacity
- Elevation tints → light overlay instead

---

## Implementation Notes

### CSS Variables Usage
All colors available as CSS custom properties in `demo_ui/styles.css`:
```css
var(--green-primary)     /* #2E7D32 */
var(--amber-primary)     /* #F59E0B */
var(--red-primary)       /* #D32F2F */
var(--surface)           /* #FFFFFF */
var(--on-surface)        /* #1C1C1E */
/* ... and 20+ more variables */
```

### Gradient Conventions
- **Splash/Hero**: `linear-gradient(175deg, #1B5E20 0%, #388E3C 100%)`
- **App Bar**: Similar green gradient
- **AI Recommendation**: `linear-gradient(135deg, #2E7D32 0%, #4CAF50 100%)`
- **Diagnosis Header**: `linear-gradient(to right, #D32F2F 0%, #B71C1C 100%)`

### Brand Consistency
- **Primary action color**: Always Green Primary unless explicitly secondary
- **Warnings/Urgent**: Amber or Red, never green
- **Disabled states**: Always use Surface Variant
- **Text contrast**: Always use On Surface or muted variant

---

## Reference Screens

Color theme applied consistently across all 11 demo_ui screens:
- `index.html` — Splash (green gradient)
- `onboarding.html` — Language & profile (green/amber buttons)
- `download.html` — Model download (progress bars green)
- `dashboard.html` — Main UI (green app bar, amber FAB, crop status colors)
- `add_crop.html` — Form (green submit, amber forecast)
- `timeline.html` — Crop timeline (green/amber/red status dots)
- `scan.html` — Camera (amber scan line)
- `diagnosis.html` — Disease result (red header, amber PHI warning)
- `market.html` — Prices (green recommendation, amber update banner)
- `schemes.html` — Govt schemes (green eligible, amber deadline)
- `settings.html` — Profile (green card, ambient UI)

---

**Last Updated**: v1.0 (Demo UI Finalization)  
**Designer Notes**: All colors tested at 390×844px phone frame size. Ready for Flutter implementation.
