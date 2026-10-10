# jh-legalforge-ai-07f03378

Source: jachacks_spring. Level 2.

Starter at jac 0.37.25: 3 errors in 1 file(s); codes {'E1116': 2, 'E1036': 1}.

Sample diagnostics:
- `E1116 service_test.jac:14 Walker ability trigger must be a node, edge, or `Root`, got "root"`
- `E1036 service_test.jac:39 Generic type "list" requires explicit type arguments`
- `E1116 service_test.jac:41 Walker ability trigger must be a node, edge, or `Root`, got "root"`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-legalforge-ai-07f03378 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.012 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.424 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
