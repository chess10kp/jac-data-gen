def _normalize(tag: str) -> str {
    return tag.strip().lower();
}

def _dedupe(tags: list) -> list {
    seen = [];
    for t in tags {
        if t not in seen {
            seen.append(t);
        }
    }
    return seen;
}

def clean_tags(raw: list) -> str {
    cleaned = [_normalize(t) for t in raw];
    kept = [t for t in cleaned if t != ""];
    return ",".join(_dedupe(kept));
}

with entry {
    print(clean_tags([' Py', 'py', '', 'ML ']));
}
