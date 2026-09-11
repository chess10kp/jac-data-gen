"""Biological taxonomy tree lifted to OSP.

Taxa are ``Taxon`` nodes; ``MemberOf`` edges point from a subordinate
taxon to its parent rank. Breadcrumbs climb; species counts and
membership sweeps descend with explicit claim-map cycle policy.
"""

node Taxon {
    has tid: str;            # unique taxon handle
    has name: str;
    has rank: str;
}

edge MemberOf: Taxon --> Taxon {}

"""Build the fixture taxonomy deterministically; returns the root taxon."""
def build_taxonomy() -> Taxon {
    root ++> (life := Taxon(tid="t1", name="Life", rank="root"));
    root ++> (animalia := Taxon(tid="t2", name="Animalia", rank="kingdom"));
    root ++> (chordata := Taxon(tid="t3", name="Chordata", rank="phylum"));
    root ++> (mammalia := Taxon(tid="t4", name="Mammalia", rank="class"));
    root ++> (canis := Taxon(tid="t5", name="Canis", rank="genus"));
    root ++> (lupus := Taxon(tid="t6", name="lupus", rank="species"));
    root ++> (familiaris := Taxon(tid="t7", name="familiaris", rank="species"));
    root ++> (plantae := Taxon(tid="t8", name="Plantae", rank="kingdom"));
    animalia +>:MemberOf:+> life;
    chordata +>:MemberOf:+> animalia;
    mammalia +>:MemberOf:+> chordata;
    canis +>:MemberOf:+> mammalia;
    lupus +>:MemberOf:+> canis;
    familiaris +>:MemberOf:+> canis;
    plantae +>:MemberOf:+> life;
    return life;
}

"""Place a taxon under `parent` (None for the root) and return it."""
def classify(parent: Taxon | None, name: str, rank: str) -> Taxon {
    # Every taxon hangs off root at creation, so the count yields a fresh tid.
    next_id = "t" + str(len([root -->]) + 1);
    root ++> (t := Taxon(tid=next_id, name=name, rank=rank));
    if parent is not None {
        t +>:MemberOf:+> parent;
    }
    return t;
}

walker CrumbClimb {
    """Climbs MemberOf edges to the classification root; linear walk."""
    has labels: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with Taxon entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.labels.append(f"{here.rank}:{here.name}");
        visit [->:MemberOf:->] else { report self.labels; disengage; }
    }
}

walker SpeciesFold {
    """Exit folds species tallies into a walker-side map keyed by tid."""
    has claimed: dict[str, bool] = {};
    has tally: dict[str, int] = {};   # tid -> species count at/below

    can descend with Taxon entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        visit [<-:MemberOf:<-];
    }

    can fold with Taxon exit {
        # Children always exit before their parent (reverse entry order),
        # so every child's tally is already recorded here.
        total = 0;
        if here.rank == "species" {
            total = 1;
        }
        for s in [<-:MemberOf:<-] {
            total += self.tally[s.tid];
        }
        self.tally[here.tid] = total;
    }
}

walker NameSweep {
    """Collects taxon names (and ranks) below a start taxon."""
    has names: list[str] = [];
    has ranks: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with Taxon entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.names.append(here.name);
        self.ranks.append(here.rank);
        visit [<-:MemberOf:<-];
    }
}

"""``rank:name`` labels from the root down to `start`, inclusive."""
def breadcrumb(start: Taxon) -> list[str] {
    w = start spawn CrumbClimb();
    return w.labels[::-1];
}

"""Number of rank=='species' taxa at or below `start`."""
def species_count(start: Taxon) -> int {
    w = start spawn SpeciesFold();
    return w.tally[start.tid];
}

"""True when a taxon named `name` exists at or below `base`."""
def contains(base: Taxon, name: str) -> bool {
    w = base spawn NameSweep();
    return name in w.names;
}

"""Distinct ranks in the subtree rooted at `base`, sorted."""
def rank_spread_list(base: Taxon) -> list[str] {
    w = base spawn NameSweep();
    return sorted(set(w.ranks));
}
test "breadcrumb climbs root-first" {
    life = build_taxonomy();
    animalia = [t for t in [life <--][?:Taxon] if t.name == "Animalia"][0];
    chordata = [t for t in [animalia <--][?:Taxon]][0];
    mammalia = [t for t in [chordata <--][?:Taxon]][0];
    canis = [t for t in [mammalia <--][?:Taxon]][0];
    familiaris = [t for t in [canis <--][?:Taxon] if t.name == "familiaris"][0];
    assert breadcrumb(familiaris) == [
        "root:Life",
        "kingdom:Animalia",
        "phylum:Chordata",
        "class:Mammalia",
        "genus:Canis",
        "species:familiaris",
    ];
}

test "species_count folds species tally" {
    life = build_taxonomy();
    assert species_count(life) == 2;
}

test "contains sweeps subtree membership" {
    life = build_taxonomy();
    assert contains(life, "lupus");
    assert not contains(life, "fungi");
}

test "rank_spread_list dedupes ranks" {
    life = build_taxonomy();
    animalia = [t for t in [life <--][?:Taxon] if t.name == "Animalia"][0];
    assert rank_spread_list(animalia) == [
        "class", "genus", "kingdom", "phylum", "species",
    ];
}
test "classify grows the tree and queries follow" {
    life = build_taxonomy();
    fungi = classify(life, "Fungi", "kingdom");
    yeast = classify(fungi, "yeast", "species");
    assert contains(fungi, "yeast");
    assert not contains(fungi, "lupus");
    assert breadcrumb(yeast) == ["root:Life", "kingdom:Fungi", "species:yeast"];
    assert species_count(life) == 3;
    assert rank_spread_list(fungi) == ["kingdom", "species"];
}
