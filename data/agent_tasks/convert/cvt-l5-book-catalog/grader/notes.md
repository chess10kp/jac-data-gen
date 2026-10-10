# cvt-l5-book-catalog
Source documentdb/documentdb-playground (MIT) @1a36d28, playgrounds/beanie/app. FARM L5: Beanie Book ->
node; 7 handlers (incl. the $unwind/$group/$sort genre aggregation) -> walker:pub. No upstream tests for
this API; tests.jac + smoke.py written from route semantics (uuid-tagged authors/genres, delta asserts).
Negatives: unattached create, no-op patch of rating, delete-by-author (over-broad), ignored author
filter, oldest-first order, genre counted once.
