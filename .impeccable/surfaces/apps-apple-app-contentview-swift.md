---
version: 1
slug: "apps-apple-app-contentview-swift"
primary_target: "apps/apple/App/ContentView.swift"
related_targets: ["apps/apple/App/MenuBarView.swift"]
---

# Main window and menu bar

Scope: the Sundial main window (sidebar, runs, output, settings, job editor) and the menu bar popover. Visitor mode: Operate.

Audience and task: developers checking whether scheduled commands passed, and reading output when one failed. Constraints: native SwiftUI controls and navigation, light and dark, Increase Contrast, Reduce Motion, status never color-only.

## Direction contract

FORM: Solarized fused with the sundial's day arc. seed:da901490f6b17eff
THESIS: The app is a sunny day. Healthy runs read as sunshine, failures as storms. It refuses the grey three-column utility with green checks.
OWN-WORLD: Solarized base3/base2 grounds in light, base03/base02 in dark, yellow and orange as the sun, Solarized red for storms. SF Pro with rounded headings; logs in SF Mono on Solarized log colors. Weather glyphs carry state.
STORY: At a glance: how today went, where the sun is now, and what runs next.
FIRST VIEWPORT: The runs column opens on a day arc, the sun's path across 24 hours. Today's runs sit on the arc as status-colored marks, the sun at the current time and a hollow ring at the next run.
SIGNATURE: The day arc, shown above the runs and in the menu bar popover.
RAISES: Orange is reserved for actions and selection (from the warm consumer app). Hairline separators at one pixel (from the reference-setting engine).
