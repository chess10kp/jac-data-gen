# jh-jaccaremind-ai-d83fe3d2

Source: jachacks_spring. Level 5.

Starter at jac 0.36.1: 55 errors in 1 file(s); codes {'E0005': 16, 'E0030': 12, 'E0046': 10, 'E0002': 9, 'E0034': 6, 'E0004': 1, 'E1053': 1}.

Sample diagnostics:
- `E0002 caremind_agents.jac:5 Missing ';'`
- `E0005 caremind_agents.jac:5 Unexpected token ':'`
- `E0005 caremind_agents.jac:5 Unexpected token '}'`
- `E0002 caremind_agents.jac:6 Missing ';'`
- `E0005 caremind_agents.jac:6 Unexpected token ':'`
- `E0030 caremind_agents.jac:6 Unexpected semicolon at module level`
- `E0002 caremind_agents.jac:7 Missing ';'`
- `E0005 caremind_agents.jac:7 Unexpected token ':'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-jaccaremind-ai-d83fe3d2 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.066 body=1.187 min_file_body=1.187
- starter_profile: pass=True check=None sym=0.979 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.406 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
