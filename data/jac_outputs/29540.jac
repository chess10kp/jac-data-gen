"""Select all possible files that are related with the given measures."""
def files_data_generation(candidates: list[str], namesmeasures: list[str]) -> list[list[str]] {
    selected = [];
    for name in namesmeasures {
        sele_name = [c for c in candidates if name in c];
        selected.append(sele_name);
    }
    return selected;
}