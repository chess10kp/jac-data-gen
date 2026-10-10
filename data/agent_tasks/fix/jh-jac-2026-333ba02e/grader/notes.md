# jh-jac-2026-333ba02e

Source: jachacks_2026. Level 1.

Starter at jac 0.36.1: 1 errors in 1 file(s); codes {'E1032': 1}.

Sample diagnostics:
- `E1032 agents/damage_estimator.jac:128 Type is Unknown, cannot access attribute "damage_done"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jac-2026-333ba02e <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.007 body=1.008 min_file_body=1.008
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.153 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.917 mass=0.0 body=0.0 min_file_body=0.0
