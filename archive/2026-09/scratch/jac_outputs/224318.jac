"""Fix up a slc object to be tuple of slices."""
def _fix_slice(slc: list[slice | int | tuple | None] | tuple[slice | int | tuple | None, ...] | None) -> tuple[slice, ...] | None {
    if slc is None {
        return None;
    }
    fixed_slc: list[slice] = [];
    for item in slc {
        if isinstance(item, slice) {
            fixed_slc.append(item);
        } elif item is None or isinstance(item, int) {
            fixed_slc.append(slice(item));
        } else {
            fixed_slc.append(slice(*item));
        }
    }
    return tuple(fixed_slc);
}