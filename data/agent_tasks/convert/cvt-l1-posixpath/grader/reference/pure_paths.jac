"""Lexical POSIX path operations: no filesystem access, strings in, strings out.

Ported from a trimmed copy of CPython's posixpath/genericpath.
"""

glob SEP: str = "/",
     CURDIR: str = ".",
     PARDIR: str = "..",
     EXTSEP: str = ".";

"""True when `s` starts with a slash."""
def isabs(s: str) -> bool {
    return s.startswith(SEP);
}

"""Join components with '/'; an absolute component discards everything before it."""
def join(a: str, *p: str) -> str {
    path = a;
    for b in p {
        if b.startswith(SEP) {
            path = b;
        } elif not path or path.endswith(SEP) {
            path += b;
        } else {
            path += SEP + b;
        }
    }
    return path;
}

"""Strip trailing slashes from a head unless it is all slashes (the root)."""
def _trim_head(head: str) -> str {
    if head and head != SEP * len(head) {
        return head.rstrip(SEP);
    }
    return head;
}

"""(head, tail) where tail is everything after the final slash."""
def split(p: str) -> tuple[str, str] {
    i = p.rfind(SEP) + 1;
    return (_trim_head(p[:i]), p[i:]);
}

"""(root, ext): ext runs from the last dot of the last component; leading dots don't count."""
def splitext(p: str) -> tuple[str, str] {
    sep_index = p.rfind(SEP);
    dot_index = p.rfind(EXTSEP);
    if dot_index > sep_index {
        filename_index = sep_index + 1;
        while filename_index < dot_index {
            if p[filename_index] != EXTSEP {
                return (p[:dot_index], p[dot_index:]);
            }
            filename_index += 1;
        }
    }
    return (p, "");
}

"""(drive, root, tail); drive is always empty on POSIX and exactly two leading
slashes are kept as a distinct root."""
def splitroot(p: str) -> tuple[str, str, str] {
    if p[:1] != SEP {
        return ("", "", p);
    }
    if p[1:2] != SEP or p[2:3] == SEP {
        return ("", SEP, p[1:]);
    }
    return ("", p[:2], p[2:]);
}

def basename(p: str) -> str {
    return p[p.rfind(SEP) + 1:];
}

def dirname(p: str) -> str {
    return _trim_head(p[:p.rfind(SEP) + 1]);
}

"""Collapse redundant separators and '.'/'..' components lexically."""
def normpath(path: str) -> str {
    if path == "" {
        return CURDIR;
    }
    (_, initial_slashes, rest) = splitroot(path);
    comps: list[str] = [];
    for comp in rest.split(SEP) {
        if comp == "" or comp == CURDIR {
            continue;
        }
        if comp != PARDIR
            or (not initial_slashes and not comps)
            or (comps and comps[-1] == PARDIR) {
            comps.append(comp);
        } elif comps {
            comps.pop();
        }
    }
    return (initial_slashes + SEP.join(comps)) or CURDIR;
}

"""Longest common leading string (character-wise) of the given paths."""
def commonprefix(m: list[str]) -> str {
    if not m {
        return "";
    }
    s1 = min(m);
    s2 = max(m);
    for (i, c) in enumerate(s1) {
        if c != s2[i] {
            return s1[:i];
        }
    }
    return s1;
}

"""Longest common sub-path (component-wise); absolute and relative paths can't mix."""
def commonpath(paths: list[str]) -> str {
    if not paths {
        raise ValueError("commonpath() arg is an empty sequence");
    }
    kinds = {p[:1] == SEP for p in paths};
    if len(kinds) != 1 {
        raise ValueError("Can't mix absolute and relative paths");
    }
    absolute = paths[0][:1] == SEP;
    parts = [[c for c in p.split(SEP) if c and c != CURDIR] for p in paths];
    s1 = min(parts);
    s2 = max(parts);
    common = s1;
    for (i, c) in enumerate(s1) {
        if c != s2[i] {
            common = s1[:i];
            break;
        }
    }
    return (SEP if absolute else "") + SEP.join(common);
}
