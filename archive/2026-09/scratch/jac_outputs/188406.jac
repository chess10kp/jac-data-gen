"""Find a profile for a given chromosome that spans a given range of bp positions."""
def find_profile(profiles: dict[str, list[list[int]]], chrom: str, start_bp: int, end_bp: int) -> list[int] | None {
    if chrom in profiles {
        for el in profiles[chrom] {
            if el[0] == start_bp and el[1] == end_bp {
                return [el[2], el[3]];
            }
        }
    }
    return None;
}