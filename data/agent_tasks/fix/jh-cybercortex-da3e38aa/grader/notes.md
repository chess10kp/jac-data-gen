# jh-cybercortex-da3e38aa

Source: jachacks_spring. Level 4.

Starter at jac 0.36.1: 22 errors in 2 file(s); codes {'E1032': 10, 'E0005': 4, 'E2018': 3, 'E0030': 2, 'E0002': 1, 'E0004': 1, 'E0034': 1}.

Sample diagnostics:
- `E0002 agents.jac:1 Missing ';'`
- `E0005 agents.jac:1 Unexpected token ':'`
- `E0005 agents.jac:1 Unexpected token '}'`
- `E0030 agents.jac:1 Unexpected semicolon at module level`
- `E0004 agents.jac:17 Unexpected token in expression: '-->'`
- `E1032 agents.jac:7 Type is Unknown, cannot access attribute "ip_address"`
- `E1032 agents.jac:8 Type is Unknown, cannot access attribute "status"`
- `E1032 agents.jac:9 Type is Unknown, cannot access attribute "vulnerabilities"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-cybercortex-da3e38aa <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.017 min_file_body=1.0
- starter_profile: pass=False check=None sym=0.833 mass=1.021 body=1.092 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.487 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
