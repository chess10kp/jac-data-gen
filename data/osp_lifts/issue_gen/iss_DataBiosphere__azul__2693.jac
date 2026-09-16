# Verbatim manifest formats — DataBiosphere/azul#2693
# A Bundle is a complete subgraph of metadata entities connected by
# FK relations. Each entity carries verbatim content and hub_ids
# (files derived from it / deriving it). Walkers compute the full
# subgraph closure and replica hub sets.

node Entity {
    has eid: str;
    has etype: str;          # replica/entity classification, e.g. table name
    has content: dict[str, str];
}

edge Derives {}             # file <-> replica lineage
edge ForeignKey {}          # AnVIL TDR FK relations

def build_bundle(bfid: str) -> Entity {
    # fixture: a small complete subgraph with a diamond (two FK paths
    # converge on the same diagnosis entity) plus file lineage
    f1 = Entity(eid=bfid + ":file1", etype="files", content={"name": "a.bam"});
    f2 = Entity(eid=bfid + ":file2", etype="files", content={"name": "b.bam"});
    s = Entity(eid=bfid + ":sample", etype="sample", content={"donor": "d1"});
    d = Entity(eid=bfid + ":diag", etype="diagnoses", content={"dx": "AML"});
    root ++> f1;
    root ++> f2;
    f1 +>:ForeignKey:+> s;
    f2 +>:ForeignKey:+> s;
    s +>:ForeignKey:+> d;
    f1 +>:Derives:+> d;
    f2 +>:Derives:+> d;
    return d;
}

def entity_type(e: Entity) -> str {
    return e.etype;
}

walker CollectBundle {
    has claimed: dict[str, bool] = {};
    has found: list[Entity] = [];

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here);
        kids: list[Entity] = [];
        for ch in [here ->:ForeignKey:->][?:Entity] { kids.append(ch); }
        for ch in [here ->:Derives:->][?:Entity] { kids.append(ch); }
        if len(kids) {
            visit kids;
        } else {
            visit [here] else { disengage; }
        }
    }
}

def subgraph_entities(start: Entity) -> list[str] {
    wk = start spawn CollectBundle(claimed={});
    ids: list[str] = [];
    for e in wk.found { ids.append(e.eid); }
    ids = sorted(ids);
    return ids;
}

def hub_ids(start: Entity) -> list[str] {
    # hub set = ids of file entities reachable to/from the replica
    ids: list[str] = [];
    for e in [start <-:Derives:-][?:Entity] {
        ids.append(e.eid);
    }
    for e in [start ->:Derives:->][?:Entity] {
        ids.append(e.eid);
    }
    return sorted(ids);
}

with entry {
    d = build_bundle("bx");
    root spawn CollectBundle(claimed={});
    print(subgraph_entities(d));
    print(hub_ids(d));
}
