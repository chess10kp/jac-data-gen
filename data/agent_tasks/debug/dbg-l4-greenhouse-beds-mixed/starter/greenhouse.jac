"""Greenhouse watering schedule. Beds hang off root; each Bed Grows Plants."""

node Bed {
    has code: str;
}

node Plant {
    has species: str;
    has interval_days: int;
    has last_watered: int;
}

edge Grows: Bed --> Plant {}

walker PlantIn {
    has bed: str;
    has species: str;
    has interval_days: int;
    has day: int;

    can plant with Root entry {
        beds = [root -->[?:Bed, code == self.species]];
        b = beds[0] if beds else root ++> Bed(code=self.bed);
        b +>:Grows():+> Plant(species=self.species, interval_days=self.interval_days, last_watered=self.day);
        report len([b ->:Grows:->]);
    }
}

walker WaterBed {
    has bed: str;
    has day: int;
    has watered: int = 0;

    can find with Root entry {
        visit [-->[?:Bed, code == self.bed]];
    }

    can open_bed with Bed entry {
        visit [here ->:Grows:->];
    }

    can water with Plant entry {
        here.last_watered = self.day;
        self.watered += 1;
    }

    can finish with Root exit {
        report self.watered;
    }
}

walker DueOn {
    has day: int;
    has due: list[str] = [];

    can start with Root entry {
        visit [-->[?:Bed]];
    }

    can scan with Bed entry {
        for p in [here ->:Grows:->] {
            if self.day - p.last_watered >= p.interval_days {
                self.due.append(f"{here.code}/{p.species}");
            }
        }
    }

    can finish with Root exit {
        report sorted(self.due);
    }
}

walker Uproot {
    has bed: str;
    has species: str;

    can pull with Root entry {
        removed = 0;
        for b in [root -->[?:Bed]] {
            for p in [b ->:Grows:->[?:Plant, species == self.species]] {
                del p;
                removed += 1;
            }
        }
        report removed;
    }
}
