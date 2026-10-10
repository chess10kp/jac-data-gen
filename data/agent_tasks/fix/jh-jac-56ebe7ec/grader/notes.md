# jh-jac-56ebe7ec

Source: jachacks_spring. Level 2.

Starter at jac 0.37.25: 2 errors in 2 file(s); codes {'E1036': 1, 'E1116': 1}.

Sample diagnostics:
- `E1036 graph/nodes.jac:22 Generic type "list" requires explicit type arguments`
- `E1116 tests/test_walker2.jac:6 Walker ability trigger must be a node, edge, or `Root`, got "root"`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jac-56ebe7ec <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.077 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.577 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
