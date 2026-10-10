# cvt-l2-normal-dist
Source: CPython v3.12.7 statistics.NormalDist (PSF-2.0), trimmed to the class + helpers (see task.json).
Hidden tests: TestNormalDist ported (tables for pdf/cdf/inv_cdf, overlap vs numeric integration,
operators, equality incl. NotImplemented, hashing, repr). Quirks: `pub` is a Jac keyword (test var renamed);
`__eq__` returning NotImplemented needs `-> bool | NotImplementedType`; passing None/any into typed
params needs an `any`-typed variable in tests (E1053 otherwise); obj properties use `has x: T { getter ... }`.
Negatives: dropped sign flip in inv_cdf tails, unnegated __rsub__, linear sigma addition, identity hash,
wrong pdf normalisation, variance == sigma.
