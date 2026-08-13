# js2jac Converter Hardening Plan

**Date:** 2026-08-11
**Status:** Proposed — driven by real-world React yield measurement

## TL;DR

The dataset bottleneck is the **converter**, not sourcing. Measured real-world
yield is **2.1% (7 / 327 files)** across 9 real React/TS repos. Project-level
yield is **0 / 9** — every repo aborts on a fail-closed reject of a ubiquitous
modern-React idiom. The pilot's 100% pass rate is survivorship: the fixtures
were written to the converter's narrow envelope.

Sourcing is solved (`discover.py` + `harvest.py`, thousands of repos on tap).
Recipes / anchoring / manifest work is premature — it operates on converted
output, of which real repos currently produce ~zero.

**The shortest path from "2% of files" to "most of a real app" is burning down
the top-5 converter gaps below, plus one structural fix (fail-open per file).**

## Evidence

- 9 React repos, project-level conversion: **0 converted**.
- 40+ files, single-file mode: **0 converted**.
- Full tally: **327 files, 7 passed = 2.1%**.
- Failures are not random — they cluster into a small taxonomy, and the top 5
  buckets account for **245 / ~320 failures (77%)**.

Each failure is a fail-closed reject on line one of a normal modern-React file:
`'use client'`, async arrow components, barrel `index.ts`, default exports,
internal (non-exported) helpers.

## Structural fix (do this first)

### H0 — Fail-open per file, not fail-closed per project ✅ DONE

**Problem:** one unsupported file aborts the entire project. A single bad file
zeros a 70-file repo. This is independently a yield killer regardless of any
per-idiom fix.

**Fix:** degrade unsupported files to per-file *skips*; emit whatever converts.
Report skipped files with their error code rather than aborting.

**Why first:** unlocks partial project yield immediately and independently of
every other gap. Turns "0 of 70" into "however many files already pass."

**Implemented** (`jaclang/compiler/js2jac/`):
- New `--fail-open` CLI flag / `ProjectRequest.fail_open` (default `False`, so
  strict behavior and all existing tests are unchanged).
- Plan-stage file-scoped rejects (discover/graph: E7401/E7405/E7406/E7409) with a
  `path` degrade to `status=REJECT` + non-blocking instead of failing the plan.
  Project-wide diagnostics without a path (case collision, out-dir, symlink
  escape) stay blocking.
- Convert-stage per-file failures (bridge E7200/E7205, empty output, read errors)
  degrade to skips instead of setting the project failure flag.
- Files that transitively import a skipped local module are dropped too (via the
  dependency graph edges), emitting `E7407` — prevents writing a file with a
  dangling import to a skipped module (jac check only *warns* on those, so staged
  validation alone misses them).
- Iterative validate-and-prune: any emitted file that hard-fails the staged
  project check is dropped and the set re-validated until it's clean.
- Tests: `tests/compiler/js2jac/test_project_fail_open.jac` (3 passing);
  fixture `project_fixtures/fail_open/mixed`. Full project suite (50 tests) still
  green. Docs updated in `jaclang/cli/docs/reference/js2jac.md`.

## Converter gap backlog (ranked by real-world frequency)

| # | Failures | Gap | Fix character |
|---|---------|-----|---------------|
| 1 | 91 | `export const X = …` only accepts arrow / `forwardRef` / `memo` | broaden accepted initializers |
| 2 | 52 | local (non-exported) components / helpers rejected | support module-internal decls |
| 3 | 41 | `export default Foo` unsupported | the single most common React export idiom |
| 4 | 28 | top-level `ExpressionStatement` (`'use client'`, side effects) | strip / handle directives |
| 5 | 33 | barrel re-exports (`export *`, `export {x} from`) | split / resolve; every `index.ts` |
| 6 | 13 | async arrow components | desugar |
| 7 | 9 | helper needs return-type annotation | infer |
| 8 | 7 | hooks beyond the 5 supported (`useContext`/`useReducer`/custom) | extend hook table |
| — | ~15 | destructuring decls, TS modules, custom JSX tags, unsupported type refs | long tail |

Top 5 = 245 of ~320 failures (77%).

## Recommended sequence

1. **H0 — fail-open per file.** Structural; unlocks partial project yield now.
2. **#3 default exports** and **#1 broaden `export const` initializers.** Highest
   single-idiom frequency; together they cover the dominant export shapes.
3. **#2 internal decls** and **#4 directive handling.** Unblocks the files that
   have local helpers and the near-universal `'use client'` banner.
4. **#5 barrel re-exports.** Unblocks every `index.ts`; needed for whole-project
   coverage even though individual barrels carry little semantic content.
5. **#6–#8 + long tail.** Diminishing returns; schedule after re-measuring.

## Method / guardrails

- **Instrument first.** The taxonomy tally script (Python, iterates all harvested
  files, tallies error codes) is the yield meter. Re-run after each fix to watch
  the number climb — do not fix blind.
- **Attach failing fixtures.** Each gap should ship with the minimal real file
  that trips it, added to the fixture set so regressions are caught.
- **Re-measure real-world yield after every gap**, not synthetic pass rate.
  Synthetic 100% is meaningless here.
- Prefer **degrade-and-emit** over reject wherever a file is partially
  convertible.

## Explicitly out of scope for now

- More sourcing work (`discover.py` / `harvest.py` are done and proven).
- Recipes / anchoring / semantic manifest — these consume converted output that
  does not yet exist at volume. Revisit once real-world yield clears the top 5.
