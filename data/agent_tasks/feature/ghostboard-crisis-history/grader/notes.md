# ghostboard-crisis-history

New: `def:pub get_crisis_history(limit: int = 10, min_severity: str = "INFO") -> list[Crisis]` in `server.jac`.
Checks (grader/tests.jac, dropped at `tests_feature.jac` in the workspace root, relative imports like the app):
- newest-first ordering by `triggered_at` over Crisis nodes attached to root
- `limit` caps the list; `limit=0` returns empty
- `min_severity` is inclusive and case-insensitive with order INFO < WARNING < ELEVATED < HIGH < CRITICAL
Regression: `initialize_graph()` idempotent (6 executives after two calls), `get_system_metrics()` still works.
The LLM-backed `trigger_orchestration` is not exercised (no API key in grading).
