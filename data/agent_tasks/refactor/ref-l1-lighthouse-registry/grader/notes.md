# ref-l1-lighthouse-registry
Smell: `for n in [root -->] { if isinstance(n, Lamp) and ... }` scans everywhere (6 isinstance calls).
Target: typed edge filters `[root -->[?:Lamp, station == wanted]]`, `[lamp -->[?:Keeper, on_duty == True]]`.
Idiom targets: 0 isinstance calls, >=4 edge filters (starter has 0).
Quirk: param `station` shares the field name -> bind `wanted = station;` first.
Negatives: doused lamps burn; duplicate station; strict threshold; keepers hung on root.
