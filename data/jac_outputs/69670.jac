"""Returns a list of contributions that were staff picked."""
def staff_pick_statistics(contributions: list[dict[str, bool]]) -> dict[str, list[dict[str, bool]]] {
    staff_picks = [contribution for contribution in contributions if contribution["staff_picked"]];
    return {"staff_picks": staff_picks};
}