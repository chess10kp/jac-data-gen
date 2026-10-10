# osp-iss-affaan-m-ecc-3ecff142

Source: osp_repair_code_fix. Level 5.

Starter at jac 0.36.1: 39 errors in 1 file(s); codes {'E0046': 11, 'E1001': 8, 'E1030': 7, 'E0002': 3, 'E0005': 3, 'E0077': 3, 'E1032': 2, 'E0034': 1, 'E0030': 1}.

Sample diagnostics:
- `E0034 main.jac:40 Expected 'with' after 'can' ability name (use 'def' for function-style declarations)`
- `E0002 main.jac:40 Missing ';'`
- `E0046 main.jac:40 Unexpected token in archetype body`
- `E0002 main.jac:40 Missing ';'`
- `E0046 main.jac:40 Unexpected token in archetype body`
- `E0046 main.jac:40 Unexpected token in archetype body`
- `E0046 main.jac:44 Unexpected token in archetype body`
- `E0046 main.jac:44 Unexpected token in archetype body`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-affaan-m-ecc-3ecff142 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.113 min_file_body=1.113 test=True
- starter_profile: pass=False check=None sym=0.0 mass=1.132 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.618 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.
