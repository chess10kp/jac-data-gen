# osp-iss-raydocs-aureo-1da51139

Source: osp_repair_code_fix. Level 5.

Starter at jac 0.37.25: 39 errors in 1 file(s); codes {'E0002': 16, 'E0004': 9, 'E0003': 4, 'E2086': 4, 'E0077': 3, 'E0013': 1, 'E1036': 1, 'E1010': 1}.

Sample diagnostics:
- `E0004 main.jac:55 Unexpected token in expression: '-->'`
- `E0013 main.jac:135 'obj' is a keyword and cannot be used as a variable name`
- `E0003 main.jac:158 Expected identifier, got '+>:'`
- `E0002 main.jac:158 Missing ';'`
- `E0004 main.jac:158 Unexpected token in expression: '+>:'`
- `E0002 main.jac:158 Missing ';'`
- `E0002 main.jac:158 Missing ';'`
- `E0004 main.jac:158 Unexpected token in expression: ':+>'`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-raydocs-aureo-1da51139 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.037 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=1.0 mass=1.0 body=1.004 min_file_body=1.004 test=False
- stub: pass=False check=True sym=1.0 mass=0.655 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.
