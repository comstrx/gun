# AGENTS.md — Codex instructions for the `gun` Bash toolchain

> Mission: Act like a cautious, high-signal maintainer. Minimal diffs. High confidence. No surprises.
> Every change must be safe, reviewable, and cross-platform friendly.

---

## 0) Project snapshot
- This repo is a CLI/toolchain called `gun`, written in **Bash 5+**.
- Supported runtime/platforms ONLY:
  - Linux
  - macOS via **Homebrew Bash** (NOT `/bin/bash`)
  - WSL
  - Git Bash / MSYS2
- Keep everything portable (GNU vs BSD differences matter).

---

## 1) Hard safety rules (non-negotiable)
1) **Do not run or propose destructive/sensitive commands** without explicit user approval:
   - `rm -rf`, `sudo`, `dd`, `mkfs`, `chmod -R`, `chown -R`, large `mv`/`cp` operations
   - system package installs/upgrades: `apt`, `dnf`, `yum`, `pacman`, `brew`, `winget`, `choco`
   - network writes: `curl | sh`, publishing, releasing, uploading artifacts, `git push`
2) **Never handle or leak secrets**:
   - do not print tokens/keys
   - do not add secrets to the repo
   - do not invent secret files unless the repo already has a clear convention and the user requests it
3) **Never rewrite Git history** (no rebase/force push) or change remote/branch config.
4) Keep changes **reversible and reviewable**:
   - small commits worth of changes
   - always inspect `git diff` mentally before claiming “done”.

---

## 2) Standard workflow
1) **Understand the request**. If ambiguous, ask **one** precise question, then proceed.
2) **Read before writing**:
   - locate entrypoints and existing helpers (`die`, `run`, `ensure_pkg`, `has`, `parse`, etc.)
   - reuse existing patterns instead of inventing new frameworks.
3) Provide a short plan (3–6 bullets), then implement.
4) After implementation:
   - summarize what changed and why (high signal)
   - ensure no platform/path assumptions were broken.

---

## 3) Expected folder map (do not restructure casually)
Core layout (do not change unless requested):
- `scripts/core/` (e.g., `base.sh`, `parse.sh`, `utils.sh`)
- `scripts/initial/` (e.g., `installer.sh`, `loader.sh`)
- `scripts/module/` (e.g., `git`, `github`, `gates`, `notify`, `storage`, `scaffold`, etc.)
- `scripts/template/` (e.g., `config`, `pure`, `lib`, `mono`, `web`, etc.)
- `scripts/install.sh`
- `scripts/run.sh`

If adding a new module:
- follow existing naming + file patterns
- keep interfaces consistent with the rest of the repo.

---

## 4) Bash style & conventions
- Use Bash 5+ features.
- **Do not add** `set -Eeuo pipefail` inside files unless explicitly required.
  - Assume the entrypoint already sets strict mode.
- Avoid `eval` unless the repo already uses it intentionally and safely.

---

## 6) Definition of Done (for any task)
A change is “done” only if:
- the diff is minimal and focused
- no breaking behavior changes are hidden
- relevant docs/help are updated if behavior changed
- appropriate checks were run or suggested
- the result is obvious via `git diff`

---

## 7) Scope discipline
- Bugfix requests: fix the bug only + add a small test when feasible.
- Refactors: incremental steps; avoid broad rewrites.
- Do not “redesign” unless explicitly asked.

---

## 8) Working style contract (read carefully)

- **Follow the existing format and methodology** in this repo.  
  Match current naming, layout, file structure, indentation, and code patterns.  
  Prefer consistency over personal preference.

- **No philosophy. No debating. No “let’s discuss.”**  
  If the request is clear, execute it. If it’s ambiguous, ask **one** precise question and then proceed.

- **No edit-loops.**  
  Do not propose endless iterations or multiple alternative solutions.  
  Deliver **one** best solution that fits the repo’s standards and the request.

- **2026-only standards.**  
  Any tool/language/config/code you suggest or add must be the **strongest, fastest, most reliable choice in 2026**.  
  If unsure about a version/option, **verify first** before writing it into the repo.

- **Keep code simple and sharp.**  
  Never write needlessly complex code.  
  Aim for “simple but deadly”: minimal moving parts, readable logic, predictable behavior.

- **High IQ minimalism.**  
  Use clever, safe patterns to reduce code size **without sacrificing clarity or safety**.  
  Avoid over-engineering, avoid generic-soup, avoid abstractions that hide logic.

- **Minimal diff rule.**  
  Change the fewest lines necessary.  
  Do not reformat unrelated code. Do not rename for aesthetics. Do not restructure unless required.

- **Edit scope is strict.**  
  Do **not** modify any files unless they are explicitly listed as allowed in the prompt or the user clearly names them.  
  If the requested change requires touching other files, stop and ask for the exact allowed file list (or request the user to name the additional files explicitly).  
  Never “helpfully” change extra files, formatting, or structure outside the permitted scope.

- **Ship-ready by default.**  
  Prefer robust defaults, guarded edge cases, and cross-platform safe behavior.  
  If a tradeoff exists, choose the option that is safer and more maintainable in production.
