"""Unix shell-style wildcard matching (`*`, `?`, `[seq]`, `[!seq]`) on POSIX.

Patterns are translated to regular expressions once and cached. Ported from
CPython's fnmatch; on POSIX case normalization is a no-op, so `fnmatch` and
`fnmatchcase` agree.
"""
import re;

glob _cache: dict[str, re.Pattern[str]] = {};

"""Compiled regex for a shell pattern (memoized)."""
def _compile_pattern(pat: str) -> re.Pattern[str] {
    if pat not in _cache {
        _cache[pat] = re.compile(translate(pat));
    }
    return _cache[pat];
}

"""True when `name` matches the shell pattern `pat` (POSIX: case-sensitive)."""
def fnmatch(name: str, pat: str) -> bool {
    return fnmatchcase(name, pat);
}

"""True when `name` matches `pat`, never normalizing case."""
def fnmatchcase(name: str, pat: str) -> bool {
    return _compile_pattern(pat).match(name) is not None;
}

"""The elements of `names` that match `pat`, in their original order."""
def filter(names: list[str], pat: str) -> list[str] {
    matcher = _compile_pattern(pat);
    return [name for name in names if matcher.match(name)];
}

"""Regex source for a bracket set body pat[i:j] (i just past '['), or a fixed token."""
def _bracket(pat: str, i: int, j: int) -> str {
    stuff = pat[i:j];
    if "-" not in stuff {
        stuff = stuff.replace("\\", "\\\\");
    } else {
        chunks: list[str] = [];
        k = i + 2 if pat[i] == "!" else i + 1;
        while True {
            k = pat.find("-", k, j);
            if k < 0 {
                break;
            }
            chunks.append(pat[i:k]);
            i = k + 1;
            k = k + 3;
        }
        chunk = pat[i:j];
        if chunk {
            chunks.append(chunk);
        } else {
            chunks[-1] += "-";
        }
        # Remove empty ranges -- invalid in a regex.
        for k2 in range(len(chunks) - 1, 0, -1) {
            if chunks[k2 - 1][-1] > chunks[k2][0] {
                chunks[k2 - 1] = chunks[k2 - 1][:-1] + chunks[k2][1:];
                chunks.pop(k2);
            }
        }
        # Escape backslashes and hyphens for set difference (--);
        # hyphens that create ranges stay unescaped.
        stuff = "-".join([s.replace("\\", "\\\\").replace("-", "\\-") for s in chunks]);
    }
    # Escape set operations (&&, ~~ and ||).
    stuff = re.sub(r"([&~|])", r"\\\1", stuff);
    if not stuff {
        return "(?!)";       # empty range: never match
    }
    if stuff == "!" {
        return ".";          # negated empty range: any character
    }
    if stuff[0] == "!" {
        stuff = "^" + stuff[1:];
    } elif stuff[0] in ("^", "[") {
        stuff = "\\" + stuff;
    }
    return f"[{stuff}]";
}

"""Translate a shell pattern into a regular expression string (not compiled).
There is no way to quote meta-characters."""
def translate(pat: str) -> str {
    # Tokens; None stands for a (compressed) run of `*`.
    toks: list[str | None] = [];
    i = 0;
    n = len(pat);
    while i < n {
        c = pat[i];
        i += 1;
        if c == "*" {
            if not toks or toks[-1] is not None {
                toks.append(None);
            }
        } elif c == "?" {
            toks.append(".");
        } elif c == "[" {
            j = i;
            if j < n and pat[j] == "!" {
                j += 1;
            }
            if j < n and pat[j] == "]" {
                j += 1;
            }
            while j < n and pat[j] != "]" {
                j += 1;
            }
            if j >= n {
                toks.append("\\[");
            } else {
                toks.append(_bracket(pat, i, j));
                i = j + 1;
            }
        } else {
            toks.append(re.escape(c));
        }
    }
    # Fixed prefix, then `STAR fixed` pairs: interior pairs become atomic
    # minimal matches so the regex never backtracks into them.
    out: list[str] = [];
    k = 0;
    m = len(toks);
    while k < m and toks[k] is not None {
        out.append(toks[k]);
        k += 1;
    }
    while k < m {
        k += 1;                       # skip the STAR
        if k == m {
            out.append(".*");
            break;
        }
        fixed: list[str] = [];
        while k < m and toks[k] is not None {
            fixed.append(toks[k]);
            k += 1;
        }
        piece = "".join(fixed);
        if k == m {
            out.append(".*" + piece);
        } else {
            out.append(f"(?>.*?{piece})");
        }
    }
    return "(?s:" + "".join(out) + ")\\Z";
}
