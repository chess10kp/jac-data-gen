# cvt-l1-posixpath
Source: CPython v3.12.7 posixpath.py/genericpath.py (PSF-2.0), trimmed to the lexical str subset.
Hidden tests: str cases of the upstream posixpath tests incl. all 48 NORMPATH_CASES, splitext x6
prefix/suffix variants, commonpath incl. ValueErrors, genericpath commonprefix.
Fidelity: os/os.path/posixpath/genericpath/pathlib imports forbidden (would be a shim).
Negatives: root-preserving head trim dropped, normpath '..' chain clause dropped, splitext leading-dot
loop dropped, splitroot '///' special case dropped, commonpath mix check dropped, join absolute reset.
