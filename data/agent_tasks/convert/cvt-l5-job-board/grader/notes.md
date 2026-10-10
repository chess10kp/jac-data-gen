# cvt-l5-job-board
Source roshan-rm01/Google-BGN (MIT) @ba223da, backend/ org + job routes (applicant side trimmed).
FARM L5: Organisation/Job -> nodes, embedded OrganisationData -> obj, ownership -> typed edge Posted.
11 handlers -> walker:pub. Hidden tests exercise the faithful union-with-duplicates get_jobs semantics,
password hashing/sign-in, profile obj, edge attachment ([org ->:Posted:->]), update/delete deltas.
Negatives: job not attached via Posted, update drops title, delete-by-location (over-broad),
deduplicated filters, sign-in ignoring password, company name taken from body.
