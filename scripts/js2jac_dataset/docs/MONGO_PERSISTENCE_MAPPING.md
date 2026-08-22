# FARM persistence mapping (FastAPI + Beanie/Motor + MongoDB → Jac graph)

Status: design sketch, **Jac verified**. Companion to `PERSISTENCE_MAPPING.md`
(Prisma). Every Jac snippet below type-checks (`jac check` green) and follows the
idiom of `jac/examples/todo_app/main.jac` — the shipped full-stack Jac todo app.

Motivation: FARM is the best translation target for teaching idiomatic Jac because
(a) the backend is Python, so schema-lift and code-rewrite are structural, not
cross-language; and (b) Mongo's data *intent* (documents reachable per-user, joined
by references) is exactly Jac's graph idiom — so a faithful translation **is**
idiomatic, unlike JSX transliteration. Scope here: the typed-ODM core
(Beanie/ODMantic/mongoengine, ~7.4k FARM files). Raw Motor/PyMongo (~29k, no
declared schema) is a separate LLM/heuristic doc.

## 0. The one idea

**A Mongo app models data as collections of documents joined by `ObjectId`
references and scoped by `where user_id == me`. Jac models the same data as a graph:
`node`s reachable from each user's `root`, joined by typed `edge`s.** The mapping is
a *schema lift* (done, deterministic) plus a *call rewrite* (the table in §2):

| Mongo / Beanie world | Jac world |
|---|---|
| `class Todo(Document)` (a collection) | `node Todo { has ...; }` |
| scalar field | `has field: type;` |
| `Link[User]` / `Reference()` | **typed edge** `edge Owns: User --> Todo` |
| `BackLink[Todo]` (inverse) | a traversal `[user -->[?:Todo]]` — not stored |
| `PydanticObjectId` / `_id` | `jid(n)` / `n._jac_id` — the node's opaque id |
| `find(Todo.user_id == me)` (tenancy) | **structural**: the todo hangs off *that user's* `root` |
| `$lookup` / manual ref join | an edge traversal `[u -->[?:Todo]]` |

The last two rows are the payoff: per-user scoping and ref-joins that Beanie does
with runtime filters, Jac does *structurally* — so a whole class of `user_id` filter
code disappears instead of being translated.

## 1. Schema lift — DONE, deterministic

`mongo_odm_to_jac.py` (stdlib `ast`, zero LLM, zero per-record tokens) lifts
Beanie/ODMantic/mongoengine `Document`/`Model` classes → `node`/`edge` archetypes:

- `Document` class → `node`; scalar field → `has f: <jac type> [= default]`
- `Link[Y]` / `list[Link[Y]]` / `Reference()` → typed `edge X --> Y` (endpoint-typed
  so traversals infer node types — avoids the W1051/E1053 latent-type trap)
- `BackLink[Y]` dropped (→ inverse traversal); `id`/`_id`/`PydanticObjectId` dropped
  (jid is identity; `--keep-external-id` keeps it as `has ext_id: str`)
- forward-ref string literals (`Link["Task"]`) resolved; edge/node **name collisions**
  disambiguated to `Parent+Field` (e.g. `TaskProject`); E2004 field ordering enforced
  (non-default fields precede default-bearing ones)

Output type-checks green (validated on a 4-model Beanie schema → 4 nodes + 3 edges).

## 2. Call-site rewrite table — the crux

**Key fact (from `todo_app/main.jac`): idiomatic CRUD-over-graph is WALKER-based, not
function-based.** A Beanie query method maps to a **walker ability**, and the client
invokes it with `root spawn W()` (collection-level) or `<id> spawn W()` (document-level).
This is the single most important shape difference from a naive FastAPI→function port.

Let `Todo` be a node, owned by `User` via `edge Owns: User --> Todo`. All Jac below
is verified green.

| Beanie / Motor (inside a FastAPI handler) | Jac (walker ability) |
|---|---|
| `await Todo(**data).insert()` | `here ++> Todo(...)` in `can ... with Root entry` |
| `await user_todos.append(t)` (owned create) | `here +>:Owns:+> Todo(...)` (typed-edge connect) |
| `await Todo.find_all().to_list()` | `report [-->[?:Todo]];` |
| `await Todo.find(Todo.done == False).to_list()` | `report [t for t in [-->[?:Todo]] if not t.done];` |
| `await Todo.get(id)` | spawn on the node: `<id> spawn W()` + `can ... with Todo entry` |
| `t.done = True; await t.save()` | `here.done = True;` (auto-persists — no save call) |
| `await Todo.find(...).update({"$set": {...}})` | walk matches in `can ... with Root entry`, assign each `n.f = v` |
| `await t.delete()` | `del here;` (cascades its edges) in `can ... with Todo entry` |
| `len(await Todo.find(...).to_list())` | `report len([-->[?:Todo]]);` |
| `user.todos` (Link back-populate) | `[here -->[?:Todo]]` (or typed: `[here ->:Owns:->]`) |
| ref-join / `$lookup` | traverse the edge inverse: `[todo <-:Owns:<-]` |
| `where user_id == current_user` (tenancy) | *nothing* — walker runs on the caller's own `root` |

**Handler shell:**

| FastAPI | Jac |
|---|---|
| `@app.post("/todos")` + `async def create(body)` | `walker:pub create_todo { has title: str; can go with Root entry {...} }` |
| `@app.get("/todos")` | `walker:pub list_todos { can go with Root entry { report [-->[?:Todo]]; } }` |
| `@app.patch("/todos/{id}")` | `walker:pub complete_todo { can go with Todo entry {...} }` → client: `id spawn complete_todo()` |
| `Depends(get_current_user)` auth | *structural* — `walker:pub` runs on the caller's `root`; no manual `user_id` guard |
| `raise HTTPException(404)` | `report {"error": "not found"};` or `disengage;` |
| `response_model=TodoOut` | walker `report`s the node; a `to_view()` `obj` projects fields if needed |

## 3. Worked example — a FARM todo endpoint set

Beanie source (abbreviated):

```python
class Todo(Document):
    title: str
    done: bool = False

@app.post("/todos")
async def create(body: TodoIn):
    return await Todo(title=body.title).insert()

@app.get("/todos")
async def list_todos():
    return await Todo.find_all().to_list()

@app.patch("/todos/{id}")
async def complete(id: str):
    t = await Todo.get(id); t.done = True; await t.save(); return t
```

Faithful Jac (what the pipeline should emit — verified green):

```jac
node Todo { has title: str; has done: bool = False; }

walker:pub create_todo {
    has title: str;
    can go with Root entry { report here ++> Todo(title=self.title); }
}
walker:pub list_todos {
    can go with Root entry { report [-->[?:Todo]]; }
}
walker:pub complete_todo {            # client: <id> spawn complete_todo()
    can go with Todo entry { here.done = True; report here; }
}
```

What vanished vs. the source: the `await`s, the `.insert()/.save()` plumbing, the
`Todo.get(id)` lookup (the client spawns the walker *on* the node id), and — in an
authed app — every `user_id` filter (the walker already runs on the caller's `root`).

## 4. The client seam (the R → the boundary)

React `fetch('/api/todos')` → the Jac client calls the walker directly:
`result = root spawn list_todos(); todos = result.reports;` (see `todo_app` client,
lines 47–48). Node identity crosses the wire as `todo._jac_id`; a document-scoped
call is `todo._jac_id spawn complete_todo()`. Matching each `fetch(path)` to its
walker is the one inference-heavy step (LLM budget goes here); FARM path↔route
conventions make it tractable.

## 5. What does NOT map (→ LLM / reject bucket)

Small and identifiable:
1. **Aggregation pipelines** (`$group`, `$facet`, `$bucket`) — no graph idiom; become
   plain comprehensions/loops over traversed nodes (works, not idiomatic).
2. **Multi-document transactions with cross-invariants** — Jac request bodies are
   atomic per spawn, but explicit `with await session.start_transaction()` spanning
   collections needs manual reasoning.
3. **Raw Motor / PyMongo dict access** — no declared schema to lift; out of scope for
   the deterministic core (the separate ~29k-file LLM tail).

## 6. The gate must be BEHAVIORAL, not `jac check`

`jac check` passes a hollow walker (`can go with Root entry { report []; }`) just as
readily as the faithful one — the exact failure mode that produced the current
stripped corpus. The keep signal must be a **round-trip**: spawn `create_todo`, then
`list_todos`, assert the created node comes back; spawn `complete_todo` on its id,
assert `done == True`; spawn `delete_todo`, assert it's gone. A node type whose
generated walkers can't round-trip its own CRUD is rejected. This replaces
"type-checks green" as the arbiter and is the next build item.
