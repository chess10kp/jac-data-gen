# jh-insuraagent-c79c9cf3

Source: jachacks_spring. Level 1.

Starter at jac 0.37.25: 2 errors in 1 file(s); codes {'E1001': 2}.

Sample diagnostics:
- `E1001 probe_featherless.jac:86 Cannot assign DenialReason to str`
- `E1001 probe_featherless.jac:94 Cannot assign PolicyClause to str`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-insuraagent-c79c9cf3 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.005 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.955 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.894 mass=0.0 body=0.0 min_file_body=0.0
