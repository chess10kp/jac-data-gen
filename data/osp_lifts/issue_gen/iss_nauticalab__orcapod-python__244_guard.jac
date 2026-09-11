// iss_nauticalab__orcapod-python__244.jac
node Dataset {
    has did: str;
    has weight: int;
    has terminal: bool = False;
    has resident: bool = False;
    has pending_release: bool = False;
}

edge Depends {}

obj Pipeline {
    has limit: int;
    has datasets: dict[str, Dataset] = {};
}

walker ReleaseSweep {
    has claimed: dict[str, bool] = {};

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        here.pending_release = True;
        print("release candidate " + here.did);
        for kid in [here ->:Depends:->][?:Dataset] {
            visit :0: [kid];
        }
    }
}

walker ReachSweep {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.did);
        print("reachable " + here.did);
        for kid in [here ->:Depends:->][?:Dataset] {
            visit :0: [kid];
        }
    }
}

def new_pipeline(limit: int) -> Pipeline {
    if limit < 1 {
        return Pipeline(1);
    }
    return Pipeline(limit);
}

def add_dataset(
    p: Pipeline,
    did: str,
    weight: int,
    terminal: bool = False
) -> None {
    if did in p.datasets {
        return None;
    }
    item = Dataset(did, weight, terminal);
    p.datasets[did] = item;
    return None;
}

def add_dependency(p: Pipeline, parent: str, child: str) -> bool {
    if parent not in p.datasets { return False; }
    if child not in p.datasets { return False; }
    upstream = p.datasets[parent];
    downstream = p.datasets[child];
    upstream +>: Depends :+> downstream;
    return True;
}

def admit(p: Pipeline, did: str) -> bool {
    if did not in p.datasets { return False; }
    if p.datasets[did].resident { return True; }
    if resident_count(p) >= p.limit { return False; }
    p.datasets[did].resident = True;
    return True;
}

def release(p: Pipeline, did: str) -> bool {
    if did not in p.datasets { return False; }
    if not p.datasets[did].resident { return False; }
    with p.datasets[did] entry {
        root spawn ReleaseSweep;
    }
    for key in p.datasets {
        if p.datasets[key].pending_release {
            p.datasets[key].resident = False;
            p.datasets[key].pending_release = False;
        }
    }
    return True;
}

def resident_count(p: Pipeline) -> int {
    total = 0;
    for key in p.datasets {
        if p.datasets[key].resident {
            total += 1;
        }
    }
    return total;
}

def resident_ids(p: Pipeline) -> list[str] {
    ids: list[str] = [];
    for key in p.datasets {
        if p.datasets[key].resident {
            ids.append(key);
        }
    }
    return sorted(ids);
}

def reachable(p: Pipeline, did: str) -> list[str] {
    ids: list[str] = [];
    if did not in p.datasets {
        return ids;
    }
    with p.datasets[did] entry {
        root spawn ReachSweep;
    }
    ids.append(did);
    for child in [p.datasets[did] ->:Depends:->][?:Dataset] {
        ids.append(child.did);
    }
    return sorted(ids);
}

test "diamond revisit is tolerated" {
    p = new_pipeline(4);
    add_dataset(p, "a", 1);
    add_dataset(p, "b", 1);
    add_dataset(p, "c", 1);
    add_dataset(p, "d", 1);
    assert (add_dependency(p, "a", "b"));
    assert (add_dependency(p, "a", "c"));
    assert (add_dependency(p, "b", "d"));
    assert (add_dependency(p, "c", "d"));
    assert (reachable(p, "a") == ["a", "b", "c", "d"]);
}

test "unknown identifiers are tolerated" {
    p = new_pipeline(2);
    assert (not add_dependency(p, "missing", "also-missing"));
    assert (not admit(p, "missing"));
    assert (not release(p, "missing"));
    assert (reachable(p, "missing") == []);
}

test "credit limit controls admission" {
    p = new_pipeline(2);
    add_dataset(p, "a", 1);
    add_dataset(p, "b", 1);
    add_dataset(p, "c", 1);
    assert (admit(p, "a"));
    assert (admit(p, "b"));
    assert (not admit(p, "c"));
    assert (resident_count(p) == 2);
    assert (resident_ids(p) == ["a", "b"]);
}

test "release frees a credit" {
    p = new_pipeline(1);
    add_dataset(p, "a", 1);
    add_dataset(p, "b", 1);
    assert (admit(p, "a"));
    assert (release(p, "a"));
    assert (admit(p, "b"));
    assert (resident_ids(p) == ["b"]);
}
