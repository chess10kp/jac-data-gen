"""Convert a slice object to the corresponding index list"""
def slice_to_range(slicer: slice[int | None, int | None, int | None], r_max: int) -> range {
    step = slicer.step if slicer.step is not None else 1;
    if slicer.start is None {
        start = r_max - 1 if step < 0 else 0;
    } else {
        start = slicer.start;
    }
    if slicer.stop is None {
        stop = -1 if step < 0 else r_max;
    } else {
        stop = slicer.stop;
    }
    return range(start, stop, step);
}