# ref-l2-pottery-shelves
Smell: one "bucket" node on root holding dict[str, dict] of shelves with nested piece dicts; isinstance scan to find it.
Target: Shelf/Piece nodes, Shelf ++> Piece edges, typed+field edge filters for every query, node deletion on collect.
Idiom targets: >=2 node types, 0 dict-typed fields, 0 isinstance calls, >=3 edge filters, >=2 connects.
