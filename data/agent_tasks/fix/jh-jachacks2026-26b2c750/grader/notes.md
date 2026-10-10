# jh-jachacks2026-26b2c750

Source: jachacks_2026. Level 2.

Starter at jac 0.37.25: 4 errors in 1 file(s); codes {'E0049': 3, 'E1002': 1}.

Sample diagnostics:
- `E0049 config.sv.jac:14 'root()' was removed. Use bare 'root' instead.`
- `E0049 config.sv.jac:29 'root()' was removed. Use bare 'root' instead.`
- `E1002 config.sv.jac:29 Cannot return <Unknown>, expected IntegrationConfig`
- `E0049 config.sv.jac:73 'root()' was removed. Use bare 'root' instead.`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jachacks2026-26b2c750 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.023 body=1.031 min_file_body=1.031
- stub: pass=False check=True sym=1.0 mass=0.262 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.778 mass=0.0 body=0.0 min_file_body=0.0
