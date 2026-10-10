# jh-sentinel-121f4bc9

Source: jachacks_spring. Level 3.

Starter at jac 0.36.1: 5 errors in 1 file(s); codes {'E0022': 1, 'E0002': 1, 'E0006': 1, 'E1054': 1, 'E1053': 1}.

Sample diagnostics:
- `E0022 src/agents/billing_walker.jac:98 Expected '{' after lambda parameters`
- `E0002 src/agents/billing_walker.jac:98 Missing ','`
- `E0006 src/agents/billing_walker.jac:98 Unexpected token`
- `E1054 src/agents/billing_walker.jac:97 No matching overload found for the function call with the given arguments`
- `E1053 src/agents/billing_walker.jac:140 Cannot assign <Unknown> to parameter 'top_diagnosis_codes' of type list[str]`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-sentinel-121f4bc9 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.007 body=1.009 min_file_body=1.009
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.212 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.659 mass=0.0 body=0.0 min_file_body=0.0
