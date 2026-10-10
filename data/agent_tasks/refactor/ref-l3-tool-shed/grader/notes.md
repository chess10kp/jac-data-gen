# ref-l3-tool-shed
Smell: obj with four parallel dicts (labels/condition/borrower/due), string condition, manual held-count and two-level sort loops.
Target: ToolShed node facade owning Tool/Member nodes (transient subgraph), Lent edge (Member --> Tool) with due_day, Condition enum, OverdueScan walker spawned from the shed reading incoming edge objects.
Idiom targets: >=2 nodes, >=1 edge, >=1 walker, >=1 spawn, >=1 enum, 0 dict fields, >=2 edge filters.
Quirks: loan return uses the untyped disconnect `m del --> t;` (only Lent edges run member -> tool); `del [edge m ->:Lent:-> t]` SIGABRTed under native jac test (0.37.25). jac.toml pins default_codespace = "server": under 0.36.1 native-inferred modules crash jac test once a demoted method is called.
