"""Inserts an empty relationship at index 4."""
def insert_relationships(datapoints: list[tuple[str, ...]]) -> set[tuple[str, ...]] {
    new_datapoints = set();
    for dp in datapoints {
        cast_dp = list(dp);
        cast_dp.insert(4, "");
        new_datapoints.add(tuple(cast_dp));
    }
    return new_datapoints;
}