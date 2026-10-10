# jh-traceforge-9d3942e5

Source: jachacks_2026. Level 2.

Starter at jac 0.37.25: 3 errors in 1 file(s); codes {'E0022': 1, 'E0002': 1, 'E0006': 1}.

Sample diagnostics:
- `E0022 scripts/validate_gold_annotations.jac:141 Expected '{' after lambda parameters`
- `E0002 scripts/validate_gold_annotations.jac:141 Missing ','`
- `E0006 scripts/validate_gold_annotations.jac:141 Unexpected token`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-traceforge-9d3942e5 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.003 body=1.003 min_file_body=1.003
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.123 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
