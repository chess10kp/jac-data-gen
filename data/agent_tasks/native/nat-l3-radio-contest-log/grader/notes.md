# nat-l3-radio-contest-log
Enum-valued node lookup (band == self.band), dupe scoped to band, case folding, zone multipliers across bands. Cross-process run gate.
Alternative: visit-else BandLog, multi-hop chain [-->[?:BandLog] ->:Logged:->[?:Qso]] for Score, dict comprehension summary.
- Quirk: `[root -->[?:BandLog, band == self.band]]` (enum value in a graph-query predicate) passes jac check but raises TypeError 'QPred value for band must be a scalar, got Band' at run time in 0.37.25; reference filters in a comprehension instead.
- jac 0.36.1 port: alt: `visit here ++> BandLog(...)` -> bind then visit (0.36.1 compiler crash).
