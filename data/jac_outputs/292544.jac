"""Pick one item from each of categories."""
def pick_equipment(categories: list[list[str]], cur_pick: str) -> list[str] {
    if not categories {
        return [cur_pick];
    }
    items = categories[0];
    picks: list[str] = [];
    for item in items {
        next_picks = pick_equipment(categories[1:], cur_pick + item);
        picks.extend(next_picks);
    }
    return picks;
}