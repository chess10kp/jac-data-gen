# jhd-fraudgraph-a512d7c0

Source: jachacks_spring_toolchain_drift. Level 3.

Starter at jac 0.37.25: 11 errors in 1 file(s); codes {'E1036': 8, 'E2086': 3}.

Sample diagnostics:
- `E1036 backend/jac/fraud_agent.jac:49 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:64 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:88 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:162 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:227 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:262 Generic type "dict" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:280 Generic type "list" requires explicit type arguments`
- `E1036 backend/jac/fraud_agent.jac:303 Generic type "dict" requires explicit type arguments`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jhd-fraudgraph-a512d7c0 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.036 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.395 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
