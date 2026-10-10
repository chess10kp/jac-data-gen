callsheet.jac needs a proper Jac rewrite before we build the scheduling UI on top of it.

Today everything sits in one `Production` node that we dig out of root with `isinstance`, holding a crew dict, a dict of scene dicts and a list of assignment dicts. Departments are plain strings with an if-chain for prep time.

What I want:
- Department as an enum.
- Crew, shooting days and scenes as nodes; scenes hang off their day via a typed edge, and crew are linked to scenes with a typed assignment edge that carries the extra early minutes (no more assignment dicts).
- Walkers for the traversals: one that builds a day's call sheet (and can give the day's locations), one that works out which days a crew member is on. Edge filters for lookups.
- Declarations in callsheet.jac, implementations in a callsheet.impl.jac annex: all function bodies and walker ability bodies go there.

Keep `callsheet` as the module and keep `hire`, `add_scene`, `assign`, `call_sheet`, `locations`, `crew_days`, `idle` with identical signatures, return values and line formats. Department names still come in as lowercase strings.
