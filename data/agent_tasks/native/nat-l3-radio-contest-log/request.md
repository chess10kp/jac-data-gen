I'm writing a logbook for a weekend radio contest in Jac (`contest.jac`). The types are drafted: one `BandLog` node per `Band` (created on `root` the first time that band is used), and each contact (QSO) is a `Qso` node linked from its band's log with a `Logged` edge. The logging station spawns one walker per contact, and the log must survive between `jac run` sessions of the project (operators restart the program all the time), so keep it all in the graph.

Walkers to implement (all spawned on `root`):

**`LogQso(call, band, minute, zone)`** — `band` is a `Band` enum value.
- Calls are case-insensitive: store the callsign upper-cased.
- A contact with a station already logged **on the same band** is a dupe: don't store it, report `"dupe"`.
- Otherwise store it and report `"ok"`.

**`Score()`** — report the score once: (number of stored contacts) × (number of distinct `zone` values across all bands). Keep the two factors in `qsos: int` and `mults: int` fields as well. An empty log scores 0.

**`BandSummary()`** — report once a dict from band name (e.g. `"B20M"`) to the number of contacts on that band, including only bands that have a log node.

Leave `Band`, `BandLog`, `Qso` and `Logged` unchanged.
