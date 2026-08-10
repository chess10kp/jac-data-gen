"""Finds all simulations in the list given."""
def find_all_simulations(flist: list[str], sim: str) -> list[str] | None {
    if not flist {
        return None;
    }
    matches = [];
    for fs in flist {
        if fs.startswith(sim) {
            matches.append(fs);
        }
    }
    return matches;
}