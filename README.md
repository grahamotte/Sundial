# Sundial

Sundial is a native macOS app for running your own commands on a schedule. Each job is a shell command, a working directory, and a schedule. Sundial installs one launchd agent per job, records every run's output and exit status, and keeps 30 days of history so you can see at a glance what passed and what failed.

Jobs run through launchd, so Sundial doesn't need to be open. If your Mac is asleep when a job is due, launchd runs it once when the Mac wakes.

Sundial is built on [Code Moto](https://github.com/grahamotte/CodeMoto), a shared foundation for a Rails API, a React website, native Apple apps, and project tooling. This repository keeps its own Git history and configuration, and merges improvements from Code Moto as the foundation evolves.

## How it works

- Jobs live in `~/Library/Application Support/Sundial/jobs.json`.
- Each enabled job gets `~/Library/LaunchAgents/com.grahamotte.sundial.job.<id>.plist`, which runs `Sundial.app/Contents/MacOS/Sundial run <id>` on a `StartCalendarInterval` schedule.
- The runner runs the command with `/bin/zsh -l -c`, with Homebrew, mise shims, and `~/.local/bin` on `PATH`, and writes combined stdout and stderr plus a run record to `~/Library/Application Support/Sundial/Runs`.
- A run passes when the command exits 0. Non-zero exits, signals, and runs whose runner died are failures.

## Contributing

Tools:

- `mise test` — run the complete app, web, deployment, and shared-gem test suite
- `mise simulate macos` — build and launch the macOS app
- `mise xcode` — open the Xcode project
- the [publish runbook](runbooks/publish.md) — version, test, sign, notarize, and publish to GitHub Releases

## Local development

Install mise and PostgreSQL, and have PostgreSQL running locally. Apple app development and tests also require macOS with Xcode.

1. Run `mise install` to install the tool versions pinned in `mise.toml`.
2. Create `.env.development` and `.env.production` from `.env.default` and fill in the required values. Projects registered in Mr. Moto with 1Password references can generate them by running Mr. Moto's `mr secrets` in the checkout instead.
3. Run `mise dependencies` to install project dependencies.
4. Run `mise db:migrate` to prepare the development database.
5. Run `mise start` to start the API, background jobs, and frontend sites. It prints the local URLs; the API runs at `http://localhost:3000`.

Non-secret project settings live in `config.json`, including the domain, GitHub repository, database name, subdomains, and app release details. Application credentials live in the gitignored `.env.*` files. Linear, GitHub/Forgejo PR operations, and macOS release uploads use Mr. Moto's central commands; repository-local tokens are not supported.

## Common commands

| Command | Purpose |
| --- | --- |
| `mise test` | Run all test suites, including frontend type checking |
| `mise tsc` | Type-check the frontend |
| `mise console` | Open the Rails development console |
| `mise simulate iphone` | Launch the iPhone app in a simulator |
| `mise xcode` | Open the Apple app project |
| `mise keychain` | Restore keychain settings left by an interrupted signing run; `--repair` resets the login keychain |

Deployment and publishing use the project-specific instructions in [runbooks](runbooks). Mr. Moto owns card tracking, enqueueing, the review workflow, and the Code Moto merge rollout.

## Starting another project

Run `mise spawn example.com` from this repository to create a sibling checkout with project configuration and generated environment files. Create its GitHub repository and review its configuration and credentials before using it. Repository registration and scheduling are handled separately by [Mr. Moto](https://github.com/grahamotte/MrMoto). Downstream projects use Mr. Moto's [merge runbook](https://github.com/grahamotte/MrMoto/blob/master/runbooks/merge.md) to bring in updates from Code Moto without replacing their history.

## Repository guide

| Directory | Contents |
| --- | --- |
| `backend/` | Rails API and background jobs |
| `frontend/` | React sites and shared frontend code |
| `apps/` | Native apps and screenshots |
| `gems/` | Shared Ruby libraries |
| `deploy/` | Infrastructure and deployment tooling |
| `publish/` | App versioning, simulation, and publishing |
| `manager/` | Project creation and Code Moto merges |
| `runbooks/` | Deployment and publishing instructions |
| `scripts/` | Scripts behind mise tasks |

See [Apple credentials](docs/apple-credentials.md) for publishing setup and [AGENTS.md](AGENTS.md) for contribution rules.
