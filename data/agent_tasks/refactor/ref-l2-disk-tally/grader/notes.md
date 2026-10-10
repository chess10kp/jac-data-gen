# ref-l2-disk-tally
Smell: graph already exists (Folder/File nodes, parent ++> child) but every query is a hand-written recursive helper (`_total`, `_count`, `_collect`) over `[d -->]` with isinstance dispatch; lookup is an isinstance scan over `[root -->]`.
Target: one walker (Tally) spawned on the folder, tallying files via `[here -->[?:File]]` and descending with `visit [here -->[?:Folder]]`; facade functions read the walker's fields; lookups use typed/field edge filters.
Idiom targets: >=1 walker, >=1 visit, >=1 spawn, 0 isinstance calls, >=2 edge filters.
All folders also hang off root (registry for path lookup); the walker only follows folder -> subfolder edges, so root links never enter the traversal.
