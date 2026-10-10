"""Greenhouse watering rounds: beds of plants, each with its own watering interval and growth stage."""

enum Stage {
    SEEDLING = "seedling",
    GROWING = "growing",
    MATURE = "mature"
}

node Bed {
    has code: str;
}

node Plant {
    has tag: str;
    has species: str;
    has interval_days: int;
    has last_watered: int;
    has stage: Stage = Stage.SEEDLING;

    def gap -> int {
        return 1 if self.stage == Stage.SEEDLING else self.interval_days;
    }
}

edge Grows: Bed --> Plant {
    has planted_on: int;
}

"""Water every plant growing in the bed the walker is spawned on."""
walker WaterRound {
    has day: int;
    has watered: int = 0;

    can open_bed with Bed entry {
        visit [here ->:Grows:->];
    }

    can water with Plant entry {
        here.last_watered = self.day;
        self.watered += 1;
    }
}

"""Sweep all beds from root and list plants due for water."""
walker DueScan {
    has day: int;
    has due: list[str] = [];

    can start with Root entry {
        visit [-->[?:Bed]];
    }

    can scan with Bed entry {
        for p in [here ->:Grows:->[?:Plant]] {
            if self.day - p.last_watered >= p.gap() {
                self.due.append(f"{here.code}/{p.tag}");
            }
        }
    }
}

def find_bed(code: str) -> Bed | None {
    wanted = code;
    found = [root -->[?:Bed, code == wanted]];
    return found[0] if found else None;
}

def find_plant(tag: str) -> Plant | None {
    wanted = tag;
    for b in [root -->[?:Bed]] {
        found = [b ->:Grows:->[?:Plant, tag == wanted]];
        if found {
            return found[0];
        }
    }
    return None;
}

def add_bed(code: str) -> bool {
    if find_bed(code) is not None {
        return False;
    }
    root ++> Bed(code=code);
    return True;
}

def plant(bed: str, tag: str, species: str, interval_days: int, day: int) -> bool {
    b = find_bed(bed);
    if b is None or find_plant(tag) is not None {
        return False;
    }
    b +>:Grows(planted_on=day):+> Plant(tag=tag, species=species, interval_days=interval_days, last_watered=day);
    return True;
}

def promote(tag: str) -> str {
    p = find_plant(tag);
    if p is None {
        return "";
    }
    if p.stage == Stage.SEEDLING {
        p.stage = Stage.GROWING;
    } elif p.stage == Stage.GROWING {
        p.stage = Stage.MATURE;
    }
    return p.stage.value;
}

def water_bed(bed: str, day: int) -> int {
    b = find_bed(bed);
    if b is None {
        return 0;
    }
    return (b spawn WaterRound(day=day)).watered;
}

def due_on(day: int) -> list[str] {
    return sorted((root spawn DueScan(day=day)).due);
}

def uproot(tag: str) -> bool {
    p = find_plant(tag);
    if p is None {
        return False;
    }
    del p;
    return True;
}

def age(tag: str, day: int) -> int {
    p = find_plant(tag);
    if p is None {
        return -1;
    }
    return day - [edge p <-:Grows:<-][0].planted_on;
}
