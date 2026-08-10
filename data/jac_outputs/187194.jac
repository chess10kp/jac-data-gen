"""Determine lane count from additive field tuples, optionally filtered by side."""
def get_additive_lane_count(
    non_zero_width_fields: list[tuple[str, int | float]],
    side_filter: str | None = None
) -> int {
    through_lane_check = "Through_Lane";
    if side_filter == "right" {
        through_lane_check = "Right_" + through_lane_check;
    } elif side_filter is not None {
        through_lane_check = "Left_" + through_lane_check;
    }
    return len([
        slice_tuple
        for slice_tuple in non_zero_width_fields
        if through_lane_check in slice_tuple[0] and slice_tuple[1] > 0
    ]);
}