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

# Mutant: keeps the schedule in a module-level dict instead of the graph.
glob BEDS: dict[str, list[list]] = {};

walker PlantIn {
    has bed: str;
    has species: str;
    has interval_days: int;
    has day: int;

    can plant with Root entry {
        BEDS.setdefault(self.bed, []).append([self.species, self.interval_days, self.day]);
        report len(BEDS[self.bed]);
    }
}

walker WaterBed {
    has bed: str;
    has day: int;

    can go with Root entry {
        rows = BEDS.get(self.bed, []);
        for r in rows {
            r[2] = self.day;
        }
        report len(rows);
    }
}

walker DueOn {
    has day: int;

    can go with Root entry {
        out: list[str] = [];
        for (code, rows) in BEDS.items() {
            for r in rows {
                if self.day - r[2] >= r[1] {
                    out.append(code + "/" + r[0]);
                }
            }
        }
        report sorted(out);
    }
}

walker Uproot {
    has bed: str;
    has species: str;

    can go with Root entry {
        rows = BEDS.get(self.bed, []);
        keep = [r for r in rows if r[0] != self.species];
        n = len(rows) - len(keep);
        if self.bed in BEDS {
            BEDS[self.bed] = keep;
        }
        report n;
    }
}
