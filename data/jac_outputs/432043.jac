"""Normalize sources loudness."""
def loudness_normalize(sources_list: list[float], gain_list: list[float]) -> list[float] {
    return [source * gain_list[i] for (i, source) in enumerate(sources_list)];
}