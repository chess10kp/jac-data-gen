We declared a `reports_to` edge in `models.jac` but never actually use it, so the board has no org chart. I'd like the executives wired up as a real reporting hierarchy in the graph:

- CTO, Marketing and Operations report to the CEO
- HR reports to Operations
- Security reports to the CTO

(ids: ceo, cto, mkt, ops, hr, sec — same as in `initialize_graph`). The edge should point from the subordinate to their manager. `initialize_graph()` should set this up, and calling it again must not create duplicate edges (it's called on every server start).

Then expose two server functions in `server.jac`:

1. `get_direct_reports(exec_id: str) -> list[Executive]` — the executives reporting directly to that person, sorted by id. Unknown id → empty list.
2. `get_chain_of_command(exec_id: str) -> list[str]` — ids from that executive up to the top, e.g. `hr` → `["hr", "ops", "ceo"]`. Unknown id → empty list.

Please do it with graph traversal over the `reports_to` edges rather than a hardcoded lookup at query time.
