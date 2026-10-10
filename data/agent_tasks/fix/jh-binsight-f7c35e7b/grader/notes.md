# jh-binsight-f7c35e7b

Source: jachacks_2026. Level 4.

Starter at jac 0.37.25: 20 errors in 2 file(s); codes {'E0048': 8, 'E2018': 3, 'E2004': 2, 'E1036': 2, 'E0022': 1, 'E0002': 1, 'E0006': 1, 'E1054': 1, 'E2086': 1}.

Sample diagnostics:
- `E2004 binsight/jac_app/extensions/domain/nodes.jac:87 Non default attribute 'action' follows default attribute`
- `E2004 binsight/jac_app/extensions/domain/nodes.jac:134 Non default attribute 'subject' follows default attribute`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:35 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:61 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:65 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:89 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:128 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/schedule_walkers.jac:148 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`

Reference = grader/reference (green at 0.37.25). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-binsight-f7c35e7b <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.021 body=1.018 min_file_body=1.018
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.691 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
