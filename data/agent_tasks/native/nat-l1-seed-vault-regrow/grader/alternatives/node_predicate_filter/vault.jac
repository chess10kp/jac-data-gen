"""Seed bank: each accession is a SeedLot node on root."""

node SeedLot {
    has accession: str;
    has species: str;
    has banked_year: int;
    has germination: int = 100;   # percent, from the last test
    has seeds_left: int = 1000;
    has retired: bool = False;

    def due_for_test(year: int) -> bool {
        return year - self.banked_year >= 10 or self.germination < 75 or self.seeds_left < 200;
    }
}

def bank_lot(accession: str, species: str, banked_year: int, germination: int, seeds_left: int) -> SeedLot {
    return root ++> SeedLot(
        accession=accession, species=species, banked_year=banked_year,
        germination=germination, seeds_left=seeds_left
    );
}

walker RegrowPlan {
    has year: int;
    has examined: int = 0;
    has picked: list[SeedLot] = [];

    can start with Root entry {
        visit [-->[?:SeedLot, retired == False]];
    }

    can assess with SeedLot entry {
        self.examined += 1;
        if here.due_for_test(self.year) {
            self.picked.append(here);
        }
    }

    can finish with Root exit {
        out: dict[str, list[str]] = {};
        for lot in sorted(self.picked, key=lambda (l: SeedLot) { l.accession; }) {
            if lot.species not in out {
                out[lot.species] = [];
            }
            out[lot.species].append(lot.accession);
        }
        report out;
    }
}
