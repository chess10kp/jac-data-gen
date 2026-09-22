"""Rename and filter package list with subsitutions; for similar systems.
    """
def _filter_subs_packages(initial: Any, subs: Any) -> object {
    final = [];
    for p in initial {
        try {
            new_p = subs[p];
        } except KeyError {
            new_p = p;
        }
        if new_p {
            final.append(new_p);
        }
    }
    return sorted(final);
}