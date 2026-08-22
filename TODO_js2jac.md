Yes—the model can add or migrate auth. The key is to avoid making the model an unrestricted second emitter.

## Recommended architecture

```text
Project source
  → deterministic js2jac baseline
  → capability/opportunity analysis
  → model supplies typed semantic decisions
  → deterministic recipe applier
  → project + behavioral validation
  → reviewed output and dataset record
```

This gives us both:

- an excellent, reproducible `js2jac`;
- model-assisted project migrations where local syntax is insufficient.

## Separate two auth operations

### 1. Migrate existing auth

The project already contains login, signup, token storage, or protected routes.

The analyzer extracts facts such as:

- source provider and imported symbol;
- endpoint paths;
- request and response shapes;
- token ownership and storage key;
- signup/session behavior;
- redirect behavior;
- protected route topology.

The model then selects a known adapter or abstains:

```json
{
  "opportunity_id": "auth-17",
  "selected_recipe": "auth.jac-protocol.login.v1",
  "answers": {
    "identity_kind": "username",
    "credential_kind": "password",
    "session_owner": "jac-runtime"
  },
  "confidence": 0.96,
  "abstain": false
}
```

A deterministic recipe renders the Jac:

```jac
import from "@jac/runtime" { jacLogin }

async def login(username: str, password: str) -> bool {
    return await jacLogin(username, password);
}
```

For signup, the recipe must encode the full sequence:

1. `await jacSignup(...)`
2. check `result["success"]`
3. `await jacLogin(...)`
4. only then call private endpoints or navigate

### 2. Add auth where none exists

This is not conversion. It is an explicit feature-generation track, for example:

```json
{
  "intent": "add-auth",
  "identity": "email",
  "flows": ["login", "signup", "logout"],
  "login_route": "/login",
  "post_login_route": "/dashboard",
  "protected_routes": ["/dashboard", "/settings"]
}
```

The model can derive parts of this from the project, but it must ask for missing product decisions. It must not silently decide which routes are private.

Call this track something like:

```text
semantic.auth-scaffold
```

Keep it separate from:

```text
semantic.auth-migration
```

## What the model should and should not produce

### Production-assisted mode

The model may produce:

- a selected recipe ID;
- structured semantic facts;
- field mappings;
- route classifications;
- assumptions and unresolved questions;
- `abstain`.

It should not directly produce:

- arbitrary Jac patches;
- arbitrary filesystem edits;
- `jac.toml` text;
- credentials;
- invented endpoints or data models.

The deterministic applier owns imports, calls, files, and config edits.

### Exploration/data mode

Allow the model to produce free-form candidate patches in a quarantined lane. These are useful for discovering new patterns, but they are not automatically production output or gold data.

The promotion loop is:

```text
model candidate
  → compile/check/browser tests
  → human review
  → accepted experimental record
  → repeated pattern becomes a deterministic recipe
  → regenerate canonical training examples
```

This gives the model room to innovate without weakening `js2jac`.

## Client-platform manifest

One adjustment to the earlier proposal: one source file is not enough for the complete registry.

Generate a combined client-platform manifest from:

- `client_runtime.jac` — `@jac/runtime` exports;
- `jac_builtins.pyi` — ambient Jac types such as `JsxElement`, `Callable`;
- `dom_types.pyi` — ambient browser/event types such as `MouseEvent`.

Example:

```json
{
  "jacSignup": {
    "availability": "runtime_import",
    "source": "@jac/runtime",
    "kind": "function",
    "async": true,
    "parameters": ["str | list", "str | dict", "dict | None"],
    "return": "dict"
  },
  "MouseEvent": {
    "availability": "ambient_type",
    "kind": "class"
  }
}
```

Signatures and async status can be generated. Semantic facts such as “signup does not establish a session” cannot be reliably inferred from declarations. Put those in a small reviewed metadata overlay and fail CI if it references a missing or changed symbol.

The converter then:

1. resolves imports by provenance;
2. removes invalid imports for ambient symbols;
3. redirects compatible symbols to `@jac/runtime`;
4. emits one deduplicated runtime import;
5. validates async and return handling.

## Deep semantic interface

I recommend only two public semantic entry points:

```text
plan_semantics(project, enabled_tracks) → SemanticPlan
apply_semantics(project, accepted_plan) → SemanticResult
```

Properties:

- planning never writes;
- apply never calls the model;
- every proposal is anchored to source hashes, node IDs, and spans;
- apply rechecks source/config/rule digests;
- only explicitly accepted proposal IDs are applied;
- changes go through existing staging, atomic write, and rollback logic.

Start with an offline `recipe-file` model adapter. This proves the complete plan/apply safety path before introducing a hosted model.

## Dataset design

Maintain physically separate datasets.

### A. Deterministic conversion

TS/TSX → converter-produced Jac:

- state, effects, refs;
- event handlers;
- props and JSX;
- routing imports;
- forms;
- runtime symbol management;
- known auth protocol shapes.

These records should be reproducible without a model.

### B. Native Jac platform tasks

Handwritten or documentation-derived Jac examples covering:

- every public `@jac/runtime` capability;
- login, signup, logout, session checks;
- signup-then-login;
- `AuthGuard`;
- manual and file routing;
- forms;
- client/server calls;
- graph-native applications.

This teaches capabilities that isolated TSX conversion cannot supply.

### C. Semantic project migrations

Complete source projects plus:

- deterministic baseline;
- opportunity inventory;
- model decision;
- accepted recipe;
- deterministic applied target;
- behavior evidence;
- review status.

Labels should distinguish:

```text
semantic-proposal
semantic-applied
semantic-model-synthesized
semantic-rejected
```

Do not count proposals as deterministic conversion positives.

## Promotion levels

| Tier | Requirements |
|---|---|
| Gold | Full project checks, client compile, required behavior tests, deterministic replay, lineage-safe split, independent review for model-assisted auth/routing |
| Silver | Static checks pass, but behavioral evidence or semantic review is incomplete |
| Rejected | Invalid proposal, abstention without a safe baseline, failed behavior, secret/license issue, or semantic mismatch |

For auth gold records, test at least:

- successful and failed login;
- signup followed by login;
- logout clears the session;
- protected-route redirect;
- reload/session restoration;
- unauthorized private call behavior;
- correct post-login navigation.

## Metrics

Use opportunity metrics rather than keyword counts:

```text
deterministically converted opportunities / eligible opportunities
model-accepted proposals / reviewed proposals
behavior-valid applications / applied proposals
```

Report by capability:

- `useState`: 7/7 converted;
- compatible router imports: 12/12 redirected;
- auth opportunities: 8 detected, 5 applicable, 4 behavior-valid;
- model abstention and false-opportunity rates;
- runtime exports with positive and negative fixtures.

Current Pilot A supports the need for this change:

- 100 records, but only 42 unique source hashes;
- 200 exact mappings;
- 166 guarded mappings;
- 6 interop mappings;
- 0 proposed mappings;
- no auth or routing tags.

Future splits must therefore operate on source/project/template lineage, not rows.

## Implementation order

### Phase 1 — Truth substrate

1. Preserve source node IDs, spans, guards, and mappings through reports.
2. Add complete project-level conversion reports.
3. Make dataset tooling call the public pipeline instead of invoking Bun bridges directly.
4. Add opportunity coverage metrics.
5. Generate the combined client-platform manifest.

### Phase 2 — Deterministic platform awareness

1. Add origin-aware symbol resolution.
2. Redirect compatible `react-router-dom` imports to `@jac/runtime`.
3. Remove ambient imports.
4. Add routing, event-type, form, and runtime-import fixtures.

### Phase 3 — Auth recipes without a model

1. Build auth/session/route fact extraction.
2. Define typed auth recipes.
3. Add the offline `recipe-file` adapter.
4. Implement model-free plan/apply replay.
5. Add compatible and incompatible auth fixtures and browser tests.

### Phase 4 — Model assistance

1. Add one structured-output model adapter.
2. Send only bounded opportunity evidence and candidate recipes.
3. Require explicit source-egress consent and secret scanning.
4. Permit `abstain`.
5. Apply saved decisions without another model call.

### Phase 5 — Capability pilots

Run:

1. 25 auth/routing projects with hand-authored decisions;
2. 100 projects with a model and full review;
3. 1,000 only after replay, security, behavior, and contamination gates pass.

Do not jump directly to a random Pilot B.

## Bottom line

Use the model for **semantic interpretation and explicit feature intent**, including auth. Use deterministic recipes for **trusted production changes**. Allow model-written patches only in an isolated exploration lane that feeds future recipe development.

The best immediate slice is:

> Complete provenance and reports → generate the platform manifest → add provenance-aware React Router rewriting → add auth opportunity fixtures.

That establishes the foundation for both a stronger converter and trustworthy model-assisted data.
