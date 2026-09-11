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
test "ancestor_names climbs nearest-first" {
    rosa = build_family();
    kids = [rosa <--][?:Person];
    marta = [k for k in kids if k.name == "Marta"][0];
    nina = [k for k in [marta <--][?:Person] if k.name == "Nina"][0];
    otto = [k for k in [marta <--][?:Person] if k.name == "Otto"][0];
    pia = [k for k in [nina <--][?:Person] if k.name == "Pia"][0];
    assert ancestor_names(pia) == ["Nina", "Marta", "Rosa"];
    assert generation_gap(otto) == 2;
    assert generation_gap(rosa) == 0;
}

test "is_blood_related shares lineage" {
    rosa = build_family();
    kids = [rosa <--][?:Person];
    felix = [k for k in kids if k.name == "Felix"][0];
    marta = [k for k in kids if k.name == "Marta"][0];
    pia = [[marta <--][?:Person][0] <--][?:Person][0];
    assert is_blood_related(pia, felix);
}

test "eldest_line reverses the founder path" {
    rosa = build_family();
    marta = [k for k in [rosa <--][?:Person] if k.name == "Marta"][0];
    nina = [k for k in [marta <--][?:Person] if k.name == "Nina"][0];
    pia = [k for k in [nina <--][?:Person]][0];
    assert eldest_line(pia) == ["Rosa", "Marta", "Nina", "Pia"];
}

test "lineage_size folds descendants" {
    rosa = build_family();
    assert lineage_size(rosa) == 6;
}
test "born extends the lineage" {
    rosa = build_family();
    kids = [rosa <--][?:Person];
    marta = [k for k in kids if k.name == "Marta"][0];
    nina = [k for k in [marta <--][?:Person] if k.name == "Nina"][0];
    sol = born(nina, "Sol", 2035);
    assert ancestor_names(sol) == ["Nina", "Marta", "Rosa"];
    assert eldest_line(sol) == ["Rosa", "Marta", "Nina", "Sol"];
    assert generation_gap(sol) == 3;
    assert lineage_size(rosa) == 7;
    assert is_blood_related(sol, rosa);
}
