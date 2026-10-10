# jh-arda-agent-37bc646e

Source: jachacks_spring. Level 5.

Starter at jac 0.36.1: 60 errors in 1 file(s); codes {'E0046': 19, 'E0034': 16, 'E0002': 9, 'E0076': 7, 'E1032': 3, 'E0005': 2, 'E0030': 2, 'E1054': 2}.

Sample diagnostics:
- `E0002 jac_app/memory.jac:5 Missing ';'`
- `E0005 jac_app/memory.jac:5 Unexpected token ':'`
- `E0030 jac_app/memory.jac:5 Unexpected semicolon at module level`
- `E0002 jac_app/memory.jac:6 Missing ';'`
- `E0005 jac_app/memory.jac:6 Unexpected token ':'`
- `E0030 jac_app/memory.jac:6 Unexpected semicolon at module level`
- `E0034 jac_app/memory.jac:17 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`
- `E0034 jac_app/memory.jac:18 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-arda-agent-37bc646e <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.018 min_file_body=1.018
- starter_profile: pass=True check=None sym=1.0 mass=1.06 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.274 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
