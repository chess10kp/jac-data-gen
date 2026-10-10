# jh-evacuai-fe9864a6

Source: jachacks_spring. Level 2.

Starter at jac 0.37.25: 4 errors in 1 file(s); codes {'E0027': 2, 'E1116': 1, 'E2086': 1}.

Sample diagnostics:
- `E0027 jac/graph.jac:17 Expected ':+>' to close forward typed connection -- did you mean '+>: <EdgeType> :+> <node>'?`
- `E0027 jac/graph.jac:19 Expected ':+>' to close forward typed connection -- did you mean '+>: <EdgeType> :+> <node>'?`
- `E1116 jac/graph.jac:10 Walker ability trigger must be a node, edge, or `Root`, got "root"`
- `E2086 jac/graph.jac:6 Edge 'Road' declares no endpoints, so every traversal through it widens to 'any'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-evacuai-fe9864a6 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.072 body=1.037 min_file_body=1.037
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.268 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
