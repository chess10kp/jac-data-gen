"""Does this target_rel appear in the rel_str?"""
def relMatches(rel_attr: str, target_rel: str) -> int {
    rels = rel_attr.strip().split();
    for rel in rels {
        rel = rel.lower();
        if rel == target_rel {
            return 1;
        }
    }
    return 0;
}