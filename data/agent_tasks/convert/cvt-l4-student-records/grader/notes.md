# cvt-l4-student-records
Source Dream0916/fastapi_mongo (MIT) @e6038f1 — the widely-forked fastapi-mongo template.
FARM L4: Beanie Student -> node; database.py CRUD -> 5 walkers. Hidden tests are delta/uuid-tagged
(the graph store persists across tests). Negatives: hollow create (node not attached), no-op gpa
update, no-op delete, over-broad delete, partial update clobbering an unsupplied field.
