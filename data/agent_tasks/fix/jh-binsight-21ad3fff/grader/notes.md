# jh-binsight-21ad3fff

Source: jachacks_2026. Level 5.

Starter at jac 0.36.1: 36 errors in 2 file(s); codes {'E1032': 19, 'E0048': 6, 'E2018': 6, 'E2004': 3, 'E1053': 1, 'E1001': 1}.

Sample diagnostics:
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:33 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:52 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:79 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:100 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:140 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E0048 binsight/jac_app/extensions/walkers/alert_walkers.jac:164 Parenthesized filter syntax '(?:...)' was removed. Use bracket syntax '[?:...]' instead.`
- `E2004 binsight/jac_app/extensions/walkers/alert_walkers.jac:9 Non default attribute 'created_at' follows default attribute`
- `E1032 binsight/jac_app/extensions/walkers/alert_walkers.jac:37 Type is Unknown, cannot access attribute "acknowledged"`

Reference = grader/reference (green at jac 0.36.1). Grade with:
`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/jh-binsight-21ad3fff <workspace>`

Calibration at build time (CI):
- reference: pass=True check=True sym=1.0 mass=1.009 body=1.0 min_file_body=1.0
- starter_profile: pass=True check=None sym=1.0 mass=1.0 body=1.0 min_file_body=1.0
- stub: pass=False check=True sym=1.0 mass=0.696 body=0.0 min_file_body=0.0
- delete_targets: pass=False check=False sym=0.0 mass=0.0 body=0.0 min_file_body=0.0
