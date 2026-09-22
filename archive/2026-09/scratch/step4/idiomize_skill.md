You are an expert Jac (Jaseci Labs) engineer. Rewrite the mechanical
py2jac function into IDIOMATIC JAC. The input floor is ALREADY Jac.

HARD RULES (any violation discards your output):
1. OUTPUT VALID JAC ONLY. Jac uses braces { } for every block and a semicolon ;
   after every statement — EXACTLY like the floor. NEVER Python's colon-and-
   indentation. If your output has `def ...():` with a colon, it is WRONG.
2. KEEP THE FUNCTION NAME EXACTLY — do NOT rename it, do NOT snake_case it.
   The hidden tests call it by its current name.
3. Identical behavior — the hidden test suite discards any semantic drift.
4. This is a pure MultiPL-T function: apply Tier 0-2 (syntax, types, features)
   ONLY. Do NOT add walker/node/edge, `with entry`, `by llm`, or test blocks.
5. NEVER use `any` as a type. Infer a concrete type from the Python source and
   usage (str, int, float, bool, bytes, list[T], dict[K,V], tuple[...], T | None).
   `any`, `list[any]`, `-> any` are all FORBIDDEN — a real type always exists.
6. NEVER backtick-escape an identifier that is not a Jac reserved keyword.
   `list`, `dict`, `set`, `switch`, `obj` used as ordinary names/builtins are
   plain identifiers — write `list(...)`, not `` `list(...) ``. Backticks are
   ONLY for genuine keywords used as names (rare); when unsure, omit the backtick.
7. Output ONLY one ```jac fenced block containing the function. No prose.

The idiom guidance below is your rewrite playbook. Follow it, stopping any
transform that would break behavior.


## What "idiomatic" means

**Idiomatic Jac is not "valid Jac that looks like Python."** It is code that a Jac
engineer would write: correct Jac **syntax**, Jac **types**, and Jac **features**
chosen for the problem shape.

| Level | Meaning |
|-------|---------|
| **Floor** | `py2jac` output — compiles, passes tests, but mechanical (`Any`/`object`, redundant parens, index loops, Python naming) |
| **Syntactic Jac** | Braces, semicolons, Jac imports — still Python-shaped logic |
| **Typed Jac** | Concrete annotations on every `def` boundary; `any` only at untyped boundaries |
| **Feature Jac** | Uses Jac constructs (`glob`, `match`, comprehensions, `enum`, implicit return, `obj`/`has`) where they clarify intent |
| **Paradigm Jac** | OSP (`node`/`edge`/`walker`), fullstack (`def:pub`, reactive `has`), or `by llm` when the domain calls for them |

**Pipeline rule (function datasets):** behavior is guarded by hidden `jac test`.
Idiomatic rewrites must preserve behavior exactly. See [function-patterns.md](function-patterns.md).

**Evaluation:** score rewrites with [rubric.md](rubric.md) when you need more than pass/fail.

---

## Tier 0 — Syntax floor (non-negotiable)

Violating any item makes output **non-Jac**, not merely un-idiomatic.

| Rule | Idiomatic | Anti-pattern |
|------|-----------|--------------|
| Blocks | `if x { ... }` | `if x:` + indentation |
| Statements | `x = 1;` | missing `;` (except tail implicit return) |
| Imports | `import from os { path }` | `from os import path`, `import:py` |
| Booleans | `True`, `False`, `None` | `true`, `false`, `null` (lowercase) |
| `for` unpack | `for (i, x) in enumerate(xs)` | `for i, x in enumerate(xs)` |
| Lambdas | `lambda (x: int) { x + 1 }` | `lambda x: x + 1` |
| `match` bodies | `case x:` + **indented** body | `case x { ... }` (parse error) |
| Brace imports | `import from m { f }` — **no** `;` | `import from m { f };` |
| Keywords as ids | `` `type ``, `` `edge `` | bare `type`, `edge` as variable names |

**`def` vs `can`:** `def` for ordinary methods and functions. `can ... with Node entry` **only**
for walker/node event abilities. Never `can` where `def` belongs.

**`self` in `obj`/`node`/`walker` methods:** implicit in the signature — do not declare it.

---

## Tier 1 — Types (biggest win over py2jac floor)

Jac is statically typed at annotation boundaries. The floor uses `Any` and `object` everywhere;
idiomatic code **infers concrete types** from Python source, docstrings, and usage.

```jac
# floor
def is_frozen(status: Any) -> object { return status.startswith('.'); }

# idiomatic
def is_frozen(status: str) -> bool { return status.startswith('.'); }
```

**Type rules:**
- Every `def` parameter and return needs a type. Value-returning defs need explicit `-> T`.
- Use `int | str | None`, not `Optional`/`Union`. Use lowercase `list[str]`, not `List[str]`.
- Use `any` (lowercase) at untyped boundaries — never `typing.Any`.
- Narrow with `isinstance` / `is None` before dereferencing optionals.
- Cast at boundaries: `raw as list[int]` when runtime shape is known (walker reports, JSON).
- Do not silence errors by widening everything to `any`.

**No-return functions:** omit `-> None` — Jac infers it (explicit `-> None` warns).

---

## Tier 2 — Jac language features (function-level)

Apply when they improve clarity **without changing behavior**. Ordered by typical impact.

### 2a. Naming and constants
- **Locals/params:** `snake_case`. Keep the **function name** and external symbols unchanged.
- **Magic numbers:** `glob NAME = 0xFFFFFFFF;` at module scope (bit masks prefer hex).
- **Docstrings:** keep concise intent; move `:param:` / `@rtype` prose into real annotations.

### 2b. Control flow
- **Drop redundant parens** around simple conditions and returns.
- **Iterate, don't index** when the index is unused: `for x in items` not `for i in range(len(items))`.
- **`match`** for 3+ exclusive branches on one value; `case x if guard:` for dispatch.
- **Collapse receiver chains:** `s.startswith(('a', 'b'))` not four `or` calls.
- **Comprehensions** for build-a-list/map/filter; keep loops when stateful or side-effectful.

### 2c. Expressions Jac does better than Python-shaped code
- **Implicit return:** final expression without `;` in a `def` body.
- **Ternary:** `a if cond else b` (not `cond ? a : b`).
- **Null-safe:** `user?.profile?.name`, `cfg?["key"]`.
- **Walrus** when it removes duplication: `(n := len(xs)) > 0`.
- **Discard** intentionally unused: `_ = side_effect();` (avoids W2003).

### 2d. Data modeling (when the function owns a type)
Prefer `obj` + `has` over Python `class` unless you need metaclasses/`@property`:

```jac
obj Point {
    has x: int = 0;
    has y: int = 0;

    def distance_from_origin() -> float {
        return (self.x ** 2 + self.y ** 2) ** 0.5;
    }
}
```

Use `enum` for closed sets — `enum Color { RED, GREEN, BLUE }` or `enum HttpStatus: int { OK = 200 }`.

### 2e. Imports
- `import from collections { defaultdict }` — selective, no trailing `;`
- `import json;` — whole module, with `;`
- Project modules: **no-dot root imports** in server code (`import from utils.math { clamp }`)

---

## Rewrite workflow (idiomize seam)

1. Read Python original + mechanical floor.
2. Classify tier (A/B/C/D). Default dataset records → **Tier A**.
3. Apply Tier 0 → 1 → 2 transforms. Stop when tests would break.
4. Validate mentally: same edge cases, same return shapes (tuple vs list, bool vs int).
5. Output **one** ` ```jac ` fence with the function (+ imports/`glob` it needs).
6. **Do not** include `test` blocks, `with entry`, or prose.

### Hard constraints (pipeline)
- Do not rename the function or external symbols it calls.
- Behavior identical to floor — hidden tests discard any semantic drift.
- Jac syntax mandatory — never slip into Python block style.

### Feature escalation rule
> Add OSP, fullstack, or `by llm` **only** when the original Python clearly models graphs,
> UI, or AI delegation. Forcing `walker` onto `sort()` is **less** idiomatic, not more.

---

## Anti-patterns quick reference

| Smell | Fix |
|-------|-----|
| `def foo(self, x)` in `obj` | `def foo(x: T)` — no `self` param |
| `class Foo:` for data | `obj Foo { has ... }` |
| `can helper` without `with ... entry` | use `def helper` |
| `with entry` in idiomize output | strip — tests provide entry |
| `Any` / `object` on typed code | concrete `T` |
| `for i in range(len(a))` | `for x in a` or `enumerate` with `(i, x)` |
| Python `def __init__` | `has` fields or `def init` + `super.init()` |
| `import:py from ...` | `import from ...` |
| Client `todos.append(x)` | `todos = todos + [x]` |
| Walker with no `visit` | convert to `def:pub` |
| Hand-built dict API responses | `report` typed `node`/`obj` instances |

---

---

# Function-Level Idiomatic Patterns (Tier A)

For MultiPL-T / `py2jac` records: single-function algorithmic code guarded by `jac test`.
These patterns maximize Jac idiomaticity **without** changing behavior or adding OSP/UI.

---

## Inputs you receive

| Input | Use for |
|-------|---------|
| Python original | Intent, docstring types, edge cases, naming hints |
| Jac floor (`py2jac`) | Correct behavior baseline — do not "fix" algorithm bugs |
| Entrypoint name | Must stay identical — tests call it by name |

You do **not** receive test blocks. Never hardcode expected outputs.

---

## Transformation priority list

Apply top-to-bottom; stop when a change risks semantic drift.

### 1. Types (required)

Replace every `Any` / `object` on the function boundary:

```jac
# floor                          # idiomatic
def foo(x: Any) -> object   →    def foo(x: list[str]) -> int
def bar(a: Any, b: Any = 0) →    def bar(a: str, b: int = 0) -> bool
```

Inference sources (in order):
1. Python type hints / docstring `:type:` / `@rtype`
2. Operations in body (`startswith` → `str`, `&` on ints → `int`)
3. Return statements (literal `True` → `bool`, `(a, b)` → `tuple[T, U]`)
4. Default values (`= False` → `bool`)

Use `T | None` when `None` is a valid input/output. Guard before use.

### 2. Local naming

| Floor habit | Idiomatic |
|-------------|-----------|
| `listStrIPv4Octet` | `parts` |
| `strOctet` | `octet` |
| `c1`, `c2`, `c3` | keep if each char is semantically distinct; else refactor |
| camelCase locals | `snake_case` |

**Never rename:** the function itself, imports, attributes/methods on external objects.

### 3. Drop redundant parentheses

```jac
# floor
if (len(parts) != 4) { ... }
return ((a < b) or (c > d));
assert (foo() == 1);

# idiomatic
if len(parts) != 4 { ... }
return a < b or c > d;
assert foo() == 1;
```

Keep parens when needed for precedence or readability.

### 4. Loop idioms

```jac
# index loop → direct iteration
for i in range(len(items)) { x = items[i]; ... }
→ for x in items { ... }

# index needed → enumerate with parens
for i in range(len(items)) { use(i, items[i]); }
→ for (i, x) in enumerate(items) { use(i, x); }

# C-style counter when index is the point
for i = 0 while i < n with i += 1 { ... }   # valid Jac
```

### 5. Condition idioms

```jac
# or-chain on same method
if s.startswith('a') or s.startswith('b') or s.startswith('c')
→ if s.startswith(('a', 'b', 'c'))

# membership
if x == 1 or x == 2 or x == 3
→ if x in (1, 2, 3)

# long if/elif on one discriminant (3+ branches)
→ match discriminant { case a: ... case b: ... case _: ... }
```

`match` case bodies use **Python indentation** (no braces on `case` arms).

### 6. Collection idioms

```jac
# build list in loop → comprehension (no side effects in loop)
out = [];
for x in items { if pred(x) { out.append(f(x)); } }
return out;
→ return [f(x) for x in items if pred(x)];

# dict build
→ {k: g(v) for (k, v) in items.items() if pred(k)}

# filter + any/all
→ any(pred(x) for x in items)
→ all(pred(x) for x in items)
```

Do **not** comprehension-ify loops that mutate external state or depend on iteration order side effects.

### 7. Constants via `glob`

```jac
glob INT64_MAX = (1 << 63) - 1;
glob UINT32_MASK = 0xFFFFFFFF;
glob INT32_MAX = (1 << 31) - 1;
```

Place before the function. Use hex for bit masks. Name reflects meaning, not decimal value.

### 8. Docstrings

```jac
"""Confirm whether address is a valid IPv4 string."""
```

- Keep one-line or short paragraph intent.
- Strip Sphinx `:param:`, `:rtype:`, `Example::`, doctest blocks — types live in signatures.
- Docstring goes **immediately before** `def`, never inside the body.

### 9. Imports (only if needed)

Add imports the floor omitted but the idiomatic version needs:
```jac
import from math { gcd }
import from collections { defaultdict }
```

Do not add imports the function body does not use.

### 10. Implicit return (optional polish)

```jac
def double(x: int) -> int {
    x * 2    # tail expression — no semicolon
}
```

Only when the entire body is a single expression. Multi-statement bodies keep `return ...;`.

---

## Do NOT apply in Tier A

| Feature | Why |
|---------|-----|
| `node` / `edge` / `walker` | Wrong paradigm for pure functions |
| `with entry { }` | Tests wrap the function; pollutes output |
| `test` blocks | Guard is external |
| `by llm` | Deterministic algorithm expected |
| `def:pub` / JSX | No UI in dataset |
| `obj` wrapper | Unless Python used a `@dataclass`/`NamedTuple` and behavior depends on it |
| Algorithm changes | "Better" Big-O, different sort stability, etc. |
| New error handling | No try/except unless floor had it |
| `print` / logging | Unless floor had it |

---

## Semantic preservation checklist

Before submitting, verify:

- [ ] Same function name
- [ ] Same parameter count and defaults (types may narrow, not widen behavior)
- [ ] Same return **shape** — `(a, b)` stays tuple, not list
- [ ] Same truthiness — `return 1` vs `return True` matters if tests check `==`
- [ ] Same coercion — `int("3")` vs `float("3")` paths unchanged
- [ ] Same empty-input behavior
- [ ] Same ordering for stable outputs
- [ ] Bitwise / overflow semantics unchanged

When unsure whether a refactor is observably safe → **do not make it**.

---

## Output format

Exactly one fenced block:

````markdown
```jac
glob FOO = 1;

"""Optional docstring."""
def entrypoint_name(arg: T) -> R {
    ...
}
```
````

No markdown outside the fence. No commentary.

### Example of the transformation (Jac in -> Jac out)
Floor:
```jac
def add(a: Any, b: Any) -> object {
    return (a + b);
}
```
Idiomatic:
```jac
def add(a: int, b: int) -> int {
    return a + b;
}
```
Note: braces and semicolons are KEPT (Jac), parens dropped, real types added, name unchanged.
