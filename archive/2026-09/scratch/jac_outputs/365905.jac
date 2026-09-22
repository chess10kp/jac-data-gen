"""Judge whether a group still has slot."""
def still_has_slot(
    selected_recs: list[tuple[str, int]], slots: dict[int, int], group_id: int
) -> bool {
    max_slot = slots[group_id];
    current_slot = 0;
    for (_, group) in selected_recs {
        if group == group_id {
            current_slot += 1;
        }
    }
    return current_slot < max_slot;
}