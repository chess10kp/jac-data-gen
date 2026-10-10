# ref-l3-tool-shed
Smell: obj with four parallel dicts (labels/condition/borrower/due), string condition, manual held-count and two-level sort loops.
Target: ToolShed node facade owning Tool/Member nodes (transient subgraph), Lent edge (Member --> Tool) with due_day, Condition enum, OverdueScan walker spawned from the shed reading incoming edge objects.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 spawn, >=1 enum, 0 dict fields, >=2 edge filters.
Quirks: `del [edge m ->:Lent:-> t]` SIGABRTs under native `jac test` in 0.37.25; the reference uses the untyped disconnect `m del --> t;` (only Lent edges run member -> tool). A first starter with dict[str, any] records + lambda sort also crashed natively; the starter uses concretely typed parallel dicts.
Local: starter + reference jac check ok; reference jac test 5/5; starter 4/5 before a test-expectation fix (expectation corrected, verified by jac run).
