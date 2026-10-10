# jh-neuroflow-48385c52

Source: jachacks_spring. Level 2.

Starter at jac 0.36.1: 3 errors in 2 file(s); codes {'E-file': 2, 'E0005': 1}.

Sample diagnostics:
- `E-file neuroflow-app/components/Button.cl.jac:None Error checking 'neuroflow-app/components/Button.cl.jac': neuroflow-app/components/Button.cl.jac: the .cl.jac marker was `
- `E-file None:None neuroflow-app/main.jac:3:1 'cl' placement markers were removed: placement is inferred (override via [placement.pins] in `
- `E0005 neuroflow-app/main.jac:6 Unexpected token 'to'`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-neuroflow-48385c52 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- starter_profile: pass=False check=None sym=0.5 mass=1.014 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.179 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
