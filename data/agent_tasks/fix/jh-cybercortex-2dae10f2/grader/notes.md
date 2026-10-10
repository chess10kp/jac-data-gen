# jh-cybercortex-2dae10f2

Source: jachacks_spring. Level 3.

Starter at jac 0.37.25: 10 errors in 1 file(s); codes {'E0005': 2, 'E1036': 2, 'E1032': 2, 'E2086': 2, 'E0030': 1, 'E0034': 1}.

Sample diagnostics:
- `E0005 graph.jac:15 Unexpected token 'graph'`
- `E0030 graph.jac:16 Unexpected semicolon at module level`
- `E0034 graph.jac:18 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`
- `E0005 graph.jac:24 Unexpected token '}'`
- `E1036 graph.jac:4 Generic type "list" requires explicit type arguments`
- `E1036 graph.jac:9 Generic type "list" requires explicit type arguments`
- `E1032 graph.jac:19 Type is Unknown, cannot access attribute "start_node"`
- `E1032 graph.jac:22 Type is Unknown, cannot access attribute "start_node"`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-cybercortex-2dae10f2 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.143 body=1.0 min_file_body=1.0
- starter_profile: pass=False check=None sym=0.75 mass=1.0 body=1.478 min_file_body=1.478
- stub: pass=False check=True sym=1.0 mass=0.908 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
