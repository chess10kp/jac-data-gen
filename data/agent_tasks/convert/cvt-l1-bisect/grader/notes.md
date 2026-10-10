# cvt-l1-bisect
Source: CPython v3.12.7 Lib/bisect.py (PSF-2.0), starter keeps the original file + upstream tests.
Hidden tests port test_bisect.py (precomputed table x both functions, slicing invariants, negative lo,
seeded random invariants, keyword args, key functions abs/str.casefold, insort with key + left/right
placement among equal keys, insort vs sorted(), grades/colors doc examples).
Fidelity: the 4 functions defined in-workspace; importing bisect/_bisect forbidden.
Quirk: with a `key(...)` call through a value the module is placed native then demoted -> SIGSEGV
under `jac test` (rc 139, no output). starter jac.toml pins `[placement] default = "server"`.
Negatives: right uses <=, no negative-lo check, insort_left via bisect_right, insort_right ignores key on x.
