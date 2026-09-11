"""OSP lift for nauticalab/orcapod-python#249."""

node Artifact {
    has path: str;
    has exists: bool = True;
}

node CacheRecord {
    has input_hash: str;
    has outputs: list[Artifact] = [];
    has valid: bool = True;
}

node Pod {
    has name: str;
    has lineage: list[str] = [];
}

edge Depends {}

walker AuditOutputs {
    has claimed: dict[str, bool] = {};
    has missing: bool = False;

    can step with CacheRecord entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for artifact in here.outputs {
            if artifact.path in self.claimed { skip; }
            self.claimed[artifact.path] = True;
            if not artifact.exists {
                self.missing = True;
            }
            print artifact.path;
        }
    }
}

walker CollectLineage {
    has claimed: dict[str, bool> = {};

    can step with Pod entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        here.lineage.append(here.name);
        print here.name;
        for child in [here ->:Depends:->][?:Pod] {
            visit :0: [child];
        }
    }
}

def make_artifact(path: str, exists: bool = True) -> Artifact {
    return Artifact(path=path, exists=exists);
}

def make_record(input_hash: str, outputs: list[Artifact] | None = None) -> CacheRecord {
    if outputs is None {
        outputs = [];
    }
    return CacheRecord(input_hash=input_hash, outputs=outputs);
}

def cache_lookup(
    records: list[CacheRecord],
    input_hash: str,
    verify_output_exists: bool = False
) -> CacheRecord | None {
    for record in records {
        if record.input_hash != input_hash {
            continue;
        }
        if not verify_output_exists {
            return record;
        }
        missing: bool = False;
        for artifact in record.outputs {
            if not artifact.exists {
                missing = True;
            }
        }
        if missing {
            return None;
        }
        return record;
    }
    return None;
}

def collect_lineage(start: Pod) -> list[str] {
    start.lineage = [];
    root spawn CollectLineage;
    return start.lineage;
}

test "cache hit ignores existence when verification disabled" {
    artifact = make_artifact("/cache/x", False);
    record = make_record("h1", [artifact]);
    records: list[CacheRecord] = [record];
    assert (cache_lookup(records, "h1", False) == record);
}

test "missing referenced output invalidates verified hit" {
    artifact = make_artifact("/cache/x", False);
    record = make_record("h1", [artifact]);
    records: list[CacheRecord] = [record];
    assert (cache_lookup(records, "h1", True) == None);
}

test "diamond lineage tolerates adversarial revisit" {
    a = Pod(name="a");
    b = Pod(name="b");
    c = Pod(name="c");
    d = Pod(name="d");
    a +>:Depends:+> b;
    a +>:Depends:+> c;
    b +>:Depends:+> d;
    c +>:Depends:+> d;
    names = collect_lineage(a);
    assert (len(names) == 4);
    assert (sorted(names) == ["a", "b", "c", "d"]);
}

test "unknown input hash returns none" {
    artifact = make_artifact("/cache/x", True);
    record = make_record("known", [artifact]);
    records: list[CacheRecord] = [record];
    assert (cache_lookup(records, "unknown", True) == None);
}

test "empty output record remains a valid verified hit" {
    record = make_record("empty");
    records: list[CacheRecord] = [record];
    assert (cache_lookup(records, "empty", True) == record);
}
