# Global Rules

- Keep responses concise and scannable; prefer bullets over long paragraphs.
- Ask permission before writing or editing files unless explicitly told otherwise.
- Make the smallest, simplest change that solves the problem.
- Avoid large refactors unless the user explicitly requests them.

## Environment Snapshot

- This workspace is configured for read-first, tool-assisted analysis.
- Common tools include `read`, `grep`, `glob`, and `webfetch`.
- MCP integrations are available for:
  - `context7` (library/docs lookup)
  - `playwright` (browser automation)
  - `chrome-devtools` (page/debug inspection)
- Shell safety denies destructive patterns such as `sudo *`, `rm -rf`, and fork bombs.

## Task Management (Beads / bd)

- If Beads is available, use it for non-trivial multi-step tasks.
- `bd` commands are available to orchestrate task execution when needed.
- Keep exactly one task `in_progress` at a time and mark tasks complete immediately after finishing.
- Skip Beads for simple one-step requests.

## PHP Workflow

- For `.php` files, rely on the configured Devsense PHP language server context for diagnostics and symbols.
- Prefer LSP-informed changes over speculative edits.
- If PHP LSP context is missing or degraded, verify `DEVSENSE_PHP_LS_LICENSE` is set; config initialization depends on it.

## Plan Mode Rules

- When plan mode is active, avoid file/system mutations; treat the session as read-only for edits.
- Planning still allows inspection, analysis, bead management, and `bd` commands.
- Use read-only tools to gather context before transitioning back to build mode.
- In configured plan mode, mutating tools are explicitly disabled: `write`, `edit`, `patch`, `sed`, and `cat`.
- Plan-mode bash is effectively limited to an allowlist: `git status`, `git diff*`, `git log*`, `git show*`, `bd *`, `rg *`, `tree *`, `wc *`, `head *`, and `tail *`.
- `todowrite` is explicitly allowed in plan mode; use it to keep one active task when work is non-trivial.

## Tooling Reliability Notes

- Context7 MCP requires `CONTEXT7_KEY`; docs lookup failures are often env-related, not query-related.
- Dynamic context pruning is configured via `dcp.jsonc`; keep context lean during longer sessions.
- Plugins include Beads orchestration and PTY support, plus notifier/table-format helpers; prefer these capabilities over ad-hoc workarounds.

## Code Change Expectations

- Match existing project conventions before introducing new patterns.
- Prefer narrow diffs over sweeping rewrites.
- Add comments only when needed for non-obvious logic.
- Avoid defensive churn or stylistic noise unless there is clear value.

## Git Hygiene

- Never revert or discard unrelated user changes.
- Avoid destructive git operations unless explicitly asked.
- Only create commits when the user requests them.

## Local Commands / Skills

- `learn`: Record non-obvious, reusable discoveries in the nearest relevant `AGENTS.md`.
- `rmslop`: Remove low-signal AI-style artifacts and keep code idiomatic.

## What Good Output Looks Like

- Lead with the direct answer before diving into details.
- File/path references should be precise and minimal.
- Offer next steps only when they are logical and actionable.
