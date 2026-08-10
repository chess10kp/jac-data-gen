"""Number contiguous elements in an array with the information of the missing indices."""
def split_and_number(strips: list[object], missing_indices: list[int]) -> list[tuple[int, object]] {
    remapped_strips: list[tuple[int, object]] = [];
    j = 0;
    missing_indices.sort();
    for strip in strips {
        if j in missing_indices {
            while j in missing_indices {
                j += 1;
            }
        }
        remapped_strips.append((j, strip));
        j += 1;
    }
    return remapped_strips;
}