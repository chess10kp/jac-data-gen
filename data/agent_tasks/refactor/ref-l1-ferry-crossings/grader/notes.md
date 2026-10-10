# ref-l1-ferry-crossings
Smell: untyped Port->Port edges plus a parallel `Timetable` node holding dict[str,int] keyed "src->dst".
Target: `edge Crossing: Port --> Port { has minutes: int; }`, typed connect, `[edge a ->:Crossing:-> b]` lookup,
edge predicate `[a ->:Crossing:minutes <= limit:->]`.
Idiom targets: >=1 edge archetype, 0 dict-typed fields.
Verified locally: `[edge a ->:Crossing:-> b]` works here (module touches root -> Python path).
Negatives: duplicate crossing; exclusive limit; retime no-op; missing returns 0.
