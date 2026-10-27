# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

Sundial is a native macOS app (macOS 27+, SwiftUI with small AppKit bridges). Impeccable has no `macos` platform value; `ios` is recorded so Apple HIG guidance loads. Apply it with Mac conventions: pointer and keyboard, menu bar, toolbars, sidebars, and resizable windows instead of touch targets and tab bars.

## Users

Developers and technical Mac users who run their own shell commands on a schedule: backups, syncs, ingests, `mise` tasks, and maintenance scripts. They open Sundial occasionally to check that recent runs passed, or right after a failure to read the output. Most of the time Sundial sits in the menu bar. (Inferred from the repository and README; the user asked not to be interviewed.)

## Product Purpose

Schedule local commands with launchd and show at a glance whether each run passed or failed. Success means the user trusts their jobs are running without opening Terminal, `launchctl`, or log files, and can find and read a failure in seconds.

## Positioning

A friendly, native front end to launchd: real launch agents that run whether or not the app is open, calendar schedules that coalesce missed runs after sleep, and 30 days of per-run output, exit status, and duration. It is a dependency-free Mac app, not a cron wrapper, server, or cloud scheduler.

## Operating Context

- Jobs are a name, a `zsh -c` command, a working directory, and a schedule (every N minutes or hours aligned to the clock, daily, or weekly).
- The main window has three columns: jobs in the sidebar, runs grouped by day in the middle, and the selected run's output on the right. Settings shows in the detail column.
- The menu bar item lists the 10 most recent runs and opens the main window to a run.
- Users check status occasionally and read long, monospaced command output when something fails.

## Capabilities and Constraints

- Run states: running, succeeded (exit 0), failed (non-zero exit or signal), interrupted, and never run.
- Native, dependency-free SwiftUI. No third-party UI packages, no notifications, no Dock icon while only the menu bar item is shown.
- Must work in light and dark appearance, with system accessibility settings (Increase Contrast, Reduce Motion, Reduce Transparency), and with the system accent color left to the user where macOS expects it.
- Distributed as a signed, notarized GitHub release and the `sundial` Homebrew cask, not through the App Store.

## Brand Commitments

- The name Sundial and the sun-and-time motif are the identity. The user wants the interface to embrace it instead of looking bland.
- The app icon (`apps/apple/App/Assets.xcassets/AppIcon.appiconset`) is a cream sundial plate with a brown gnomon and shadow, on a warm orange-to-amber gradient with a pale sun.
- `SundialGlyph` draws the template menu bar glyph in code (dial, gnomon, shadow).
- Voice is plain, short, and literal ("Run Now", "No runs in the last 30 days.").

## Evidence on Hand

- `assets/screenshot.png`: README screenshot of the main window.
- No testimonials, user counts, or press. Do not invent them.

## Product Principles

1. Pass or fail comes first. Status must be readable at a glance in every surface.
2. Native before novel. Mac conventions, controls, and keyboard shortcuts stay intact; personality goes into color, iconography, and small moments.
3. The output is the work. Logs stay legible, selectable, and searchable.
4. Quiet when healthy, clear when broken. A failure should stand out against a calm, sunny baseline.

## Accessibility & Inclusion

Status is never color-only: icons and text labels carry the state alongside color. Respect Reduce Motion and Increase Contrast.
