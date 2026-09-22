"""
Returns the next stage start timestamp from a list/set of stage
boundaries and current time.
"""
def lookup_next_stage_start(stage_boundaries: list[int | float] | set[int | float], t: int | float) -> int | float | None {
    next_boundaries = [x for x in stage_boundaries if x > t];
    if not next_boundaries {
        return None;
    }
    return min(next_boundaries);
}