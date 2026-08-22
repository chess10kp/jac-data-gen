# Goal: build a large dataset of idiomatic Jac code

We produce a fine-tuning dataset of Jac functions by reusing the **MultiPL-T**
pipeline (Cassano et al. 2024, `./low_resource_paper.pdf`) and adapting it to
Jac's tooling. MultiPL-T generates *semi-synthetic, test-validated* training
data for low-resource languages by translating tested high-resource (Python)
functions and keeping only translations that pass compiled tests.

Our adaptation is **simpler than the paper's** because Jac ships a deterministic
Python→Jac transpiler (`jac tool py2jac`). We do not need MultiPL-E's
Python-assertion→target test *compiler* — the transpiler hands us a correct Jac
reference for free.

## Key insight: two separate concerns

- **Correctness** — guaranteed by `py2jac` (deterministic) for the transpile
  step, and re-verified by tests after the idiomize step.
- **Idiomaticity** — a separate, softer concern handled by an LLM agent, then
  *guarded* by tests. (The paper notes fine-tuning slightly hurts idiom but
  greatly helps correctness — §5.4.)

`py2jac` is deterministic, so the transpile hop needs no validation. The **only**
non-deterministic hop is the LLM idiomize step — that is where behavior can
silently change, and the only place a guard is required.

## Pipeline

```
tested Python function (+ high-coverage test cases)
  │   from nuprl/MultiPL-T (133,168 functions, already filtered & tested)
  ▼
py2jac  ──────────────► baseline Jac  (deterministic, correct by construction,
  │                                     non-idiomatic: `-> object`, `Any`, loops)
  ▼
LLM idiomize agent ───► idiomatic Jac (non-deterministic → NEEDS GUARD)
  │
  ▼
jac test  (compile the Python test cases as Jac assertions, run against idiomatic Jac)
  │
  ├─ pass ─► keep idiomatic Jac
  └─ fail ─► fall back to the baseline py2jac output (still valid, less idiomatic)
  │
  ▼
jac fmt + ROUGE-L dedup ─► final Jac fine-tuning dataset
```

## Why reuse nuprl/MultiPL-T instead of re-mining The Stack

The paper's expensive part (§4.1–4.2, ~10,000 A100-hours) is filtering 22M
Python functions down to **133,168** that have docstrings, type-check, and — most
importantly — have **generated test suites with ≥90% line coverage**. That output
is published (`https://huggingface.co/datasets/nuprl/MultiPL-T`). We start from
it and skip the mining entirely.

We must reuse the **test cases**, not just the functions — see the coverage
caveat below.

## Coverage is load-bearing (verified experimentally)

The idiomize guard is only as strong as the test inputs' coverage. In testing,
a subtly-wrong idiomatic rewrite (that dropped a "y counts only at the end"
special case) **passed a 4-case test suite** because no input exercised the
broken branch. It was only caught after adding an input that hit that branch.

This is exactly why the paper filters to ≥90% line coverage. If we reuse
MultiPL-T's functions with weak tests, poisoned idiomatic samples pass the guard
and enter the training set. **Preserve MultiPL-T's high-coverage test cases.**

## Jac toolchain (all in the `jac` binary, verified working)

| Purpose                         | Command                       |
| ------------------------------- | ----------------------------- |
| Python → Jac transpile          | `jac tool py2jac file.py`     |
| Jac → Python (reverse)          | `jac tool jac2py file.jac`    |
| Type-check                      | `jac check file.jac`          |
| Run test suite (pytest-backed)  | `jac test file.jac`           |
| Run a program                   | `jac run file.jac`            |
| Format (for dedup normalization)| `jac fmt file.jac`            |

Jac test-block syntax: `test "name" { assert expr; }` (name is a string literal).
Per-function run+test is ~0.13s.

## Open decisions / risks

1. **Idiomize agent scope** — let it be as aggressive as it wants; the diff-test
   guard decides what is kept. Do not gate aggressiveness on sample size:
   MultiPL-T functions are small and self-contained, so diff-testing is cheap
   across the board and a size threshold is just another parameter to get wrong.
2. **Test translation** — need to render MultiPL-T's Python test cases as Jac
   assertions. Since `py2jac` transpiles whole modules, transpiling the
   `assert f(x) == y` cases alongside the function may be the cheapest route
   (verify this works vs. hand-compiling assertions).
3. **Scale target** — "large" = up to 133,168 functions (the full MultiPL-T set),
   minus any that fail transpile/idiomize. Quantify a target.
4. **Idiomize model** — which LLM writes idiomatic Jac, and how do we give it
   enough Jac idiom to do better than py2jac's mechanical output?
