# osp-iss-leonarduk-issue-worm-0da0ef2b

Source: osp_repair_code_fix. Level 4.

Starter at jac 0.36.1: 16 errors in 1 file(s); codes {'E0002': 6, 'E0004': 4, 'E0048': 2, 'E0001': 1, 'E0032': 1, 'E1053': 1, 'E1055': 1}.

Sample diagnostics:
- `E0048 main.jac:62 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 main.jac:89 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0004 main.jac:91 Unexpected token in expression: ':'`
- `E0002 main.jac:91 Missing ']'`
- `E0002 main.jac:91 Missing ')'`
- `E0001 main.jac:91 Expected 'else', got 'NAME'`
- `E0004 main.jac:91 Unexpected token in expression: ':->'`
- `E0002 main.jac:91 Missing ';'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/osp-iss-leonarduk-issue-worm-0da0ef2b <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.233 min_file_body=1.233 test=True
- starter_profile: pass=False check=None sym=0.8 mass=1.18 body=1.0 min_file_body=1.0 test=False
- stub: pass=False check=True sym=1.0 mass=0.5 body=0.0 min_file_body=0.0 test=False
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0 test=False

grader/tests.jac is the verified annex test suite rewritten as a separate module (`import from main {...}`); run `jac test tests.jac` with it copied next to the candidate main.jac.
