# pi-jac-ast-edit

AST-native search and editing tool for **Jac** (`.jac`) files in [pi](https://github.com/earendil-works/pi-coding-agent).
The Jac sibling of [`pi-ast-edit`](../pi-ast-edit) — but backed by **tree-sitter**
([tree-sitter-jac](../tree-sitter-jac)) instead of ts-morph.

## How it works

```
extensions/jac-ast-edit.ts   pi tool registration (`jac_ast_search`, `jac_ast_edit`), shell-search guard,
                             session snapshot recorder
python/jac_ast_edit.py       engine: symbol index, search, edits (locate → splice → re-parse → write),
                             and the model-facing result text
python/edit_view.py          changed-code view appended to edit results
python/jac_check.py          post-edit `jac check`, reporting only NEW errors
python/tree_sitter_jac/      local Python binding compiled from tree-sitter-jac's parser.c + scanner.c
deploy/                      pinned deploy profile: SYSTEM.md + jacpi.sh launcher
tests/                       pytest suite (engine, view, search, check, corpus sample, end-to-end pi)
```

- Locates symbols by `{target, name}` in the parse tree — no oldString, no
  whitespace/escape failures, no line-offset drift.
- Batches are **atomic**: ops apply in order, and the result is **re-parsed
  before writing**. If the new source would introduce syntax errors, the batch
  is rejected and nothing is written.
- Works on files with pre-existing parse errors as long as the target symbol
  itself parses.

## Setup

`pi install` clones the repo, and the extension looks for `.venv/bin/python`
inside its own package directory — so the one-time build happens in the
installed clone. The grammar C sources are vendored under `python/vendor/`,
so no sibling checkout of tree-sitter-jac is needed:

```bash
pi install git:github.com/chess10kp/pi-jac-ast-edit
cd ~/.pi/agent/git/github.com/chess10kp/pi-jac-ast-edit
python3 -m venv .venv
.venv/bin/pip install "tree-sitter>=0.25,<0.27" setuptools
.venv/bin/pip install -e ./python
```

For development, clone this repo anywhere, run the same three build lines
inside the clone, then `pi install /path/to/pi-jac-ast-edit`.


## Deploy profile (training and deployment)

`deploy/jacpi.sh` runs pi with a pinned prompt and tool set. SFT trajectories
are recorded with it, and the fine-tuned model is deployed with it, so both
see the same prompt, tool schemas and tool-result formats:

```bash
cd /path/to/project
~/repos/pi-jac-ast-edit/deploy/jacpi.sh --model zai/glm-5.3-flash            # interactive
~/repos/pi-jac-ast-edit/deploy/jacpi.sh --model zai/glm-5.3-flash -p "task"  # one shot
```

- System prompt: `deploy/SYSTEM.md` replaces pi's default prompt. pi appends
  only `Current working directory: <cwd>`.
- Tools: `read`, `bash`, `write`, `jac_ast_search`, `jac_ast_edit`. No `edit`,
  no MCP gateway.
- No skills, prompt templates, context files (AGENTS.md / CLAUDE.md),
  discovered extensions or project-local `.pi/` resources; `--offline`.
- Agent dir: `$JACPI_AGENT_DIR` (default `~/.pi/jacpi-deploy`). `auth.json`
  and `models.json` are linked from `~/.pi/agent` on first run. The launcher
  refuses to start if that dir holds `SYSTEM.md`, `APPEND_SYSTEM.md`,
  `mcp.json`, or `packages` in `settings.json`.
- Jac docs are not in the prompt. The prompt tells the model to run
  `jac guide` through bash when it needs it (an unclear `jac check` error, an
  unfamiliar construct), so teacher and student see the same context.

## Tool: `jac_ast_search`

Search without shell `grep`/`rg`/`find` (the extension blocks those in `bash`).

- `mode: "symbols"` (default) — Jac declarations whose name (or declaration
  line) contains `query`; `kind` filters (`archetype` = any archetype kind,
  `method` = ability, `property` = has); `exact` for exact names.
- `mode: "outline"` — every symbol in the files under `root`; set
  `root` to one `.jac` file for a per-file listing.
- `mode: "text"` — literal text inside `.jac` files, each hit as
  `path:line [kind Symbol] text` with the innermost enclosing symbol. Smart
  case: case-insensitive unless the query has a capital. `pathGlob` (e.g.
  `**/*.py`) searches other files.
- `mode: "files"` — `.jac` files with symbol counts.
- `limit` — default 100 (text: 50), max 500; a truncated listing says so.

The symbol index is cached across runs: the first search parses every `.jac`
file under the root and stores per-file symbol payloads keyed by
`mtime_ns` + `size` in `~/.cache/pi-jac-ast-edit/<root-hash>.json` (`$JAC_AST_EDIT_CACHE_DIR` overrides the directory); later
searches re-parse only new/changed files and prune deleted ones (written
atomically, and read failures are retried rather than cached). Set
`JAC_AST_EDIT_NO_CACHE=1` to bypass the cache.

## Tool: `jac_ast_edit`

`{path, operations: [{action, target?, name?, value?, valueEnd?, newCode?, index?}, ...]}`
— always a batch, applied in order, all or nothing. New files are created
with `write`.

| Action | Arguments |
|---|---|
| `set_body` | `newCode` = body statements, no braces |
| `add_statement` | `newCode` appended at the end of the body (after any `return`) |
| `replace_in_body` | `value` = unique anchor (+ optional `valueEnd`), `newCode` replaces the span |
| `replace` | `newCode` = the whole new symbol |
| `add_member` | `newCode` = field (`has x: int = 0;` or `x: int = 0`) or full method; `target` = archetype |
| `add_declaration` | `newCode` = full top-level declaration; `glob`/`type` go after the imports, the rest at the end |
| `rename`, `remove`, `set_initializer`, `set_type`, `set_return_type` | `value` = new name / expression / type |
| `add_parameter`, `remove_parameter`, `set_extends` | `value` = `x: int = 0` / param name / `Base, Mixin` |
| `add_import` | `value` = full import line; an `import from M { … }` merges into an existing one; idempotent |
| `remove_import`, `organize_imports` | `value` = module, `newCode` = one item to drop |

Targets: `obj`, `node`, `edge`, `walker`, `class`, `function` (module-level
def), `ability` (member def/can; `Card.label`), `impl` (`Animal.speak`),
`has`, `enum`, `member` (enum member), `glob`, `type`, `test`, `import`,
`code` (free `with entry` blocks).

Resolution rules:

- Each symbol is indexed once under its real kind.
- Archetype kinds are interchangeable as targets (`target: 'obj'` finds
  `walker X`), and `function`/`ability` match module defs, member abilities
  and `impl` blocks. If several symbols still match, body ops pick the one
  with a body (the `impl` over its bodyless declaration) and other ops pick
  the declaration; anything still ambiguous is rejected with an
  `ambiguous_symbol` error listing `index=N` per candidate.
- A miss reports where the name actually lives (`exists as: walker X (line 3)
  -> use target='walker'`) or a did-you-mean, plus at most 40 symbols.

Body contract: indentation of `newCode` is normalized (relative or absolute
style). Empty `{}` bodies work. `replace_in_body` works on function and
archetype bodies; anchors match exactly first, then whitespace-insensitively,
and must be unique. A miss shows the start of the body.

### Edit result

A successful batch returns one summary line, a view of the changed code, and
the new `jac check` errors:

```
add_statement ok (lines +1)
[f.jac:28-32 function add_two]
def add_two(x: int, y: int) -> int {
    z = x + y;
    return z;
    q: int = "s";
}
jac check: 1 new error (file has 2 total):
error[E1001] f.jac:31:5: Cannot assign Literal["s"] to int
      q: int = "s";
      ^^^^^^^^^^^^^
```

View (`python/edit_view.py`): each changed region is shown inside its
smallest enclosing symbol of the new file. A symbol of at most 30 lines is
shown whole. A longer one shows its first and last line plus each change with
3 lines of context, and skipped spans become
`… 42 unchanged lines (read f.jac:88-130) …`. The whole view is capped at 60
lines per batch, with a final marker naming the next ranges to read. No line
gutters, so shown code can be used as an anchor.

`jac check` (`python/jac_check.py`): `jac check --nowarn <file>` before and
after the write; only errors beyond the before-run's (code, message) counts
are shown, at most 5, at most 2000 characters, with the source line, caret
and `jac guide` hint. The pre-edit result is cached by path + content hash,
and each post-edit result becomes the baseline for the next edit, so only the
first edit of a file pays two checks. Environment:

| Variable | Default | |
|---|---|---|
| `JAC_AST_EDIT_CHECK` | `1` | `0` disables the check |
| `JAC_AST_EDIT_CHECK_TIMEOUT` | `30` | seconds per run |
| `JAC_AST_EDIT_CHECK_MAX` | `5` | errors shown |
| `JAC_AST_EDIT_JAC` | `jac` | executable |

Known grammar gaps (the re-parse gate rejects these — use supported forms):
bare `has x;` with neither type nor default, `impl ... for ...` root form
(write `impl Archetype.ability { }`), and `check` statements in test bodies
(use `assert`).

## Harvested from Empryo's ast_edit

Prompt suggestions and behaviors ported from Empryo's `ast-edit`
(`src/core/tools/ast-edit.ts` + its ts-morph backend):

- **Did-you-mean** fuzzy symbol suggestions (Damerau-Levenshtein, dot-prefix
  aware: `Card.labl` → `Did you mean: "Card.label"?`) alongside the
  available-symbols list on misses.
- **Idempotent `add_import`** — an identical import line is a no-op merge.
- **Output deltas** — `lines +N`, atomic op lists.
- **Action coverage where Jac allows it** — `set_type`, parameter ops,
  `set_extends`, import management, declaration creation. TS-only machinery
  (jsdoc, decorators, overloads, interfaces, exports, fix_missing_imports) has
  no Jac equivalent and is intentionally absent. The advertised surface was
  later reduced for small models (see `jac_ast_edit`); the engine still
  accepts the older action names (`add_method`, `add_property`,
  `add_function`, `add_enum`, `add_archetype`, `add_glob`, `add_type_alias`,
  `add_impl`, `add_test`, `add_named_import`, `insert_text`).

Not ported (Empryo-infra specific): undo stack, editor reload, memory hints,
clone hints, auto-format appends (run `jac format` instead), CAS
ts-morph-cache check (this engine re-reads per call; pi's mutation queue
serializes access).

## Trajectory recording

Before every agent turn the extension writes the exact system prompt and the
active tool schemas (name, description, JSON-schema parameters) into the pi
session JSONL as a custom entry, but only when they changed since the last
snapshot in that session:

```json
{"type":"custom","customType":"jac-harness-snapshot","data":{"hash":"…","systemPrompt":"…","tools":[{"name":"jac_ast_edit","description":"…","parameters":{…}}]}}
```

Custom entries are never sent to the LLM. Trajectory converters should take
the system prompt and tools from the latest snapshot before each response,
not from a stock pi prompt. Set `JAC_AST_EDIT_NO_SNAPSHOT=1` to disable.

## Tests

```bash
.venv/bin/pip install pytest pytest-xdist
.venv/bin/python -m pytest
```

`tests/test_corpus.py` edits a sample of real files from `$JAC_CORPUS_DIR`
(default `~/repos/jaseci/jac`, `$JAC_CORPUS_SAMPLE` files, default 60) and is
skipped without it. `tests/test_check.py` needs the `jac` CLI for its
integration cases, and `tests/test_e2e_pi.py` runs `deploy/jacpi.sh` against
a fake local model and needs `pi`; both skip when missing.

## Engine CLI (debugging)

```bash
echo '{"query":"Card","mode":"symbols"}' | .venv/bin/python python/jac_ast_edit.py search .
echo '{"mode":"text","query":"visit"}' | .venv/bin/python python/jac_ast_edit.py search .
echo '{"operations":[{"action":"add_member","target":"obj","name":"Card","newCode":"def f() -> int {\n    return 1;\n}"}]}' \
  | .venv/bin/python python/jac_ast_edit.py edit path/to/file.jac
```

## Known grammar gaps (upstream, not worked around here)

- `glob { ... }` block form does not parse (jsx_text fallback / ERROR).
- Named tests `test foo { ... }` leave the name as an ERROR node; the engine
  recovers the label heuristically but tests are best addressed by `index`.
