# Agent rules

Hard rules for agents in this repo:

- All work happens on a feature branch via [rift](https://github.com/anomalyco/rift), never committed directly to main/master.
- Default base is latest `main` (`origin/main` after fetch when available).
- Rift procedure: `rift init` if needed → `git fetch origin main` when remote exists → `rift create --name <slug>` → move agent root → `git checkout -B ship/<slug> origin/main` (or local `main` if origin has no commits yet) and reset hard to base tip.
- Parallel/disposable copies: `rift create` from the session rift; merge back; `rift remove` when done.
- No pushes or PRs unless the user explicitly asks.
- Never dismiss a security finding without surfacing it to the user.
- No secrets in commits, PR bodies, or reports.
