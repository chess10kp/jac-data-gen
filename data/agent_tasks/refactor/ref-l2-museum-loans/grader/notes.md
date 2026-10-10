# ref-l2-museum-loans
Smell: one "bucket" Register node on root holding dict[str, dict] of museums -> works -> list of loan dicts; isinstance scan to find it; on_display/lenders_to scan every museum's nested dicts.
Target: Museum/Artwork nodes on root, Owns edge (Museum -> Artwork), LoanedTo typed edge (Artwork -> Museum) carrying start_year/end_year; overlap and "on display in year" via edge predicates; incoming LoanedTo for borrowed works and lenders.
Idiom targets: >=2 node types, >=1 edge type, 0 dict-typed fields, 0 isinstance calls, >=3 edge filters, >=2 connects.
Quirks: edge predicate RHS reads ordinary scope, so years are bound to locals (s/e/y) first. Years are inclusive on both ends.
