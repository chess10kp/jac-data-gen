"""Greenhouse watering schedule. Beds hang off root; each Bed Grows Plants."""

node Bed {
    has code: str;

    can tend with WaterBed entry {
        for p in [self ->:Grows:->] {
            p.last_watered = visitor.day;
            visitor.watered += 1;
        }
    }
}

node Plant {
    has species: str;
    has interval_days: int;
    has last_watered: int;

    def is_due(day: int) -> bool {
        return day - self.last_watered >= self.interval_days;
    }
}

edge Grows: Bed --> Plant {}

def find_bed(code: str) -> Bed | None {
    for b in [root -->[?:Bed]] {
        if b.code == code {
            return b;
        }
    }
    return None;
}

walker PlantIn {
    has bed: str;
    has species: str;
    has interval_days: int;
    has day: int;

    can plant with Root entry {
        visit [-->[?:Bed, code == self.bed]] else {
            fresh = here ++> Bed(code=self.bed);
            visit fresh;
        }
    }

    can add with Bed entry {
        here +>:Grows():+> Plant(species=self.species, interval_days=self.interval_days, last_watered=self.day);
        report len([here -->[?:Plant]]);
    }
}

walker WaterBed {
    has bed: str;
    has day: int;
    has watered: int = 0;

    can go with Root entry {
        b = find_bed(self.bed);
        if b is not None {
            visit b;
        }
    }

    can finish with Root exit {
        report self.watered;
    }
}

walker DueOn {
    has day: int;

    can start with Root entry {
        out: list[str] = [];
        for b in [-->[?:Bed]] {
            out.extend([b.code + "/" + p.species for p in [b -->[?:Plant]] if p.is_due(self.day)]);
        }
        out.sort();
        report out;
    }
}

walker Uproot {
    has bed: str;
    has species: str;
    has removed: int = 0;

    can start with Root entry {
        visit [-->[?:Bed, code == self.bed]];
    }

    can pull with Bed entry {
        doomed = [p for p in [here -->[?:Plant]] if p.species == self.species];
        self.removed = len(doomed);
        for p in doomed {
            del p;
        }
    }

    can finish with Root exit {
        report self.removed;
    }
}
