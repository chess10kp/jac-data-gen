# cvt-l1-fnmatch
Source: CPython v3.12.7 Lib/fnmatch.py (PSF-2.0). Request fixes POSIX semantics (normcase identity).
Hidden tests port the str cases of test_fnmatch.py: basics/newlines, slow pattern, fnmatchcase,
char sets & ranges over ascii+digits+punctuation, separators in sets/ranges, set-op chars,
exact translate() strings incl. atomic groups and the "|"-joined fat regex, filter().
Fidelity: fnmatch/glob/pathlib imports forbidden (`re` allowed).
Negatives: no star squashing, non-atomic interior stars, '!' negation dropped, empty-range pruning
dropped (invalid regex), unclosed '[' unescaped, set-operation escaping dropped.
