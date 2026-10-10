Ham radio contest logger in `contest.jac`. Three walkers: `LogQso` (log a contact, reject dupes), `Score` (QSOs × distinct zones) and `BandSummary` (contacts per band).

No tests exist yet. Write `contest_tests.jac` please — must pass as-is, and should catch it if anyone breaks dupe detection (which is per band and case-insensitive), the scoring formula, or the per-band counts. Don't change contest.jac.
