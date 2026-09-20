"""NCEAS/metacat#1429 — closure table for Metacat version chains."""

node RegistryHub {}

node Version {
    has guid: str;
}

edge Member {}

edge Supersedes {}

node ClosureFact {
    has parent_guid: str;
    has child_guid: str;
    has depth: int;
}

obj VersionRegistry {
    has hub: RegistryHub;
    has facts: list[ClosureFact] = [];
}

walker DescendFacts {
    has claimed: dict[str, bool] = {};
    has anchor_guid: str;
    has depth: int = 0;
    has bucket: list[ClosureFact] = [];

    can walk with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        row = ClosureFact(
            parent_guid=self.anchor_guid,
            child_guid=here.guid,
            depth=self.depth
        );
        self.bucket.append(row);
        kids: list[Version] = [here ->:Supersedes:->][?:Version];
        for kid in kids {
            wk = kid spawn DescendFacts(
                claimed=self.claimed,
                anchor_guid=self.anchor_guid,
                depth=self.depth + 1,
                bucket=self.bucket
            );
        }
        print("closure", self.anchor_guid, here.guid, self.depth);
    }
}

walker ClosureDemo {
    can run with RegistryHub entry {
        root spawn DescendFacts(
            claimed={},
            anchor_guid="demo",
            depth=0,
            bucket=[]
        );
        print("demo done");
    }
}

glob {
    def make_registry() -> VersionRegistry {
        hub = RegistryHub();
        root ++> hub;
        return VersionRegistry(hub=hub, facts=[]);
    }

    def _find_version(hub: RegistryHub, guid: str) -> Version | None {
        for nd in [hub ->:Member:->][?:Version] {
            if nd.guid == guid {
                return nd;
            }
        }
        return None;
    }

    def register_version(reg: VersionRegistry, guid: str) {
        existing = _find_version(reg.hub, guid);
        if existing {
            return;
        }
        nd = Version(guid=guid);
        reg.hub +>:Member:+> nd;
    }

    def link_version_chain(reg: VersionRegistry, older: str, newer: str) {
        parent_nd = _find_version(reg.hub, older);
        child_nd = _find_version(reg.hub, newer);
        if parent_nd and child_nd {
            parent_nd +>:Supersedes:+> child_nd;
        }
    }

    def rebuild_closure(reg: VersionRegistry) {
        reg.facts = [];
        versions: list[Version] = [reg.hub ->:Member:->][?:Version];
        for ver in versions {
            claimed: dict[str, bool] = {};
            bucket: list[ClosureFact] = [];
            w = ver spawn DescendFacts(
                claimed=claimed,
                anchor_guid=ver.guid,
                depth=0,
                bucket=bucket
            );
            for item in w.bucket {
                reg.facts.append(item);
            }
            print("rebuild", ver.guid, len(w.bucket));
        }
    }

    def descendants_of(reg: VersionRegistry, parent_guid: str) -> list[tuple[str, int]] {
        out: list[tuple[str, int]] = [];
        for fact in reg.facts {
            if fact.parent_guid == parent_guid and fact.child_guid != parent_guid {
                pair: tuple[str, int] = (fact.child_guid, fact.depth);
                out.append(pair);
            }
        }
        return sorted(out);
    }

    def ancestors_of(reg: VersionRegistry, child_guid: str) -> list[tuple[str, int]] {
        out: list[tuple[str, int]] = [];
        for fact in reg.facts {
            if fact.child_guid == child_guid and fact.parent_guid != child_guid {
                pair: tuple[str, int] = (fact.parent_guid, fact.depth);
                out.append(pair);
            }
        }
        return sorted(out);
    }

    def pair_depth(reg: VersionRegistry, parent_guid: str, child_guid: str) -> int {
        for fact in reg.facts {
            if fact.parent_guid == parent_guid and fact.child_guid == child_guid {
                return fact.depth;
            }
        }
        return -1;
    }
}

test "linear_chain_closure" {
    reg = make_registry();
    register_version(reg, "v1");
    register_version(reg, "v2");
    register_version(reg, "v3");
    link_version_chain(reg, "v1", "v2");
    link_version_chain(reg, "v2", "v3");
    rebuild_closure(reg);
    assert descendants_of(reg, "v1") == [("v2", 1), ("v3", 2)];
    assert ancestors_of(reg, "v3") == [("v1", 2), ("v2", 1)];
    assert pair_depth(reg, "v1", "v3") == 2;
    assert pair_depth(reg, "v1", "v1") == -1;
}

test "register_idempotent" {
    reg = make_registry();
    register_version(reg, "dup");
    register_version(reg, "dup");
    rebuild_closure(reg);
    assert descendants_of(reg, "dup") == [];
    assert pair_depth(reg, "dup", "dup") == -1;
}

test "diamond_adversarial_order" {
    reg = make_registry();
    register_version(reg, "root_v");
    register_version(reg, "left");
    register_version(reg, "right");
    register_version(reg, "join");
    link_version_chain(reg, "root_v", "left");
    link_version_chain(reg, "root_v", "right");
    link_version_chain(reg, "left", "join");
    link_version_chain(reg, "right", "join");
    rebuild_closure(reg);
    assert descendants_of(reg, "root_v") == [("join", 2), ("left", 1), ("right", 1)];
    assert ancestors_of(reg, "join") == [("left", 1), ("right", 1), ("root_v", 2)];
    assert pair_depth(reg, "root_v", "join") == 2;
}

test "missing_link_noop" {
    reg = make_registry();
    register_version(reg, "only");
    link_version_chain(reg, "only", "ghost");
    link_version_chain(reg, "ghost", "only");
    rebuild_closure(reg);
    assert descendants_of(reg, "only") == [];
    assert ancestors_of(reg, "only") == [];
    assert pair_depth(reg, "only", "ghost") == -1;
}

test "rebuild_replaces_stale_facts" {
    reg = make_registry();
    register_version(reg, "a");
    register_version(reg, "b");
    link_version_chain(reg, "a", "b");
    rebuild_closure(reg);
    assert pair_depth(reg, "a", "b") == 1;
    link_version_chain(reg, "b", "a");
    rebuild_closure(reg);
    assert pair_depth(reg, "a", "b") == 1;
    assert descendants_of(reg, "a") == [("b", 1)];
}
