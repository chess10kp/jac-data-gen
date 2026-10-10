"""Seed bank: each accession is a SeedLot node on root."""

node SeedLot {
    has accession: str;
    has species: str;
    has banked_year: int;
    has germination: int = 100;   # percent, from the last test
    has seeds_left: int = 1000;
    has retired: bool = False;
}

def bank_lot(accession: str, species: str, banked_year: int, germination: int, seeds_left: int) -> SeedLot {
    return root ++> SeedLot(
        accession=accession, species=species, banked_year=banked_year,
        germination=germination, seeds_left=seeds_left
    );
}
