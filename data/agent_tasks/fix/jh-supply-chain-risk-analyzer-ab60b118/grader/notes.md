# jh-supply-chain-risk-analyzer-ab60b118

Source: jachacks_2026. Level 2.

Starter at jac 0.36.1: 4 errors in 1 file(s); codes {'E0049': 2, 'E1002': 1, 'E1001': 1}.

Sample diagnostics:
- `E0049 services/supply_chain.sv.jac:79 'root()' was removed. Use bare 'root' instead.`
- `E0049 services/supply_chain.sv.jac:90 'root()' was removed. Use bare 'root' instead.`
- `E1002 services/supply_chain.sv.jac:90 Cannot return <Unknown>, expected Package`
- `E1001 services/supply_chain.sv.jac:260 Cannot assign <Unknown> to str`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-supply-chain-risk-analyzer-ab60b118 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.012 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=0.988 mass=1.0 body=1.008 min_file_body=1.008
- stub: pass=False check=True sym=1.0 mass=0.412 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
