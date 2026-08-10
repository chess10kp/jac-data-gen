"""Equality test for list of series."""
def lists_of_series_are_equal(list_of_series_1: list[object], list_of_series_2: list[object]) -> bool {
    return all([
        getattr(s1 == s2, "all")()
        for (s1, s2) in zip(list_of_series_1, list_of_series_2)
    ]);
}