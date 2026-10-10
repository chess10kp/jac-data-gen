"""Semantic version parsing, ordering and bumping."""

obj Version {
    has major: int;
    has minor: int;
    has patch: int;
    has pre: str = "";
}

def parse_version(s: str) -> Version {
    text = s.strip();
    if text.startswith("v") {
        text = text[1:];
    }
    pre = "";
    if "-" in text {
        idx = text.index("-");
        pre = text[idx + 1:];
        text = text[:idx];
        if pre == "" or "" in pre.split(".") {
            raise ValueError(f"bad pre-release in {s}");
        }
    }
    parts = text.split(".");
    if len(parts) != 3 {
        raise ValueError(f"not a version: {s}");
    }
    for p in parts {
        if not p.isdigit() {
            raise ValueError(f"not a version: {s}");
        }
    }
    return Version(major=int(parts[0]), minor=int(parts[1]), patch=int(parts[2]), pre=pre);
}

def cmp_int(a: int, b: int) -> int {
    return (a > b) - (a < b);
}

def cmp_pre(a: str, b: str) -> int {
    if a == b {
        return 0;
    }
    if a == "" {
        return 1;
    }
    if b == "" {
        return -1;
    }
    xs = a.split(".");
    ys = b.split(".");
    for i in range(min(len(xs), len(ys))) {
        x = xs[i];
        y = ys[i];
        if x == y {
            continue;
        }
        if x.isdigit() and y.isdigit() {
            return cmp_int(int(x), int(y));
        }
        if x.isdigit() {
            return -1;
        }
        if y.isdigit() {
            return 1;
        }
        return -1 if x < y else 1;
    }
    return cmp_int(len(xs), len(ys));
}

def compare(a: str, b: str) -> int {
    va = parse_version(a);
    vb = parse_version(b);
    for (x, y) in [(va.major, vb.major), (va.minor, vb.minor), (va.patch, vb.patch)] {
        c = cmp_int(x, y);
        if c != 0 {
            return c;
        }
    }
    return cmp_pre(va.pre, vb.pre);
}

def bump(v: str, part: str) -> str {
    x = parse_version(v);
    if part == "major" {
        return f"{x.major + 1}.0.0";
    }
    if part == "minor" {
        return f"{x.major}.{x.minor + 1}.0";
    }
    if part == "patch" {
        if x.pre != "" {
            return f"{x.major}.{x.minor}.{x.patch}";
        }
        return f"{x.major}.{x.minor}.{x.patch + 1}";
    }
    raise ValueError(f"unknown part {part}");
}

def max_satisfying(versions: list[str], caret_range: str) -> str | None {
    floor = caret_range.strip().lstrip("^");
    base = parse_version(floor);
    best: str | None = None;
    for v in versions {
        pv = parse_version(v);
        if pv.pre != "" or pv.major != base.major or compare(v, floor) < 0 {
            continue;
        }
        if best is None {
            best = v;
        } elif compare(v, str(best)) > 0 {
            best = v;
        }
    }
    return best;
}
