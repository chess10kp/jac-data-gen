"""Return unique items in a sequence seq preserving the original order."""
def ordered_unique[T](seq: list[T]) -> list[T] {
    if not seq {
        return [];
    }
    uniques: list[T] = [];
    for item in seq {
        if item in uniques {
            continue;
        }
        uniques.append(item);
    }
    return uniques;
}