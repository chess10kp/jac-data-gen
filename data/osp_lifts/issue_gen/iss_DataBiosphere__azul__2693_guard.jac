# Lifting DataBiosphere/azul#2693 — verbatim manifest formats: a Bundle is a
# complete metadata subgraph; entities link via derived/derives edges; replicas
# capture verbatim content plus hub ids from the file-derivation closure.

node Entity {
    has eid: str;
    has etype: str;
    has content: dict[str, any];
}

node Bundle {
    has bid: str;
}

edge derives {}      # file -> replica it came from (replica derived FROM file)
edge references {}   # replica -> file it is derived from

walker BuildBundle {
    has bundle_id: str;
    has claimed: dict[str, bool] = {};
    has entities: dict[str, Entity] = {};

    can collect with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.entities[here.eid] = here;
        kids: list[Entity] = [];
        for ch in [here ->:references:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here <-:derives:<-][?:Entity] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        }
        visit [kids];
    }
}

def make_bundle(bundle_id: str, seed: Entity) -> Bundle {
    b = Bundle(bid=bundle_id);
    root ++> seed;
    root ++> b;
    return b;
}

def collect_bundle(bundle_id: str, seed: Entity) -> dict[str, dict[str, any]] {
    wk = seed spawn BuildBundle(bundle_id=bundle_id, claimed={});
    out: dict[str, dict[str, any]] = {};
    for eid in sorted(wk.entities.keys()) {
        ent = wk.entities[eid];
        out[eid] = {"entity_type": ent.etype, "content": ent.content};
    }
    return out;
}

def manifest_entry(entities: dict[str, dict[str, any]], eid: str) -> dict[str, any] {
    # unknown ids tolerated: verbatim empty entry rather than KeyError
    if eid not in entities {
        return {"entity_type": "unknown", "content": {}, "hub_ids": []};
    }
    ent = entities[eid];
    return {"entity_type": ent["entity_type"], "content": ent["content"], "hub_ids": []};
}

walker HubClosurer {
    has claimed: dict[str, bool] = {};
    has hubs: list[str] = [];

    can walk with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        if here.etype == "file" {
            self.hubs.append(here.eid);
        }
        for ch in [here ->:references:->][?:Entity] {
            visit [ch];
        }
        for ch in [here <-:derives:<-][?:Entity] {
            visit [ch];
        }
    }
}

def hub_ids(seed: Entity) -> list[str] {
    wk = seed spawn HubClosurer(claimed={});
    return sorted(wk.hubs);
}

# hidden tests appended to candidate source

def _fixture() -> Entity {
    f1 = Entity(eid="f1", etype="file", content={"name": "a.bam"});
    f2 = Entity(eid="f2", etype="file", content={"name": "b.bam"});
    r1 = Entity(eid="r1", etype="replica", content={"url": "s3://x/a.bam"});
    r2 = Entity(eid="r2", etype="replica", content={"url": "s3://x/b.bam"});
    r1 +>:references:+> f1;
    r2 +>:references:+> f2;
    f1 +>:derives:+> r1;
    f2 +>:derives:+> r2;
    return f1;
}

test "collect_bundle_closure" {
    seed = _fixture();
    got = collect_bundle("b1", seed);
    assert sorted(got.keys()) == ["f1", "r1"];
    assert got["f1"]["entity_type"] == "file";
    assert got["r1"]["content"] == {"url": "s3://x/a.bam"};
}

test "hub_ids_files_only" {
    seed = _fixture();
    assert hub_ids(seed) == ["f1"];
}

test "manifest_entry_known" {
    seed = _fixture();
    ents = collect_bundle("b1", seed);
    me = manifest_entry(ents, "f1");
    assert me["entity_type"] == "file";
    assert me["content"] == {"name": "a.bam"};
}

test "manifest_entry_unknown_tolerated" {
    seed = _fixture();
    ents = collect_bundle("b1", seed);
    me = manifest_entry(ents, "nope");
    assert me["entity_type"] == "unknown";
    assert me["hub_ids"] == [];
}

test "cycle_tolerance" {
    a = Entity(eid="fa", etype="file", content={"n": 1});
    b = Entity(eid="rb", etype="replica", content={"n": 2});
    b +>:references:+> a;
    a +>:derives:+> b;
    b +>:derives:+> a;
    assert sorted(hub_ids(a)) == ["fa"];
    assert sorted(collect_bundle("c1", a).keys()) == ["fa", "rb"];
}

test "make_bundle_node" {
    seed = _fixture();
    b = make_bundle("bx", seed);
    assert b.bid == "bx";
}
