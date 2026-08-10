"""Count the number of individuals of each species"""
def get_species_counts(data: list[tuple[str, str, str]]) -> dict[str, int] {
    species_counts: dict[str, int] = {};
    for record in data {
        species = record[1];
        count = int(record[2]);
        species_counts[species] = species_counts.get(species, 0) + count;
    }
    return species_counts;
}