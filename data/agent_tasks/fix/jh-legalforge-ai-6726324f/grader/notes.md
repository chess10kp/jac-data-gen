# jh-legalforge-ai-6726324f

Source: jachacks_spring. Level 2.

Starter at jac 0.36.1: 3 errors in 1 file(s); codes {'E0105': 1, 'E0004': 1, 'E1032': 1}.

Sample diagnostics:
- `E0105 agents/risk_scorer.jac:11 Unexpected character: '`'`
- `E0004 agents/risk_scorer.jac:11 Unexpected token in expression: 'ERROR'`
- `E1032 agents/risk_scorer.jac:11 Type is Unknown, cannot access attribute "Clause"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-legalforge-ai-6726324f <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.004 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.004 min_file_body=1.004
- stub: pass=False check=True sym=1.0 mass=0.164 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.924 mass=0.0 body=0.0 min_file_body=0.0
