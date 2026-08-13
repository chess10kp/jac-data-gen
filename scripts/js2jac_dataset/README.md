# js2jac dataset tooling

Deterministic pipeline for the **Pilot A** (100-component) corpus and future
50k dataset generation. Large artifacts stay in this data repo; the converter
lives in `jaseci/jac/jaclang/compiler/js2jac/`.

## Pilot A corpus

| Artifact | Location |
|---|---|
| Source files (100) | `jaseci/jac/tests/compiler/js2jac/pilot/pilot_*.tsx` |
| Generator | `scripts/js2jac_dataset/generate_pilot.py` |
| Validator | `scripts/js2jac_dataset/validate.py` |
| Manifest | `scripts/js2jac_dataset/pilot_manifest.json` |
| Record schema | `scripts/js2jac_dataset/schema.json` |
| Jac test | `jaseci/jac/tests/compiler/js2jac/test_pilot_corpus.jac` |

### Regenerate

```bash
python3 scripts/js2jac_dataset/generate_pilot.py
python3 scripts/js2jac_dataset/validate.py
```

`generate_pilot.py` is deterministic (`PILOT_SEED=20260810`). Re-running yields
byte-identical sources. `validate.py` runs parse → convert → `jac check` for
every record and updates the manifest with `jac_sha256` and conversion evidence.

### Families (100 total)

| Family | Count | Exercises |
|---|---:|---|
| basic_props | 8 | inline props, primitives |
| destructure | 8 | destructuring, external alias |
| jsx_attrs | 7 | static/dynamic attributes |
| jsx_conditionals | 7 | ternary, `&&`, `\|\|` |
| jsx_lists | 7 | `.map` comprehensions |
| hooks_state | 7 | `useState` |
| hooks_effect | 6 | `useEffect` deps |
| hooks_ref | 5 | `useRef` |
| helpers | 7 | local `def` / arrow helpers |
| control_flow | 7 | `if`, `for-of`, `while` |
| ts_types | 7 | unions, generics, interface |
| interop | 6 | `useMemo`, `useCallback`, npm |
| wrappers | 5 | `FC`, `memo`, `forwardRef` |
| native_idioms | 5 | V2.8 list/dict lowering |
| minimal_tsx | 5 | arrow-export JS-style patterns |
| ts_only | 3 | type-alias props |

### Known limitations (Pilot A)

- `.jsx` / `.js` without TypeScript annotations do not pass reviewed conversion
  (parser has no `typescript` plugin for those suffixes). Pilot uses `.tsx` with
  inline types instead.
- Patterns requiring `.length`, `.slice()`, or untyped props bags are excluded.

## Record schema

See `schema.json`. Each validated record includes content-addressed
`record_id` / `source_sha256` / `jac_sha256`, family, rule tags, and conversion
summary from the bridge.

## Next steps (per `JS2JAC_PLAN.md`)

- Pilot B: 1,000 examples with browser traces (V3 native idioms)
- Project mode: multi-file graph conversion
- `collect` / `dedup` / `split` modules for the 50k release funnel
