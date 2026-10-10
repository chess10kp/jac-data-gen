# jh-civicmesh-e5947708

Source: jachacks_spring. Level 1.

Starter at jac 0.36.1: 1 errors in 1 file(s); codes {'E-file': 1}.

Sample diagnostics:
- `E-file civicmesh/components/SessionBanner.cl.jac:None Error checking 'civicmesh/components/SessionBanner.cl.jac': civicmesh/components/SessionBanner.cl.jac: the .cl.jac marke`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-civicmesh-e5947708 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.003 body=1.003 min_file_body=1.003
- starter_profile: pass=False check=None sym=0.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.024 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
