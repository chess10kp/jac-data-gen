"""Filters a list of worlds to a list only containing f2p worlds."""
def f2p_worlds(worlds: list[dict[str, bool]]) -> list[dict[str, bool]] {
    return [world for world in worlds if world['f2p'] and not world['vip']];
}