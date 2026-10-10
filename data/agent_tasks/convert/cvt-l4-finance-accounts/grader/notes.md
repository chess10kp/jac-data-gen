# cvt-l4-finance-accounts
Source Vitoria-Rabelo/fastapi-beanie-finance (MIT) @28ef2f1. FARM L4 with relations: Link[User]
back-references become typed edges from the owning User. Quirk exercised: `skip` is a Jac keyword
(field needs `` `skip ``). Hidden tests: uuid-tagged users; paging asserted relative to the full
listing (the store persists). Negatives: duplicate email allowed, unhashed password, user filter
ignored, skip ignored, no-op account delete.
