""" resolve multiple levels of generators """
def _resolve_nested(level_count: int, source: object) -> list[object] {
    assert level_count > 0;
    if level_count > 1 {
        return [_resolve_nested(level_count - 1, item) for item in source];
    } else {
        return list(source);
    }
}