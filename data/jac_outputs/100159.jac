def dictmerge(*dicts: dict[str, object]) -> dict[str, object] {
    result = {};
    for d in dicts {
        result.update(d);
    }
    return result;
}