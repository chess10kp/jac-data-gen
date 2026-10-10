# jh-evacuai-281c1afa

Source: jachacks_spring. Level 4.

Starter at jac 0.36.1: 24 errors in 1 file(s); codes {'E0002': 14, 'E0034': 2, 'E0004': 2, 'E1097': 2, 'E1055': 2, 'E1001': 1, 'E1053': 1}.

Sample diagnostics:
- `E0034 jac/brain.jac:21 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`
- `E0034 jac/brain.jac:33 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`
- `E0002 jac/brain.jac:35 Missing ';'`
- `E0002 jac/brain.jac:36 Missing ';'`
- `E0002 jac/brain.jac:37 Missing ';'`
- `E0002 jac/brain.jac:51 Missing ';'`
- `E0002 jac/brain.jac:63 Missing ';'`
- `E0002 jac/brain.jac:99 Missing ';'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-evacuai-281c1afa <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.015 body=1.018 min_file_body=1.018
- stub: pass=False check=True sym=1.0 mass=0.41 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
