"""Family lineage records lifted to OSP.

Persons are ``Person`` nodes; ``BornOf`` edges point from a person
to their recorded parent. Ancestry queries climb linearly; blood
relations compare two climbed chains; lineage size folds bottom-up.
"""

node Person {
    has name: str;
    has birth_year: int;
    has kin_total: int = 0;  # staging: descendants below, folded at exit
}

edge BornOf: Person --> Person {}

"""Build the fixture lineage deterministically; returns the founder."""
def build_family() -> Person {
    root ++> (rosa := Person(name="Rosa", birth_year=1938));
    root ++> (marta := Person(name="Marta", birth_year=1960));
    root ++> (felix := Person(name="Felix", birth_year=1963));
    root ++> (nina := Person(name="Nina", birth_year=1985));
    root ++> (otto := Person(name="Otto", birth_year=1988));
    root ++> (pia := Person(name="Pia", birth_year=2010));
    marta +>:BornOf:+> rosa;
    felix +>:BornOf:+> rosa;
    nina +>:BornOf:+> marta;
    otto +>:BornOf:+> marta;
    pia +>:BornOf:+> nina;
    return rosa;
}

"""Record a birth under `parent` (None for the founder); return them."""
def born(parent: Person | None, name: str, birth_year: int) -> Person {
    root ++> (p := Person(name=name, birth_year=birth_year));
    if parent is not None {
        p +>:BornOf:+> parent;
    }
    return p;
}

walker KinClimb {
    """Climbs BornOf edges toward the founder; linear walk."""
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Person entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        visit [->:BornOf:->] else { report self.chain; disengage; }
    }
}

walker LineageFold {
    """Exit folds descendant counts bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Person entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:BornOf:<-];
    }

    can fold with Person exit {
        total = 1;
        for c in [<-:BornOf:<-] {
            total += c.kin_total;
        }
        here.kin_total = total;
    }
}

"""Names of direct ancestors of `person`, nearest parent first."""
def ancestor_names(person: Person) -> list[str] {
    w = person spawn KinClimb();
    return w.chain[1:];
}

"""Number of generations between `person` and the founder."""
def generation_gap(person: Person) -> int {
    w = person spawn KinClimb();
    return len(w.chain) - 1;
}

"""True when `a` and `b` share a lineage (common ancestor or descent)."""
def is_blood_related(a: Person, b: Person) -> bool {
    wa = a spawn KinClimb();
    wb = b spawn KinClimb();
    kin_a = set(wa.chain);
    kin_b = set(wb.chain);
    return len(kin_a & kin_b) > 0;
}

"""Number of people at or below `founder`, counting them."""
def lineage_size(founder: Person) -> int {
    founder spawn LineageFold();
    return founder.kin_total;
}

"""Names on the path from the founder down to `person`, inclusive."""
def eldest_line(person: Person) -> list[str] {
    w = person spawn KinClimb();
    return w.chain[::-1];
}
