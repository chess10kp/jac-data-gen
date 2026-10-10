# jh-orion-and-diana-jachacks-20e769c3

Source: jachacks_spring. Level 3.

Starter at jac 0.36.1: 8 errors in 1 file(s); codes {'E1030': 3, 'E0002': 2, 'E0005': 1, 'E0001': 1, 'E1116': 1}.

Sample diagnostics:
- `E0005 v2/orion.jac:11 Unexpected token 'from'`
- `E0002 v2/orion.jac:13 Missing ';'`
- `E0001 v2/orion.jac:65 Expected '{', got ':'`
- `E0002 v2/orion.jac:76 Missing '}'`
- `E1116 v2/orion.jac:37 Walker ability trigger must be a node, edge, or `Root`, got "root"`
- `E1030 v2/orion.jac:50 Type "sar_fetch" has no attribute "lat"`
- `E1030 v2/orion.jac:50 Type "sar_fetch" has no attribute "lon"`
- `E1030 v2/orion.jac:72 Type "rgb_fetch" has no attribute "final_result"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-orion-and-diana-jachacks-20e769c3 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.008 body=1.004 min_file_body=1.004
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.367 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
