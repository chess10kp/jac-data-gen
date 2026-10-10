# nat-l3-tool-library
OSP + persistence: state lives in nodes/edges on root across separate spawns; the run gate
replays a seed in one `jac run` process and queries in a SECOND process in the same cwd,
so a module-global/dict implementation that passes in-process tests is still rejected.
Requirements: check order (unknown/already lent/limit), get-or-create member, due = day+loan_days,
Return deletes only the edge, overdue strict + ordered (due, code).
Alternative: get-or-create via `visit ... else`, Return as a traversal over members, dict rows.
