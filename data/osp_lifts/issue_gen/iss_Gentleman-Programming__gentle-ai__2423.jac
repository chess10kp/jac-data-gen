# PROGRAM iss_Gentleman-Programming__gentle-ai__2423.jac
"""OSP lift for Gentleman-Programming/gentle-ai#2423."""

node ReviewCatalog {
    has label: str;
}

node ReviewSurface {
    has key: str;
}

edge Contains {}
edge DependsOn {}
edge References {}

obj ReviewFixture {
    has catalog: ReviewCatalog;
    has lifecycle: ReviewSurface;
}

walker ReachWalker {
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with ReviewSurface entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print("live " + here.key);
        self.found.append(here.key);
        for kid in [here ->:DependsOn:->][?:ReviewSurface] {
            visit :0: [kid];
        }
    }
}

walker InventoryWalker {
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can scan_catalog with ReviewCatalog entry {
        print("inventory " + here.label);
        for surface in [here ->:Contains:->][?:ReviewSurface] {
            visit :0: [surface];
        }
    }

    can scan_surface with ReviewSurface entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print("surface " + here.key);
        self.found.append(here.key);
    }
}

walker TargetWalker {
    has target: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};

    can seek with ReviewSurface entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print("seek " + here.key);
        if here.key == self.target {
            self.found = True;
        }
        for kid in [here ->:DependsOn:->][?:ReviewSurface] {
            visit :0: [kid];
        }
    }
}

def review_fixture() -> ReviewFixture {
    candidate = ReviewSurface(key="candidate_consent");
    freeze = ReviewSurface(key="freeze");
    admitted = ReviewSurface(key="admitted_lenses");
    correction = ReviewSurface(key="bounded_correction");
    validation = ReviewSurface(key="targeted_validation");
    approval = ReviewSurface(key="approval");
    burn = ReviewSurface(key="burn");

    legacy = ReviewSurface(key="legacy_review_format");
    translator = ReviewSurface(key="compatibility_translator");
    receipt = ReviewSurface(key="terminal_receipt");
    lineage = ReviewSurface(key="lineage_witness");
    recovery = ReviewSurface(key="recovery_shell");
    mirror = ReviewSurface(key="gate_mirror");

    candidate +>:DependsOn:+> freeze;
    freeze +>:DependsOn:+> admitted;
    admitted +>:DependsOn:+> correction;
    admitted +>:DependsOn:+> validation;
    correction +>:DependsOn:+> validation;
    validation +>:DependsOn:+> approval;
    approval +>:DependsOn:+> burn;

    legacy +>:DependsOn:+> translator;
    translator +>:DependsOn:+> receipt;
    recovery +>:References:+> lineage;
    mirror +>:References:+> recovery;

    graph_root = ReviewCatalog(label="review_inventory");
    graph_root +>:Contains:+> candidate;
    graph_root +>:Contains:+> freeze;
    graph_root +>:Contains:+> admitted;
    graph_root +>:Contains:+> correction;
    graph_root +>:Contains:+> validation;
    graph_root +>:Contains:+> approval;
    graph_root +>:Contains:+> burn;
    graph_root +>:Contains:+> legacy;
    graph_root +>:Contains:+> translator;
    graph_root +>:Contains:+> receipt;
    graph_root +>:Contains:+> lineage;
    graph_root +>:Contains:+> recovery;
    graph_root +>:Contains:+> mirror;

    return ReviewFixture(catalog=graph_root, lifecycle=candidate);
}

def live_surface_keys(lifecycle: ReviewSurface) -> list[str] {
    w = lifecycle spawn ReachWalker(claimed={});
    return sorted(w.found);
}

def orphaned_surface_keys(catalog: ReviewCatalog, lifecycle: ReviewSurface) -> list[str] {
    live = live_surface_keys(lifecycle);
    w = catalog spawn InventoryWalker(claimed={});
    orphaned: list[str] = [];
    for key in w.found {
        if not (key in live) {
            orphaned.append(key);
        }
    }
    return sorted(orphaned);
}

def has_live_path(lifecycle: ReviewSurface, key: str) -> bool {
    w = lifecycle spawn TargetWalker(target=key, claimed={});
    return w.found;
}
