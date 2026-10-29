---
name: Sundial
description: A native macOS launchd scheduler that reads as a sunny day, with storms for failures.
colors:
  plate: "#FAF7F0"
  paper: "#FFFDF8"
  ink: "#073642"
  muted: "#4F646B"
  selection: "#EBE4D1"
  hairline: "#E9E4D8"
  horizon: "#CFC8B6"
  sun: "#A07800"
  sunlight: "#B58900"
  sky: "#1F6FA8"
  storm: "#DC322F"
  storm-text: "#B0201D"
  dusk: "#6E7C7C"
typography:
  title:
    fontFamily: "SF Pro Rounded, -apple-system, system-ui"
    fontSize: "17px"
    fontWeight: 600
  headline:
    fontFamily: "SF Pro Rounded, -apple-system, system-ui"
    fontSize: "13px"
    fontWeight: 700
  body:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "13px"
    fontWeight: 400
  callout:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "12px"
    fontWeight: 400
  subheadline:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "11px"
    fontWeight: 400
  caption:
    fontFamily: "SF Pro, -apple-system, system-ui"
    fontSize: "10px"
    fontWeight: 400
  mono:
    fontFamily: "SF Mono, ui-monospace, Menlo"
    fontSize: "12px"
    fontWeight: 400
rounded:
  row: "6px"
  well: "8px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "14px"
  xl: "20px"
components:
  run-row:
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    height: "40px"
  command-well:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.mono}"
    rounded: "{rounded.well}"
    padding: "8px 10px"
  status-header:
    textColor: "{colors.ink}"
    typography: "{typography.headline}"
    padding: "0 20px"
  log-view:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    typography: "{typography.mono}"
    padding: "12px 14px"
  menu-row:
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.row}"
    padding: "4px 9px"
  menu-popover:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    width: "320px"
  settings-sidebar-button:
    rounded: "{rounded.well}"
    padding: "7px 10px"
---

# Design System: Sundial

## Overview

**Creative North Star: "A Sunny Day"**

Sundial is a native Mac utility dressed as a day of weather. Healthy runs are sunshine, failures are storms, and the runs column opens on the sun's path across the day. The palette stays light and calm: near-white grounds with a faint warm tint in light, a soft neutral charcoal in dark. Solarized is the inspiration for that warm tint, the ink, and the accent hues (the sun's yellow carrying success, Solarized red carrying failure), not a source of literal beige or teal grounds.

Personality lives in color, weather glyphs, and the day arc; structure stays stock macOS. The window is a native three-column `NavigationSplitView` with system toolbars, segmented pickers, grouped forms, and a system-glass sidebar. Density is standard Mac list density. Status is never color-only: every state has its own glyph and a text label.

Every color token resolves four ways (light, dark, Increase Contrast light, Increase Contrast dark) through `Solar.color`. The frontmatter records the light value; the sidecar carries all four.

**Key Characteristics:**
- Light, calm grounds: warm-white plate for the runs column, paper for the window, output, settings, and the menu bar popover; soft charcoal in dark.
- Weather glyphs carry run state, each in its status tint.
- The day arc is the signature, above the runs list and in the menu bar popover.
- The accent is Solarized slate (base01, base00 in dark), so selection and controls stay in the palette.
- Native controls, navigation, and keyboard behavior throughout.

## Colors

Solarized-inspired and quiet: warm near-white in light, neutral charcoal in dark, Solarized ink, and three state hues: sun, sky, storm.

### Primary
- **Sun Gold** (sun): Succeeded glyph, the passed dots and elapsed path on the day arc, the sun body at the current time, and the menu row hover wash (18%). Status title text for succeeded runs.
- **Sunlight** (sunlight): Solarized yellow at fixed value in all appearances. Only as a translucent material: the arc's daylight fill (18% to 2% gradient) and log text selection (30%).

### Secondary
- **Sky Blue** (sky): Running. The rotating rays glyph, the running ring on the day arc, and the running status title.

### Tertiary
- **Storm Red** (storm): Failed and interrupted glyphs and failure diamonds on the arc.
- **Storm Text** (storm-text): Deeper red for failure text where storm would be too light to read: exit codes in rows, the Failed title, result values, settings errors.

### Neutral
- **Warm White Plate** (plate): Near-white with a faint warm tint; soft charcoal (#23272A) in dark. The runs column ground, the No Job Selected placeholder, and the default day arc ground.
- **Paper White** (paper): The lightest ground; a deeper charcoal (#1C1F21) in dark. The window container background (the toolbar background is hidden so the columns show through), the output column, Settings, empty detail, the command well, and the menu bar popover.
- **Ink** (ink): Solarized base02 in light, base2 in dark. Primary text and log text; the next-run ring on the arc.
- **Muted** (muted): Secondary text: labels, timestamps, durations.
- **Linen Hairline** (hairline): 1pt separators and the command well border. Faint by design; Increase Contrast darkens it.
- **Horizon Stone** (horizon): The arc's horizon line and dotted full-day path.
- **Dusk** (dusk): Never-run glyph and the moon on the arc.

### Named Rules
**The Weather Rule.** Run state maps to exactly one hue: sun for passed, sky for running, storm for failed and interrupted, dusk for never run. Nothing else borrows these hues for decoration.

**The Accent Is Not Status Rule.** `AccentColor` is Solarized slate: #586E75 (base01) in light and #657B83 (base00) in dark, so controls match the theme instead of system blue. Run state colors (sun, sky, storm) never stand in for selection.

**The Quiet Ground Rule.** Grounds stay near-white in light and neutral charcoal in dark. Solarized is the source of the warm tint and the accent hues, not literal beige or teal grounds.

**The Four Appearances Rule.** A new color is a `Solar.color` with light, dark, and both Increase Contrast values, never a single hex.

## Typography

**Display Font:** SF Pro Rounded (system `.rounded` design)
**Body Font:** SF Pro (system)
**Label/Mono Font:** SF Mono (system monospaced)

**Character:** System type at macOS text-style sizes. The rounded design is reserved for a few headings so they feel sunny without leaving the platform. Commands and logs are monospaced.

### Hierarchy
- **Title** (600, title2 17pt, rounded): "Sundial" in Settings. The run status in the output header uses rounded headline so it fits the toolbar.
- **Headline** (bold, 13pt, rounded): The day arc title ("Today") in the menu bar popover.
- **Body** (400, 13pt): Row names, values, the job summary grid. Use `monospacedDigit` wherever durations or times change.
- **Callout** (400, 12pt): The job summary grid and, in mono, the command.
- **Subheadline** (400, 11pt): Row detail lines (time, outcome, duration).
- **Caption** (400, 10pt): Header field labels.
- **Mono** (400, 12pt, SF Mono): Commands and log output.

### Named Rules
**The Rounded Headings Rule.** `.fontDesign(.rounded)` goes on status and identity headings only; body, rows, and logs stay in default SF Pro.

## Layout

A native three-column split: jobs sidebar, runs column (min 300, ideal 360, max 480pt), output detail. Settings is a 460pt grouped-form sheet over the window with no toolbar; its Done button sits inline at the trailing end of the last footer. The runs column leads with the day arc (All Runs) or a job summary (arc, command well, summary grid) as a non-selectable first section, followed by runs grouped by day. Run rows are 40pt tall with a 10pt gap between glyph and text. The output column puts its status line (glyph, status, job and start time, duration, result) in a toolbar item aligned with the 20pt content inset, then the command row (4pt top, 12pt bottom padding), a 1pt hairline, then the full-height log with 14 by 12pt insets. The menu bar popover is 320pt wide with 14pt content margins and 5pt row insets. The arc is 70pt tall in the window and 50pt in the popover. The job summary grid puts muted labels on the left and right-aligns their values.

## Elevation & Depth

Flat. There are no custom shadows and no tinted bands. Depth comes from the two grounds (plate behind the list, paper for the window, content wells, and output), 1pt hairlines, and the system-glass sidebar and toolbar. The window's container background is paper and the window toolbar background is hidden, so each column's ground runs up under the toolbar instead of a white bar. Never give the toolbar a solid background: it spans the whole window and flattens the floating sidebar. The only gradient is the day arc's faint daylight fill.

### Named Rules
**The Two Grounds Rule.** Plate holds lists; paper holds the window and content to read. A surface is one or the other, separated by a 1pt hairline, never a shadow, a tinted band, or a wash.

**The No Wash Rule.** Headers and bands sit on their column's ground. Status shows through the glyph and the status-tinted title, never through a tinted background.

## Shapes

Native shapes for native controls. Custom shapes are few: 8pt rounded rectangles for the command well and the Settings sidebar button, 6pt for menu row hover. Day arc marks use shape as well as color: filled circles (3.5pt radius) for passed, diamonds (5.5pt half-width) for failed and interrupted, a hollow sky ring for running, a hollow ink ring (8pt) for the next run. Each mark has a 3pt ground-colored halo so it reads over the path.

## Components

### Status Icon
Weather glyphs at 18 by 18pt, hierarchical rendering: `sun.max.fill` in sun (succeeded), `cloud.bolt.rain.fill` in storm (failed), `cloud.fill` in storm (interrupted), `rays` in sky rotating continuously (running; static under Reduce Motion), `sun.horizon` in dusk (never run). Always carries an accessibility label.

### Run Rows
- **Layout:** Status icon, a two-line stack (name or time; detail in subheadline), trailing duration in subheadline muted with monospaced digits.
- **Failure:** The detail line turns storm-text. Passed detail stays muted.
- **Selection:** One selection look whether or not the list has focus. `RowSelectionBackground` turns off the native table highlight and fills the selected row with selection (#EBE4D1 light, #384044 dark) in a 6pt rounded rectangle inset 10pt. Row text and glyphs keep their normal ink, muted, storm text, and status tints.

### Status Header
The top of the output column: a title-size status icon, the status title in rounded semibold in the status text tint, job and date in muted, a trailing Duration / Result grid, then the command in mono muted with icon-only borderless Copy Output and Show Log in Finder buttons. It sits on paper like the rest of the column, with no wash; status shows through the icon and the status-tinted title only. A 1pt hairline separates it from the log.

### Command Well
Paper fill, 1pt hairline border, 8pt corners, 8 by 10pt padding, callout mono, up to 4 lines, selectable.

### Log View
A native `NSTextView`: selectable, find bar enabled, not editable, 12pt monospaced in ink on paper, selection in sunlight at 30%. Follows the end of the log while a run is live.

### Navigation
Native sidebar with system glass and `.secondary` subtitles. Settings is a full-width button pinned to the sidebar bottom (8pt corners, quaternary fill selected, quinary on hover). The runs column's header is one toolbar item as wide as the column: the title and subtitle on the left, glass circle Run Now and More buttons on the right. A small segmented All / Failed picker sits in the runs list above the day groups.

### Menu Bar Popover
Paper ground, 320pt. Day arc titled "Today", a hairline, "Recent Runs" (headline) with up to 10 rows, a hairline, then View All Runs…, Quit Sundial. Choosing a run or View All Runs… closes the popover and opens the main window. Rows highlight with sun at 18% and 6pt corners on hover.

### Day Arc (signature)
The sun's path across 24 hours as a negative cosine from midnight to midnight, with the horizon at 6 AM and 6 PM. A horizon line and dotted full-day path in horizon; a faint daylight fill in sunlight above the horizon (18% at the top of the arc to 2% at the horizon); the elapsed path stroked 2pt in sun up to now; `sun.max.fill` (17pt) at now above the horizon, `moon.fill` (13pt, dusk) below. Today's runs sit on the path as status marks, failures drawn last so they are on top. No hour labels and no visible summary; the summary ("7 passed, 1 failed, 1 running. Next run at 12:00 PM.") is only the accessibility value. Updates every minute.

## Do's and Don'ts

### Do:
- **Do** take every color from `Solar`, defined with light, dark, and Increase Contrast values.
- **Do** keep `AccentColor` Solarized slate, and give list rows `RowSelectionBackground` so selection does not change with focus.
- **Do** pair every status color with its weather glyph and a text label.
- **Do** use storm-text, not storm, for failure text.
- **Do** use native SwiftUI controls, lists, forms, toolbars, and split views; put personality in color, glyphs, and the day arc.
- **Do** gate continuous motion on Reduce Motion, as the running rays do.
- **Do** separate surfaces with 1pt hairlines in hairline.

### Don't:
- **Don't** use system blue or a status hue for the accent; never use sun, sky, or storm to mark selection. Running is sky, the next run is ink.
- **Don't** use green checks or red crosses for status; the weather glyphs are the status vocabulary.
- **Don't** add shadows or card elevation; use the plate and paper grounds.
- **Don't** apply the rounded design to body text, rows, or logs.
- **Don't** add strong tinted bands or status washes behind headers.
- **Don't** use literal Solarized beige or teal for grounds; keep them light and calm.
