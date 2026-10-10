# osp-iss-blamechris-chroxy-9fddf2df

Source: osp_repair_code_fix. Level 4.

Starter at jac 0.37.25: 15 errors in 1 file(s); codes {'E2086': 4, 'E1036': 3, 'E0005': 2, 'E0052': 2, 'E2015': 2, 'E0013': 1, 'E1030': 1}.

Sample diagnostics:
- `E0013 main.jac:71 'match' is a keyword and cannot be used as a ability name`
- `E0005 main.jac:126 Unexpected token '{'`
- `E0005 main.jac:128 Unexpected token '}'`
- `E0052 main.jac:71 Parameter 'self' is missing a type annotation`
- `E0052 main.jac:86 Parameter 'self' is missing a type annotation`
- `E1036 main.jac:43 Generic type "list" requires explicit type arguments`
- `E1030 main.jac:75 Type "Message" has no attribute "belongs_to_project"`
- `E2015 main.jac:71 Explicit 'self' parameter is not allowed in walker method 'match' — 'self' is implicit in obj, node, edge, and walker me`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-blamechris-chroxy-9fddf2df <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.599 body=1.0 min_file_body=1.0 test=True
- starter_profile: pass=False check=None sym=0.4 mass=1.0 body=1.108 min_file_body=1.108 test=False
- stub: pass=False check=True sym=1.0 mass=1.093 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.
