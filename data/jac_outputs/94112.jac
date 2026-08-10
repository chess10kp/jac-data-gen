"""Return geotype based on population density."""
def lookup_clutter_geotype(
    clutter_lookup: list[tuple[float, str]],
    population_density: float
) -> str {
    (_, lowest_geotype) = clutter_lookup[0];
    (middle_popd, middle_geotype) = clutter_lookup[1];
    (highest_popd, highest_geotype) = clutter_lookup[2];
    if population_density < middle_popd {
        return lowest_geotype;
    } elif population_density > highest_popd {
        return highest_geotype;
    } else {
        return middle_geotype;
    }
}