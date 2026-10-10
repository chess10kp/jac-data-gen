# jh-financial-time-machine-agent-dfa50a56

Source: jachacks_spring. Level 4.

Starter at jac 0.36.1: 15 errors in 1 file(s); codes {'E2018': 7, 'E1032': 5, 'E0002': 1, 'E0005': 1, 'E0030': 1}.

Sample diagnostics:
- `E0002 jac-backend/agents.jac:1 Missing ';'`
- `E0005 jac-backend/agents.jac:1 Unexpected token ':'`
- `E0030 jac-backend/agents.jac:1 Unexpected semicolon at module level`
- `E1032 jac-backend/agents.jac:47 Type is Unknown, cannot access attribute "current_savings"`
- `E1032 jac-backend/agents.jac:57 Type is Unknown, cannot access attribute "amount"`
- `E1032 jac-backend/agents.jac:59 Type is Unknown, cannot access attribute "category_name"`
- `E1032 jac-backend/agents.jac:65 Type is Unknown, cannot access attribute "goal_name"`
- `E1032 jac-backend/agents.jac:82 Type is Unknown, cannot access attribute "monthly_income"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-financial-time-machine-agent-dfa50a56 <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.039 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.322 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=True sym=0.6 mass=0.0 body=0.0 min_file_body=0.0
