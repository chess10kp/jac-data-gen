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

walker RegrowPlan {
    has year: int;
    has examined: int = 0;
    has plan: dict[str, list[str]] = {};

    can start with Root entry {
        visit [-->[?:SeedLot]];
    }

    can assess with SeedLot entry {
        if here.retired {
            return;
        }
        self.examined += 1;
        too_old = self.year - here.banked_year > 10;
        weak = here.germination < 75;
        low_stock = here.seeds_left < 200;
        if too_old or weak or low_stock {
            self.plan.setdefault(here.species, []).append(here.accession);
        }
    }

    can finish with Root exit {
        report {sp: sorted(codes) for (sp, codes) in self.plan.items()};
    }
}
