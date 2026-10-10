# jh-jachacks-7cfd00fd

Source: jachacks_2026. Level 3.

Starter at jac 0.36.1: 5 errors in 1 file(s); codes {'E1032': 3, 'E0049': 1, 'E1002': 1}.

Sample diagnostics:
- `E0049 api.jac:34 'root()' was removed. Use bare 'root' instead.`
- `E1032 api.jac:51 Type is Unknown, cannot access attribute "get"`
- `E1032 api.jac:52 Type is Unknown, cannot access attribute "get"`
- `E1032 api.jac:53 Type is Unknown, cannot access attribute "get"`
- `E1002 api.jac:57 Cannot return <Unknown>, expected dict`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jachacks-7cfd00fd <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.057 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.337 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.95 mass=0.0 body=0.0 min_file_body=0.0
