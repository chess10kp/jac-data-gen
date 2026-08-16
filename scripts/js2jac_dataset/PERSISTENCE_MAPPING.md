# js2jac persistence mapping (Prisma / ORM → Jac graph)

Status: design sketch. Motivation: the current pipeline **strips** every DB call
(`strip_policy.json` → `new:PrismaClient` = `"strip", "lossy"`), producing hollow
stubs that type-check green. Jac's differentiator is native graph persistence, which
is exactly the idiomatic target these calls should map to. This doc defines that map.

## 0. The one idea

**A relational ORM models data as tables + foreign keys + WHERE-scoping. Jac models
the same data as a graph: nodes reachable from `root`, joined by typed edges.** The
mapping is therefore not line-by-line — it is a *schema lift* plus a *call rewrite*:

| Relational world | Jac world |
|---|---|
| `model Foo` (a table) | `node Foo { has ...; }` |
| scalar column | `has field: type;` |
| foreign key / relation (`Post.authorId`) | **typed edge** `edge Wrote: User --> Post` |
| primary key `id` (cuid/uuid) | `jid(n)` — the node's opaque id |
| `WHERE userId = <me>` (row-level tenancy) | **structural**: the row hangs off *that user's* `root` |
| a JOIN | an edge traversal `[u ->:Wrote:->]` |

The last two rows are the payoff: multi-tenant scoping and joins that Prisma does with
runtime `where` filters, Jac does *structurally* — per-user `root` + edges — so a whole
class of filter code disappears instead of being translated.

## 1. Call-site rewrite table

Let `M` be a Prisma model mapped to node `M`, related to `User` by `edge Owns: User --> M`.

| Prisma | Jac (server, runs in caller's request context) |
|---|---|
| `prisma.m.create({ data })` | `root ++> M(...)`  (or `owner +>:Owns:+> M(...)`) |
| `prisma.m.findUnique({ where:{ id } })` | `jobj(id)` then `isinstance(x, M)` — O(1), reaches cross-user grants |
| `prisma.m.findFirst({ where:{ f } })` | `[root -->][?:M][?f == v]` → take `[0]` |
| `prisma.m.findMany()` | `[root -->][?:M]` |
| `prisma.m.findMany({ where:{ f } })` | `[root -->][?:M][?f == v]` |
| `prisma.m.update({ where:{ id }, data })` | resolve via `jobj(id)`; mutate in place `x.f = v` (auto-persists) |
| `prisma.m.updateMany({ where, data })` | assign comprehension `[root-->[?:M][?...]](=f=v)` |
| `prisma.m.delete({ where:{ id } })` | `del jobj(id)` (cascades its edges) |
| `prisma.m.count({ where })` | `len([root -->][?:M][?...])` |
| `user.posts` (relation load) | `[user ->:Owns:->][?:M]` |
| `include: { author: true }` | traverse the inverse edge `[m <-:Owns:<-][?:User]` |
| `select: { a, b }` (projection) | a `to_view()` view-model `obj` (see jac-sv-persistence) |
| `$transaction([...])` | endpoint body is already atomic per request; writes commit on return |

Handler shell:

| Next.js route | Jac endpoint |
|---|---|
| `export async function GET(req)` | `def:pub GET(...) -> <ret>` (no traversal) or `walker:pub` (if it walks) |
| auth: `session.user` guard | `def:priv` → runs on caller's own `root`; no manual check |
| `NextResponse.json(x)` | `return x;` (auto-serialized envelope) |
| admin check `user.admin === true` | `has admin: bool` on `User` node + role gate |

## 2. Worked example — the route the pipeline currently guts

Source (`api/admin/reset/[requesterId]/route.ts`), abbreviated:

```ts
const requester = await prisma.user.findUnique({
  where: { id: requesterId }, select: { admin: true }
});
if (requester?.admin === false)
  return NextResponse.json({ error: "not authorized" });
// delete all businesses + upgrades for the target player, bump user.resets
```

Faithful Jac (what the converter *should* emit):

```jac
node User { has admin: bool = False; has resets: int = 0; }
node Business {}
node Upgrade {}
edge Owns: User --> Business {}
edge Has:  User --> Upgrade  {}

def:pub reset_player(requester_id: str, target_id: str) -> dict[str, str] {
    requester = jobj(requester_id);
    if not isinstance(requester, User) { return {"error": "Invalid requester"}; }
    if not requester.admin            { return {"error": "not authorized"}; }

    target = jobj(target_id);
    if not isinstance(target, User)   { return {"error": "Invalid target"}; }

    for b in [target ->:Owns:->][?:Business] { del b; }   # cascade wipes edges
    for u in [target ->:Has:->][?:Upgrade]   { del u; }
    target.resets += 1;                                    # auto-persists
    return {"status": "ok"};
}
```

Note what vanished vs. the current stub: the `{"status":"ok"}` is the *same* line, but
now it is reached *after real graph mutations*, not instead of them.

## 3. Why the current converter cannot do this (the hard part)

1. **Relationships are global, the converter is per-file.** `edge Owns: User --> Business`
   comes from `schema.prisma` (or inferred FKs), not from the route file. A fail-open
   *per-declaration* converter never sees the schema, so it cannot know `user.businesses`
   is an edge traversal. **A persistence pass must first ingest the schema** and emit the
   `node`/`edge` archetypes once, project-wide, before rewriting any call site.

2. **Identity model differs.** Prisma ids are stored scalars; Jac ids are `jid`. Two
   options: (a) adopt `jid` as identity and rewrite `where:{id}` → `jobj(id)` (clean, but
   external ids in URLs must be jids); (b) keep the external id as `has ext_id: str` and
   filter `[root-->[?:M][?ext_id==id]]` (compatible, O(n)). Pick per corpus; default (a)
   for greenfield, (b) for migrations.

3. **`where` scoping ≠ pure filter.** `where:{ userId: session.user.id }` is *tenancy*,
   not a predicate — it should collapse into "this hangs off the caller's `root`", which
   requires knowing which fields are the tenant key. Needs a heuristic or annotation.

4. **The gate can't reward faithfulness.** `jac check` passes the hollow stub *and* the
   faithful version. A persistence pass needs a **behavioral** check (does a
   create-then-read round-trip return the row?), not just type-check green — otherwise the
   LLM keeps regressing to the strippable form. See the mutation-gate work for the shape.

## 4. Minimum the converter needs to gain

- **A schema loader**: parse `schema.prisma` → `{model, fields, relations}` → emit
  `node`/`edge` archetypes (endpoint types on edges so traversals infer node types —
  avoids the W1051/E1053 latent-bug trap from jac-node-edge-patterns).
- **A call-site rewriter**: the table in §1, dispatched on the Prisma method name.
- **A tenancy heuristic**: which `where` keys are the current-user scope → drop into
  `root`; which are real predicates → keep as `[?...]`.
- **A behavioral gate**: round-trip a create/read/update/delete per emitted node type;
  reject on divergence. This replaces "type-checks green" as the keep signal.

Scope note: this covers Prisma first (7 records + the dominant pattern). `fetch`/axios,
firebase, and `localStorage` are *different* targets (external service call, doc store,
client-side KV) and each needs its own mapping doc — do not fold them into this one.
