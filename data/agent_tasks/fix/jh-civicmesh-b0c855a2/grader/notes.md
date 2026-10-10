# jh-civicmesh-b0c855a2

Source: jachacks_spring. Level 4.

Starter at jac 0.37.25: 21 errors in 2 file(s); codes {'E2086': 7, 'E0002': 4, 'E1036': 4, 'E0004': 2, 'E0014': 1, 'E0022': 1, 'E0006': 1, 'E1054': 1}.

Sample diagnostics:
- `E2086 civicmesh/graph/edges.jac:9 Edge 'has_need' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:13 Edge 'eligible_for' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:17 Edge 'governed_by' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:21 Edge 'requires_form' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:25 Edge 'applied_to' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:35 Edge 'leads_to' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 civicmesh/graph/edges.jac:47 Edge 'reflected_on' declares no endpoints, so every traversal through it widens to 'any'`
- `E0014 civicmesh/walkers/critique.jac:195 'Root' is not a keyword -- remove the backtick`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-civicmesh-b0c855a2 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.018 body=1.008 min_file_body=1.008
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.21 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.691 mass=0.0 body=0.0 min_file_body=0.0
