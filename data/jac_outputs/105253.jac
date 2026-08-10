"""Returns indexes of channels whose name stems appear only once."""
def pairless_grads(ch_names: list[str]) -> list[int] {
    stems = [name[:-1] for name in ch_names];
    only_once = [stem for stem in stems if stems.count(stem) == 1];
    return [name_idx for (name_idx, name) in enumerate(ch_names) if name[:-1] in only_once];
}