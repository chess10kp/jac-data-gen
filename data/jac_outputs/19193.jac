"""Find a family of subsets that covers the universal set"""
def set_cover(universe: set, subsets: list[set]) -> list[set] | None {
    elements = set(e for s in subsets for e in s);
    if elements != universe {
        return None;
    }
    covered = set();
    cover = [];
    while covered != universe {
        subset = max(subsets, key=lambda (s: set) { len(s - covered); });
        cover.append(subset);
        covered |= subset;
    }
    return cover;
}