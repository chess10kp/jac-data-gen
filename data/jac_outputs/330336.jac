"""Remove the duplicates."""
def no_dups(recommend: list[object]) -> list[object] {
    new = [];
    for x in recommend {
        if x not in new {
            new.append(x);
        }
    }
    return new;
}