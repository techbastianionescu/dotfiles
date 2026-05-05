---
name: doc
description: Document or audit the current project using a fixed three-file structure (README.md, docs/ARCHITECTURE.md, docs/DECISIONS.md). Invoked by the user typing /doc, optionally with a mode (init, update, audit, decision). Use to bootstrap docs, refresh stale docs, find drift between docs and code, or capture an architectural decision.
---

# /doc — project documentation skill

Produces or maintains documentation under a fixed three-file structure. Designed to prevent both under-documentation and over-documentation by giving every piece of information exactly one home.

## Invocation

The user types `/doc` followed by an optional mode:

| Command | Behavior |
| --- | --- |
| `/doc` | No mode. Prompt the user to pick: init / update / audit / decision. |
| `/doc init` | Bootstrap docs from current repo state. |
| `/doc update` | Diff repo vs. existing docs, propose targeted edits. |
| `/doc audit` | Report drift between docs and code. **Read-only.** |
| `/doc decision "<title>"` | Append a new entry to DECISIONS.md (interactive). |

If the user passes any other arg, ask once for clarification — do not guess.

## The three artifacts

Documentation lives in exactly these locations. Never create others without explicit user approval.

### 1. `README.md` — project root

Operator-facing. The "how do I run this" layer. Section order is fixed:

1. **One-line description** — what the project IS, in one sentence.
2. **Stack** — frameworks and key libraries with pinned versions (e.g., "Angular 13.3", not "Angular").
3. **Prerequisites** — required Node/Python/etc. versions, Docker, env vars, accounts.
4. **Quick start** — clone → install → run, in 3 commands max.
5. **Commands** — install / dev / build / test / lint / deploy. Only list commands that actually exist in `package.json` (or equivalent).
6. **Services & ports** — what runs where.
7. **Project structure** — top-level folders, 1 line each. No deeper than one level.
8. **Common tasks** — "how do I add a route", "how do I run a migration". Only tasks the user actually performs.
9. **Troubleshooting** — known gotchas only. No speculation.

**Hard cap: 150 lines.** If the README exceeds 150 lines, content must move to ARCHITECTURE.md or be cut. This cap is non-negotiable — it is the primary forcing function against bloat.

### 2. `docs/ARCHITECTURE.md` — system-level docs

Created **lazily**. Only generate this file when the project has at least one of:
- More than one deployable service or runtime
- Non-trivial layering (controllers / services / repositories, or equivalent)
- External integrations worth explaining (third-party APIs, queues, external DBs)

If none of these apply, omit the file entirely. Do not create empty scaffolding.

Sections:
- **Components** — what pieces exist and what each owns.
- **Data flow** — how a request travels through the system. One numbered flow or one diagram, not both.
- **External dependencies** — APIs, queues, databases, third-party services.
- **Conventions** — cross-cutting rules (error handling style, naming, layering).

### 3. `docs/DECISIONS.md` — append-only log

Architectural or tech-stack decisions. Each entry uses this exact template:

```markdown
## YYYY-MM-DD — Title

**Context:** what forced this decision
**Decision:** what we chose
**Alternatives considered:** what we rejected, and why
**Tradeoff:** what we gave up
```

Rules:
- **Append-only.** Never edit past entries except to fix typos.
- **Reversed decisions get a new entry** that links to the superseded one by `YYYY-MM-DD — Title`. Never delete the old entry.
- Newest entry at the bottom (chronological), so a reader scrolls top-down through history.

## Mode behavior

### `init`

1. **Check for existing docs first.** If `README.md`, `docs/ARCHITECTURE.md`, or `docs/DECISIONS.md` exist with non-trivial content, stop and ask:
   > "`<file>` already exists. Run `/doc update` to refresh it, `/doc audit` to check for drift, or confirm you want to overwrite."
   Do not overwrite without explicit confirmation.
2. Read the repo: `package.json` (or equivalent), framework signals, folder structure, lockfile for versions, compose/k8s files for services, existing `.env.example` for required vars.
3. **Decide scope:**
   - If the project shows architectural complexity (>1 service, layered code, external integrations), generate all applicable artifacts.
   - Otherwise, generate **README only**. Tell the user: "ARCHITECTURE and DECISIONS can be added later when there's content for them — run `/doc decision` when you make your first decision."
4. Fill each README section from observable repo state. Where information is not derivable from the repo (one-line description, troubleshooting gotchas, "common tasks"), insert `<!-- TODO: ... -->` placeholders. **Never invent.**
5. Show the proposed file(s) as a diff. Wait for confirmation before writing.

### `update`

1. Read existing docs.
2. Read current repo state (same signals as `init`).
3. Build a drift list:
   - Commands in README that no longer exist in `package.json`
   - Ports in README that don't match config
   - Stack versions that have bumped
   - New top-level folders not mentioned in "Project structure"
   - Services or files referenced in ARCHITECTURE that no longer exist
4. Propose **targeted edits**, not full rewrites. Show a diff per section that needs changing.
5. Wait for confirmation before writing.

### `audit`

**Read-only. This mode never writes to disk.**

Produce a punch list grouped by file:

```
README.md
  ❌ Broken: <specific contradiction with code>
  ⚠️ Stale: <doc area where the code has changed recently>
  ❓ Missing: <required section empty or marked TODO>

docs/ARCHITECTURE.md
  ...

docs/DECISIONS.md
  ...
```

End with a one-line summary: `Audit: <N broken>, <N stale>, <N missing>`.

If the user wants to act on the report, they invoke `/doc update` separately — audit and update are intentionally separate so reading the report is not coupled to writing changes.

### `decision "<title>"`

If no title was passed, ask for one first.

Then ask the four questions, **one at a time**, waiting for each answer:

1. **Context** — what forced this decision? (constraint, deadline, problem)
2. **Decision** — what did we choose?
3. **Alternatives** — what else did you consider, and why rejected?
4. **Tradeoff** — what are you giving up?

Format the answers using the template above with today's date in `YYYY-MM-DD` format. Append to `docs/DECISIONS.md`. If the file does not exist, create it with a one-line heading: `# Decisions` and append the entry below it.

Show the appended block back to the user. Done. Do not over-summarize.

## Discipline rules — apply in every mode

- **Never invent.** If the repo doesn't tell you something, ask the user or insert a `<!-- TODO -->`. Plausible-sounding fabrication is the worst failure mode of doc generation.
- **No filler sections.** "Introduction," "Overview," "Background" — cut them. Every section answers a question someone actually asks.
- **Never modify source files.** This skill does not generate inline comments, docstrings, or JSDoc. Code-level documentation is a coding-time discipline, not a doc-time one.
- **No speculative content.** No "Future work," "Roadmap," or "Possible extensions" sections.
- **Always show a diff before writing.** Modes `init` and `update` propose changes; the user confirms before any file is written.
- **Plain language.** "Runs on port 4200" beats "exposes a development server bound to TCP/4200."

## Conventions

- **Date format:** `YYYY-MM-DD`.
- **Code blocks:** language-tagged (` ```bash`, ` ```ts`, ` ```json`).
- **Links:** prefer relative paths inside the repo.
- **Headings:** sentence case ("Quick start"), not Title Case ("Quick Start").
- **Lists:** hyphens, not asterisks.

## What this skill does NOT do

- Does not write tests for documentation.
- Does not generate code comments or docstrings.
- Does not enforce documentation in CI (that's a separate concern).
- Does not document third-party libraries — only this project.
- Does not invent decisions the user hasn't actually made.
