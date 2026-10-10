# ref-l2-org-roster
Smell: a "bucket" Roster node on root (isinstance scan) holding parallel dicts boss: dict[str, str] and pay: dict[str, int]; every query scans the boss dict.
Target: Employee nodes on root (registry), a typed Manages edge (Employee -> Employee) for the hierarchy; reports via `[e ->:Manages:->]`, manager via incoming `[e <-:Manages:<-]`; transfer deletes the old typed edge (iterate `[edge old ->:Manages:-> e]` and `del` each; `del [edge ...]` passes jac check but fails bytecode gen E5043 at 0.36.1) and connects the new one; fire reconnects reports to the next manager up and `del`s the node.
Idiom targets: >=1 node type, >=1 edge type, 0 dict-typed fields, 0 isinstance calls, >=3 edge filters, >=2 connects.
No cycle check on transfer (tests never create one).
