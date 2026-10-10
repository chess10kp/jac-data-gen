# jh-jac-e2767359

Source: jachacks_spring. Level 3.

Starter at jac 0.36.1: 4 errors in 1 file(s); codes {'E0105': 1, 'E0004': 1, 'E1032': 1, 'E1116': 1}.

Sample diagnostics:
- `E0105 walkers/drug_stats.jac:6 Unexpected character: '`'`
- `E0004 walkers/drug_stats.jac:6 Unexpected token in expression: 'ERROR'`
- `E1032 walkers/drug_stats.jac:6 Type is Unknown, cannot access attribute "Drug"`
- `E1116 walkers/drug_stats.jac:5 Walker ability trigger must be a node, edge, or `Root`, got "root"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jac-e2767359 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.046 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.005 min_file_body=1.005
- stub: pass=False check=True sym=1.0 mass=0.204 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.826 mass=0.0 body=0.0 min_file_body=0.0
