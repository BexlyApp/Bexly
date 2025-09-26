# Bexly Design System & UI Guidelines

## Overview
This document defines the design principles, UI patterns, and visual guidelines for the Bexly app to ensure consistency and maintainability across all screens and components.

## Core Design Principles

### 1. Readability First
- **Minimum font weights**: Never use weights below 500 for body text
- **Contrast ratios**: Maintain WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
- **Text opacity**: Never reduce text opacity below 0.87 for primary text

### 2. Visual Hierarchy
- Clear distinction between interactive and non-interactive elements
- Consistent use of elevation and shadows
- Progressive disclosure of information

### 3. Responsive & Adaptive
- Support for light and dark themes
- Scalable typography (0.8x to 1.2x)
- Responsive breakpoints for mobile, tablet, and desktop

## Typography

### Font Family
- **Primary**: System default (San Francisco on iOS, Roboto on Android)
- **Numeric**: Urbanist (for numbers and amounts)

### Text Styles & Usage

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| **Display Large** | 46px | 900 (Black) | Hero headings, splash screens |
| **Display Medium** | 38px | 900 (Black) | Page titles |
| **Display Small** | 32px | 900 (Black) | Section headers |
| **Headline Large** | 26px | 900 (Black) | Card titles |
| **Headline Medium** | 22px | 800 (Extra Bold) | Subsection headers |
| **Headline Small** | 20px | 700 (Bold) | List headers |
| **Title Large** | 18px | 600 (Semi Bold) | Button text, important labels |
| **Title Medium** | 16px | 600 (Semi Bold) | Navigation items |
| **Title Small** | 14px | 600 (Semi Bold) | Tab labels |
| **Body Large** | 16px | 500 (Medium) | Primary content |
| **Body Medium** | 14px | 500 (Medium) | Secondary content |
| **Body Small** | 12px | 500 (Medium) | Captions, hints |
| **Label Large** | 16px | 600 (Semi Bold) | Form labels |
| **Label Medium** | 14px | 600 (Semi Bold) | Chip labels |
| **Label Small** | 12px | 600 (Semi Bold) | Tags, badges |

### Typography Rules
1. **Never use font weight below 500** for body text
2. **Headers must use weight 700+** for proper hierarchy
3. **Interactive elements** (buttons, links) use weight 600+
4. **Numeric values** always use Urbanist font family
5. **Line height**: 1.2-1.5x font size depending on context

## Color System

### Primary Colors
- **Primary**: #5B21B6 (Purple)
- **Primary Light**: #7C3AED
- **Primary Dark**: #4C1D95
- **On Primary**: White

### Semantic Colors
- **Success**: #10B981 (Green)
- **Warning**: #F59E0B (Amber)
- **Error**: #EF4444 (Red)
- **Info**: #3B82F6 (Blue)

### Neutral Colors
- **Background Light**: #FAFAFA
- **Background Dark**: #121212
- **Surface Light**: White
- **Surface Dark**: #1E1E1E
- **Text Primary**: rgba(0,0,0,0.87) / rgba(255,255,255,0.87)
- **Text Secondary**: rgba(0,0,0,0.60) / rgba(255,255,255,0.60)

### Color Usage Rules
1. **Text on colored backgrounds** must always be white or very light
2. **Never use pure black** (#000000) - use #121212 minimum
3. **Opacity for text**:
   - Primary text: 87%
   - Secondary text: 60%
   - Disabled text: 38%
4. **Interactive elements** must have distinct hover/pressed states

## Spacing System

Using 4px base unit:
- **spacing4**: 4px (extra small)
- **spacing8**: 8px (small)
- **spacing12**: 12px
- **spacing16**: 16px (default)
- **spacing20**: 20px
- **spacing24**: 24px (large)
- **spacing32**: 32px
- **spacing48**: 48px (extra large)

### Spacing Rules
1. **Consistent padding**: 16px minimum for touchable areas
2. **Card padding**: 16-20px
3. **Screen margins**: 20px on mobile, 24px on tablet
4. **List item spacing**: 12px between items
5. **Section spacing**: 24-32px between major sections

## Components

### Buttons
- **Minimum height**: 48px
- **Corner radius**: 8px
- **Text weight**: 600 (Semi Bold)
- **Padding**: 16px horizontal, 12px vertical

Types:
1. **Primary**: Filled with primary color
2. **Secondary**: Tonal/outlined
3. **Text**: No background, primary color text
4. **Icon**: 48x48px touch target

### Input Fields
- **Height**: 56px
- **Border radius**: 8px
- **Border width**: 1px (unfocused), 2px (focused)
- **Label**: Always visible (floating or above field)
- **Helper text**: 12px, weight 500

### Cards
- **Border radius**: 12px
- **Elevation**: 2dp (light theme), border (dark theme)
- **Padding**: 16-20px
- **Spacing between cards**: 12px

### Bottom Sheets
- **Handle**: 4x32px, centered
- **Corner radius**: 24px (top only)
- **Max width**: 640px on large screens
- **Padding**: 20px

### Dialogs
- **Width**: 280px (mobile), 400px (tablet)
- **Corner radius**: 16px
- **Title**: 20px, weight 700
- **Body**: 16px, weight 500
- **Actions**: Right-aligned, 8px spacing

## Elevation & Shadows

| Level | Usage | Light Theme | Dark Theme |
|-------|-------|------------|------------|
| 0 | Background | No shadow | No elevation |
| 1 | Cards, sheets | 0 2px 4px rgba(0,0,0,0.1) | Surface + 5% white |
| 2 | Raised buttons | 0 4px 8px rgba(0,0,0,0.15) | Surface + 8% white |
| 3 | Dialogs, menus | 0 8px 16px rgba(0,0,0,0.2) | Surface + 11% white |
| 4 | FAB, modals | 0 12px 24px rgba(0,0,0,0.25) | Surface + 14% white |

## Icons

### Sizes
- **Small**: 16px
- **Default**: 24px
- **Medium**: 32px
- **Large**: 48px

### Rules
1. Use **HugeIcons** library for consistency
2. **Stroke weight**: 1.5-2px
3. **Touch targets**: Minimum 48x48px
4. Icon color should match text color at same hierarchy level

## Animation & Transitions

### Duration
- **Instant**: 0ms (state changes)
- **Fast**: 200ms (micro-interactions)
- **Normal**: 300ms (standard transitions)
- **Slow**: 500ms (complex animations)

### Easing
- **Standard**: cubic-bezier(0.4, 0.0, 0.2, 1)
- **Decelerate**: cubic-bezier(0.0, 0.0, 0.2, 1)
- **Accelerate**: cubic-bezier(0.4, 0.0, 1, 1)

## Accessibility

### Requirements
1. **Touch targets**: Minimum 48x48px
2. **Text scaling**: Support 0.8x to 1.2x
3. **Color contrast**: WCAG AA compliant
4. **Focus indicators**: Visible keyboard navigation
5. **Screen reader**: Semantic labels for all interactive elements

## Platform Adaptations

### iOS
- Navigation bar blur effect
- Swipe-back gesture
- SF Symbols where appropriate

### Android
- Material You dynamic colors (Android 12+)
- System navigation gestures
- Material ripple effects

## Implementation Notes

### Theme Configuration
All design tokens are defined in:
- `lib/core/constants/app_colors.dart`
- `lib/core/constants/app_text_styles.dart`
- `lib/core/constants/app_spacing.dart`
- `lib/core/app.dart` (theme definitions)

### Best Practices
1. **Always use theme colors** - Never hardcode color values
2. **Use semantic text styles** - Access via `Theme.of(context).textTheme`
3. **Consistent spacing** - Use AppSpacing constants
4. **Responsive sizing** - Use MediaQuery and responsive_framework
5. **Test both themes** - Ensure readability in light and dark modes

### Component Library
Reusable components are in `lib/core/components/`:
- Buttons: `buttons/`
- Form fields: `form_fields/`
- Cards: Use `Container` with consistent decoration
- Dialogs: `dialogs/`
- Bottom sheets: `bottom_sheets/`

## Validation Checklist

Before releasing any UI changes:
- [ ] Text is readable (weight ≥ 500 for body text)
- [ ] Colors meet contrast requirements
- [ ] Touch targets are ≥ 48px
- [ ] Works in both light and dark themes
- [ ] Responsive on different screen sizes
- [ ] Follows spacing guidelines
- [ ] Uses correct typography hierarchy
- [ ] Interactive elements have clear states
- [ ] Animations are smooth (60fps)
- [ ] Accessible via keyboard/screen reader