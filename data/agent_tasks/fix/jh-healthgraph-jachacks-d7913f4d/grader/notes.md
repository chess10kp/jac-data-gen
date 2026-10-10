# jh-healthgraph-jachacks-d7913f4d

Source: jachacks_spring. Level 1.

Starter at jac 0.36.1: 2 errors in 1 file(s); codes {'E1053': 2}.

Sample diagnostics:
- `E1053 main.jac:80 Cannot assign str | int to parameter 'description' of type str`
- `E1053 main.jac:82 Cannot assign str | int to parameter 'duration_days' of type int`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-healthgraph-jachacks-d7913f4d <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.01 body=1.019 min_file_body=1.019
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.48 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
