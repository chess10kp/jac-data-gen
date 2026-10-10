# osp-iss-marin-community-marin-01166168

Source: osp_repair_code_fix. Level 4.

Starter at jac 0.36.1: 13 errors in 1 file(s); codes {'E0002': 5, 'E0004': 3, 'E1001': 2, 'E0001': 1, 'E0032': 1, 'E1030': 1}.

Sample diagnostics:
- `E0002 main.jac:91 Missing ')'`
- `E0001 main.jac:91 Expected 'else', got '-->'`
- `E0004 main.jac:91 Unexpected token in expression: '->:'`
- `E0002 main.jac:91 Missing ';'`
- `E0002 main.jac:91 Missing ';'`
- `E0004 main.jac:91 Unexpected token in expression: ':->'`
- `E0002 main.jac:91 Missing ';'`
- `E0004 main.jac:91 Unexpected token in expression: ')'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-marin-community-marin-01166168 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.191 body=1.603 min_file_body=1.603 test=False
- stub: pass=False check=True sym=1.0 mass=0.742 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.
