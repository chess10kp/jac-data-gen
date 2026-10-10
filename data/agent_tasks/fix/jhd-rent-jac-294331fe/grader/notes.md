# jhd-rent-jac-294331fe

Source: jachacks_2026_toolchain_drift. Level 1.

Starter at jac 0.37.25: 2 errors in 1 file(s); codes {'E1036': 2}.

Sample diagnostics:
- `E1036 shared.jac:28 Generic type "list" requires explicit type arguments`
- `E1036 shared.jac:29 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jhd-rent-jac-294331fe <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.005 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.299 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.025 mass=0.0 body=0.0 min_file_body=0.0
