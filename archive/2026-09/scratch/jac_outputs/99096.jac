"""Chop the list of ttvalues at now."""
def chop_at_now(ttlist: list[object]) -> list[object] {
    ttlist = list(ttlist);
    if not ttlist {
        return [];
    }
    first = ttlist[0];
    now = first.__class__();
    return [ttval for ttval in ttlist if ttval <= now];
}