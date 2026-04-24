---
name: ck-check
description: Drift detector. Diff SPEC.md against code. Read-only, zero writes.
argument-hint: [§V | §I | §T | --all]
---

# ck-check

This is a generated Codex adapter wrapper.
Canonical upstream source: `commands/check.md` @ `028643f913996cfe1c59f261627d167d4ab5477f`.

Invocation translation:
- upstream `/ck:check` -> Codex `$ck-check`
- other upstream `/ck:*` references map to `$ck-*` in the same way
Pure diagnostic. Reports violations. Writes nothing. User decides remedy.

## LOAD

1. Read `SPEC.md`. If missing → "no spec, nothing to check." Stop.
2. Parse `$ARGUMENTS`:
   - `§V` → check invariants only (default)
   - `§I` → check interfaces
   - `§T` → audit task status vs code
   - `--all` → all three

## CHECK §V — invariants

For each V<n>:

1. Translate invariant into verifiable claim about code.
2. Grep / read relevant files.
3. Classify: **HOLD** / **VIOLATE** / **UNVERIFIABLE**.
4. Record address + file:line evidence.

## CHECK §I — interfaces

For each I item:

1. Locate implementation.
2. Classify:
   - **MATCH** — shape in code = shape in spec.
   - **DRIFT** — impl exists, shape differs.
   - **MISSING** — impl absent.
   - **EXTRA** — code exposes surface not in §I.

## CHECK §T — tasks

For each T<n>:

1. If `x`: verify claimed work present.
2. If `~`: note as in-progress.
3. If `.`: note as pending.
4. Flag `x` rows with no evidence as **STALE**.

## REPORT

Caveman. Grouped by severity.

```
## §V drift
V2 VIOLATE: auth/mw.go:47 uses `<` not `≤`. see §B.1.
V5 UNVERIFIABLE: no test covers ∀ req path.

## §I drift
I.api DRIFT: POST /x returns `{result}` not `{id}`. route.go:112.
I.cmd MISSING: `foo bar` absent from cli/*.go.

## §T drift
T3 STALE: status `x`, no middleware file exists.

## summary
2 violate. 1 missing. 1 stale. 1 unverifiable.
next: `$ck-spec bug:` or fix code at cited lines.
```

## REMEDY HINTS (not actions)

End report with one-line hint per class:
- VIOLATE / DRIFT → `$ck-spec bug: <V.n>` or fix code.
- MISSING → `$ck-build §T.n` if task exists; else `$ck-spec amend §T`.
- STALE → `$ck-spec amend §T` to uncheck.
- EXTRA → `$ck-spec amend §I` to document, or delete code.

Never invoke fixes. Report only.

## NON-GOALS

- Zero writes. No SPEC.md edits. No code edits.
- No sub-agents. Main thread reads.
- No scores, no grades. Binary per item: holds or drifts.
