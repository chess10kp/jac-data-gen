# ghostboard-reporting-lines

The `reports_to` edge exists in models.jac but nothing creates it. New behaviour:
- `initialize_graph()` links subordinate -[reports_to]-> manager per the org chart in request.md, idempotently
  (second call adds no duplicate edges), also for graphs seeded before the change.
- `def:pub get_direct_reports(exec_id) -> list[Executive]` sorted by id; unknown id -> [].
- `def:pub get_chain_of_command(exec_id) -> list[str]` ids from exec up to the top, inclusive; unknown -> [].
Tests check the edges structurally (`[hr ->:reports_to:->]`), so a dict lookup without graph edges fails.
Regression: 6 executives after repeated init; metrics still readable.
