# AGENTS.md

## Code Moto

This repo is based on Code Moto. Code Moto is a basis/template repository that provides tools and patterns for downstream repositories. From a downstream repository, the basis repository is typically available at `../CodeMoto`. If the current repository is named `CodeMoto`, changes affect the Code Moto framework itself.

Repositories based on Code Moto may omit components or add their own. Backport broadly useful tools and changes to `CodeMoto` when practical.

The "Repo Specific" section blow contains rules specific to this repo only.

## Project Rules

1. Do not introduce bugs or regressions.
2. Before writing code, find analogous code in the repository and follow its established patterns.
3. Do not add comments to code. Preserve existing comments unless they are incorrect or obsolete.
4. Check code changes with `mise test`, which runs every test suite and type check. There is no lint task or linter config, so do not run linters such as RuboCop or ESLint.
5. Use root `mise` tasks instead of invoking underlying tools directly when an applicable task exists.
6. Give every task in the root `mise.toml` a `description` so `mise tasks` lists what it does.
7. Do not create a canvas or visualization unless the user specifically requests one.
8. Mr. Moto copies the main checkout's `.env.*` files into the card worktrees it opens, so do not copy them again. Copy `.env.development` and `.env.production` from the main checkout only into a worktree you open some other way, before running tests or mise tasks.
9. All code changes and other changes to tracked repository files need a PR, pushed with `mr push` and opened with `mr pr create`. Operations without tracked repository changes need no PR, empty commit, or branch. Never commit to or push `master`, and never make repository changes outside the PR flow.
10. Work from `origin/master`: start branches from it, and do not rely on local `master` being current.
11. If you spend significant time unnecessarily or the instructions misdirect you, and the issue could be backported to Code Moto (`CodeMoto` / MOTO), report it with enough detail for Mr. Moto to track the basis-repository follow-up. Keep app-specific issues separate.
12. On macOS, run root `mise` tasks from the worktree root in a non-login shell. For Codex `exec_command`, set `login: false` explicitly on each call that runs `mise`, including through wrappers. If Bundler reports system Ruby or a missing Bundler version, check tool resolution and retry the same root task this way before changing dependencies. Confirm the pinned tools with `mise which ruby` and `mise which bundle`; do not install gems into system Ruby, change lockfiles, or downgrade pinned versions to fix a shell-resolution failure. Agent shells on macOS run zsh, not bash: quote globs and URLs containing `?`, do not rely on unquoted variables splitting into words, remember that zsh arrays start at 1, and run bash scripts with `bash -c` or as a file with a bash shebang.
13. `AGENTS.md` is the only agent-instruction file. Do not add `.agents/`, `.claude/`, `.codex/`, or `CLAUDE.md`; put repeatable operations in `runbooks/`.

## Ruby

- Use `.blank?` and `.present?` for presence checks instead of `.empty?`, `.nil?`, or truthiness checks.
- Do not use `sleep`; use an event- or state-based approach instead.
- Add trailing commas to multiline argument lists and collections.

## TypeScript

- Treat nullable values as both `null` and `undefined`; use `nullish()` in Zod schemas and check for both states.
- Use `pnpm`, not `npm`.
- Use `mise tsc` to type-check.
- Prefer Lodash utilities over custom equivalents when Lodash is already available.
- Use shadcn/ui components.
- Use Tailwind CSS for styling.

## Testing

- Never run network requests, system commands, or application sleeps in tests. Stub those boundaries every time.
- Do not stub other units in a unit test. Only stub network requests, system commands, and sleeps so the real local collaborators and full local surface are exercised together.
- Every business-logic file must have one corresponding unit test file. Source and test files are 1:1.
- Test each business-logic unit thoroughly. Configuration, generated files, framework shells, and other files without business logic do not need tests.
- After every code change, run the whole suite with `mise test`.
- Do not write integration tests.

## Apple Workflow

- `mise test` runs the Apple app package tests in `apps/apple/Tests`, which compile the non-UI files listed in `Tests/Package.swift` into the `<Name>Core` target (`AppCore` in Code Moto), tested by `<Name>CoreTests` in Swift 5 language mode. Add new business-logic files to its `sources` and app-only files to its `exclude`.
- Use `mise simulate macos` to build and launch the Debug app and `mise xcode` to open the project macOS Debug builds use the configured bundle ID with a `.debug` suffix and a "Debug" display name so they run beside the installed app, and `mise simulate macos` quits only the Debug build it launched.
- Screen capture is not available to agents. To check UI, run the macOS Debug build and use `mise app:debug` with the `DebugHooks` commands, for example `mise app:debug "snap|/tmp/app.png"`, then read the PNG. `mise app:debug` waits for the app to finish each command and exits nonzero with the app's error when the command fails or the app is not running, so chain commands with `&&` and do not hide their output. Debug builds compile with `APP_DEV` and may write under `/tmp`. Commands do not activate the app or order windows front. Pass `DebugHooks.install` a closure to handle app-specific commands; throw `DebugHooks.Failure` from it to report an error. `DebugHooks` is macOS only; for iOS and tvOS simulators, use `xcrun simctl io booted screenshot /tmp/app.png`.

## Session instructions

Use `origin` as the sole workflow repository remote, preserving its hosting provider and actual default branch. A Code Moto basis remote named `codemoto` and an optional `deployment` remote may also be present. Do not add mirrors or alternate origin names. Fetch before updating default branches, use fast-forward-only pulls, and never force-push a default branch.

For card work, use Mr. Moto's `mr` CLI: run `mr card claim <CARD>` and follow its output, and see `mr --help` for the rest. This repository provides implementation instructions, checks, and operation tooling.

## File Structure

- `runbooks/` - Project operation instructions, such as deployment and publishing.
- `.env.default` - Template for the `.env.*` secret files.
- `.env.*` - Gitignored secrets, identifiers issued or rotated with them, and `RAILS_ENV`/`NODE_ENV`. Do not expose secret values. Mr. Moto generates them from 1Password with its `secrets` command; each item stores one concealed field per env key, labeled with the key name, and the file follows the `.env.default` layout with extra keys at the end.
- `apps/` - The Sundial macOS app and its tests.
- `assets/` - Shared images and media.
- `backend/` - Ruby on Rails API server.
- `config.json` - Non-secret configuration, including mobile app release (`apps`) and subdomain (`subdomains`) settings. Code reads it directly instead of `ENV`. Each subdomain entry has a required `source`: `website` (the Astro site on Cloudflare Workers), `frontend` (a React site in `frontend/subdomains/<name>` served from the droplet), or `backend` (Rails on the droplet). The default layout puts the website at the apex and `www`, the React app at `app`, and the Rails API at `api`. A config with only `website` entries needs no droplet. A `frontend` entry may list `backendPaths`, nginx location matches such as `"/.well-known/"` or `"~ ^/(mcp|oauth/)"` that its server proxies to Rails instead of serving the React app. Optional `redirectDomains` lists other domains that `mise deploy` 301-redirects to `domain` through Cloudflare, keeping the path and query; deploy replaces each redirect zone's Single Redirect rules. Deploy adds Fastmail MX, DKIM, and SPF records to `domain` and every redirect domain.
- `deploy/` - Backend and frontend deployment tooling.
- `docs/` - Project documentation in Markdown.
- `frontend/` - React frontend sites served from the droplet.
- `gems/` - Shared Ruby gems.
- `website/` - Astro marketing website, deployed to Cloudflare Workers by `mise deploy`.
- `manager/` - Project tooling for spawning new apps and Code Moto merges.
- `publish/` - Mobile app versioning, simulators, and App Store publishing. `mise keychain` restores the user keychain search list after a killed signing run and runs before `mise publish`; `mise keychain --repair` resets the login keychain, default keychain, and search list.
- `scripts/` - General-purpose scripts. `scripts/mise/` holds the scripts behind multi-line `mise.toml` tasks.
- `mise.toml` - Project tooling and task definitions.

## Runbooks

Read the relevant runbook when asked to perform an operation:

- [Deploy](runbooks/deploy.md) - Deploy `origin/master` to production and the website.
- [Publish](runbooks/publish.md) - Version and publish configured Apple apps.

Run `mise tasks` to discover available tasks and their descriptions, including development and production debugging tools.

## Repo Specific

### Deployment

This repository is deployed: `mise deploy` publishes only the Astro website in `website/` to Cloudflare Workers at `sundial.rsvp`, following the [deploy runbook](runbooks/deploy.md). `config.json` has only `website` subdomains, so there is no droplet; do not add `frontend` or `backend` subdomains, which would make `mise deploy` provision one on DigitalOcean.

### Sundial

Sundial is a native macOS app (macOS 27+) that schedules user shell commands with launchd and shows whether each run passed or failed. It is distributed as a signed and notarized repository release, not through the App Store, and through the `sundial` Homebrew cask in `grahamotte/homebrew-tap`, which `mise publish` updates from `apps.homebrew` in `config.json` after each release. It has a menu bar item listing recent runs, no Dock icon while that item is shown and the main window is closed, and no notifications.

### Apple App Architecture

- The app source is in `apps/apple/App`; the Xcode project is `apps/apple/App.xcodeproj` with the `Sundial` scheme.
- `SundialMain` is the entry point. `Sundial run <job-id>` runs one job headlessly through `JobRunner` and exits with the job's status; any other launch starts `SundialApp`.
- `JobStore` persists jobs to `~/Library/Application Support/Sundial/jobs.json`. `RunStore` writes one `<run-id>.json` record and `<run-id>.log` per run under `Runs/`, trims logs to 5 MB, and prunes runs older than 30 days.
- `LaunchAgentManager` owns `~/Library/LaunchAgents/com.grahamotte.sundial.job.<id>.plist` files. `sync` writes, bootstraps, boots out, and removes only labels with that prefix; it reloads a job only when its plist bytes change or it is not loaded. Rebooting out a running job stops that run, which then shows as interrupted.
- `Schedule` is the only source of schedule semantics: launchd `StartCalendarInterval` entries, next-run calculation, and summaries all derive from `calendarIntervals`. Keep schedules calendar-based so missed runs are coalesced after sleep; do not use `StartInterval`.
- `AppModel` is the single observable state for the UI and the only caller of the stores and `LaunchAgentManager`. `FileMonitor` reloads runs when the `Runs` directory changes and follows the log of a running run. `LogTextView` reads that log through `LogTail`, which returns only bytes added since the last read, and appends them to the text view at most ten times a second, so streaming output never re-reads or re-renders the whole log.
- `SundialApp` has two scenes: the main `Window` (`SundialApp.mainWindowID`) and a `.window`-style `MenuBarExtra` (`MenuBarView`) shown while the `showsMenuBarExtra` preference is on. `LSUIElement` keeps Sundial out of the Dock; `AppDelegate.applyActivationPolicy` makes it a regular Dock app while the menu bar item is off or the main window is open, because macOS shows an app's menu bar (About, Help, Window) only for regular apps. `ContentView` reports the main window opening and closing through `AppDelegate.setMainWindowOpen`. The app quits when its last window closes only while the menu bar item is off. `LoginItem` wraps `SMAppService.mainApp` for Open at login. Settings is not a separate window: `AppModel.isShowingSettings` (the button pinned to the bottom of the sidebar, ⌘) presents `SettingsView` as a sheet over the main window. The main window is always the same three-column split; do not swap split views by selection, because rebuilding the split rebuilds the window's toolbar and titlebar layout. The split view's restored sidebar width does not survive relaunch, so `SidebarWidthKeeper` stores the sidebar divider position in the `sidebarWidth` default and reapplies it at launch. The sidebar is always shown and has no toggle.
- Launch the app with `open` (or `mise simulate macos`) when checking UI. Running the executable directly does not present the main window.
- `SundialGlyph` draws the template menu bar glyph in code; there is no SF Symbol for a sundial. The app icon PNGs in `AppIcon.appiconset` show the same dial, gnomon, and shadow.
- The look is Solarized with a sun motif; `DESIGN.md` records it and `PRODUCT.md` holds product context for Impeccable design work. `Solar` defines the light, dark, and Increase Contrast colors, and `RunRecord.Status.tint` maps run states to them. `StatusIcon` draws states as weather (sun, storm cloud, cloud, turning sun, sunrise). `DayArc` owns the day-arc geometry and summary that `DayArcView` draws above the runs and in the menu bar.
- `AppModel.reveal(_:)` selects a run's job and the run itself; `ContentView` applies `revealedRunID` after the sidebar selection changes.
- The UI is a three-column `NavigationSplitView`: jobs in the sidebar, runs for the selection in the middle, and the selected run's output on the right. Keep it native, dependency-free, and pass/fail first.
- SwiftUI places a column's trailing toolbar items at the window's trailing edge, so only the sidebar uses the toolbar. `RunListView` removes the toolbar title and puts the title and subtitle in a `.navigation` toolbar item sized to the runs column's width minus the native Run Now and More items that follow it, so those controls stay right-aligned in that column. `RunDetailView` puts the run's status line in a `.navigation` toolbar item sized to the output column the same way. Views drawn under the toolbar band are hidden by it, so keep header content in toolbar items. The All / Failed filter is a segmented picker in the runs list above the day groups.
- `JobRunner` runs commands with non-login `/bin/zsh -c`. A login shell runs `/etc/zprofile`, whose `path_helper` drops the mise shims from `PATH` and breaks `mise` tasks.
- System boundaries are `CommandRunning` (launchctl) and `ProcessLaunching` (the job's shell); stub them in tests.

### Apple Workflow

- Debug builds compile with `SUNDIAL_DEV`, which stores data in `~/Library/Application Support/Sundial Dev` and labels launch agents `com.grahamotte.sundial.dev.job.<id>`, so development never touches the installed app's jobs.
- `mise test` runs the repository suite, including the `SundialCore` package tests in `apps/apple/Tests`, which compile the non-UI files listed in `Tests/Package.swift`. Add new business-logic files to its `sources` and app-only files to its `exclude`.
- Use `mise simulate macos` to build and launch the app and `mise xcode` to open the project.
- Use the [publish runbook](runbooks/publish.md) for versioning and the signed, notarized GitHub release workflow.
