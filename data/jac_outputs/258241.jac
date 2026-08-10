"""combine intervalls. Overlapping intervalls
    are concatenated into larger intervalls.
    """
def CombineIntervallsLarge(intervalls: list[tuple[int, int]]) -> list[tuple[int, int]] {
    if not intervalls {
        return [];
    }
    new_intervalls = [];
    intervalls.sort();
    (first_from, last_to) = intervalls[0];
    for (this_from, this_to) in intervalls[1:] {
        if this_from > last_to {
            new_intervalls.append((first_from, last_to));
            (first_from, last_to) = (this_from, this_to);
            continue;
        }
        if last_to < this_to {
            last_to = this_to;
        }
    }
    new_intervalls.append((first_from, last_to));
    return new_intervalls;
}