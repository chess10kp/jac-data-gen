"""Construct tuple of slices to slice an array in the given dimension."""
def _slice_at_axis(sl: slice, axis: int) -> tuple {
    return (slice(None),) * axis + (sl,) + (...,);
}