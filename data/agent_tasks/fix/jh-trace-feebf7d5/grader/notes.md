# jh-trace-feebf7d5

Source: jachacks_2026. Level 4.

Starter at jac 0.36.1: 17 errors in 1 file(s); codes {'E1032': 9, 'E0022': 1, 'E0002': 1, 'E0006': 1, 'E1053': 1, 'E1054': 1, 'E1001': 1, 'E1116': 1, 'E2018': 1}.

Sample diagnostics:
- `E0022 artifacts/jac-backend/walkers/recall.jac:49 Expected '{' after lambda parameters`
- `E0002 artifacts/jac-backend/walkers/recall.jac:49 Missing ','`
- `E0006 artifacts/jac-backend/walkers/recall.jac:49 Unexpected token`
- `E1032 artifacts/jac-backend/walkers/recall.jac:23 Type is Unknown, cannot access attribute "content"`
- `E1053 artifacts/jac-backend/walkers/recall.jac:23 Cannot assign <Unknown> to parameter 'memory_content' of type str`
- `E1032 artifacts/jac-backend/walkers/recall.jac:27 Type is Unknown, cannot access attribute "content"`
- `E1032 artifacts/jac-backend/walkers/recall.jac:28 Type is Unknown, cannot access attribute "memory_type"`
- `E1032 artifacts/jac-backend/walkers/recall.jac:29 Type is Unknown, cannot access attribute "timestamp"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-trace-feebf7d5 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.038 body=1.039 min_file_body=1.039
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.371 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.72 mass=0.0 body=0.0 min_file_body=0.0
