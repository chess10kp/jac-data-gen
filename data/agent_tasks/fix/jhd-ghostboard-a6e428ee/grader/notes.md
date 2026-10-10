# jhd-ghostboard-a6e428ee

Source: jachacks_spring_toolchain_drift. Level 2.

Starter at jac 0.37.25: 4 errors in 2 file(s); codes {'E2086': 3, 'E1036': 1}.

Sample diagnostics:
- `E2086 models.jac:75 Edge 'manages' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 models.jac:76 Edge 'reports_to' declares no endpoints, so every traversal through it widens to 'any'`
- `E2086 models.jac:77 Edge 'monitoring' declares no endpoints, so every traversal through it widens to 'any'`
- `E1036 client.jac:16 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jhd-ghostboard-a6e428ee <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.022 body=1.007 min_file_body=1.007
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.315 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.298 mass=0.0 body=0.0 min_file_body=0.0
