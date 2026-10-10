# nat-l5-bikeshare-api
walker:pub endpoints tested over HTTP in-process (JacTestClient, registered user root, state persisted across requests) + start gate: reference served by 'jac start' (0.36.1; 'jac run --serve' on 0.37+) and probed over real HTTP (anonymous / guest graph).
km wear tie ('return docks...' test: A-10 at 14.5, B-10 at 10 then 11, B-30 at 30 -> third rent B-10).
Alternative: walkers visit the station node (filter in visit) and report from Station entry; missing station detected in Root exit.
- jac 0.36.1 port: typed-edge del loops (E5043); alt tracks best_km/best_serial (0.36.1 does not narrow Optional inside an `or` chain).
- All L5 tests: JacTestClient lives at jaclang.runtimelib.testing in 0.36.1 (jaclang.testing.testing in 0.37); responses read through an envelope-agnostic payload() helper.
