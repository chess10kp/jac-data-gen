"""Delete duplicates in a playlist."""
def deletedup(xs: list[object]) -> list[object] {
    result = [];
    for x in xs {
        if x not in result {
            result.append(x);
        }
    }
    return result;
}