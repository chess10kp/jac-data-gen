"""tjmisko/Coldstore#7 — tag catalog subtree list, merge, cascade delete."""

from __future__ import annotations


class TagCatalog:
    def __init__(self) -> None:
        self.parent: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}
        self.tags: set[str] = set()


def load_tags(paths: list[str]) -> TagCatalog:
    c = TagCatalog()
    seen: set[str] = set()
    for path in paths:
        parts = [p for p in path.split("/") if p]
        for i in range(len(parts)):
            name = "/".join(parts[: i + 1])
            if name in seen:
                continue
            seen.add(name)
            c.tags.add(name)
            par = "/".join(parts[:i]) if i > 0 else None
            c.parent[name] = par
            c.children.setdefault(name, [])
            if par is not None:
                c.children.setdefault(par, []).append(name)
    return c


def descendant_tags(c: TagCatalog, name: str) -> list[str]:
    if name not in c.tags:
        return []
    out: list[str] = []
    stack = [name]
    seen: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != name:
            out.append(cur)
        for ch in sorted(c.children.get(cur, [])):
            stack.append(ch)
    return sorted(out)


def delete_tag(c: TagCatalog, name: str, cascade: bool = False) -> list[str]:
    if name not in c.tags:
        return []
    kids = descendant_tags(c, name)
    if kids and not cascade:
        raise ValueError("has_descendants")
    doomed = sorted(set([name] + (kids if cascade else [])))
    for t in doomed:
        c.tags.discard(t)
        c.parent.pop(t, None)
        c.children.pop(t, None)
    for par, chs in list(c.children.items()):
        c.children[par] = [x for x in chs if x in c.tags]
    return doomed


def merge_tags(c: TagCatalog, src: str, dst: str) -> bool:
    if src not in c.tags or dst not in c.tags:
        return False
    for ch in list(c.children.get(src, [])):
        c.parent[ch] = dst
        c.children.setdefault(dst, []).append(ch)
    c.children.pop(src, None)
    c.parent.pop(src, None)
    c.tags.discard(src)
    return True
