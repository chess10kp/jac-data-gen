The dashboard only ever shows the current state of the board, but ops keeps asking "what fired last week?". Crises are already stored as `Crisis` nodes on root when an orchestration runs, we just never expose them.

Can you add a public server function `get_crisis_history` in `server.jac` next to the other `def:pub` API functions? It should return the stored `Crisis` nodes newest first (by `triggered_at`). Two optional knobs:

- `limit: int = 10` — max number of crises to return (0 means none)
- `min_severity: str = "INFO"` — only include crises at or above this severity. Order is INFO < WARNING < ELEVATED < HIGH < CRITICAL, and it should accept lowercase too ("high").

Don't change how crises get created or the existing endpoints. Make sure `jac check` stays clean.
