"""
Verbatim manifest replica collection for bundle subgraphs.
DataBiosphere/azul#2693
"""

glob root;

node Entity {
    has cid: str;
    has entity_type: str;
    has content: dict;
    has hub_ids: list[str] = [];
}

edge Fk {}

node FileRef {
    has fid: str;
}

edge FileHub {}

walker ManifestWalker {
    has root_cid: str;
    has claimed: dict[str, bool] = {};
    has found: list[dict] = [];

    can boot with root entry {
        print "manifest boot", self.root_cid;
        target: Entity | None = None;
        for nd in [here -->][?:Entity] {
            if nd.cid == self.root_cid {
                target = nd;
            }
        }
        if target is not None {
            visit target;
        } else {
            disengage;
        }
    }

    can traverse with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        doc: dict = {};
        doc["entity_type"] = here.entity_type;
        doc["content"] = here.content;
        hubs: list[str] = [];
        for h in here.hub_ids {
            hubs.append(h);
        }
        doc["hub_ids"] = sorted(hubs);
        self.found.append(doc);
        replica_cid = here.cid;
        replica_etype = here.entity_type;
        print "replica", replica_cid, replica_etype;
        for ch in [here ->:Fk:->][?:Entity] {
            visit :0: ch;
        }
    }
}

def register_entity(cid: str, entity_type: str, content: dict) -> Entity {
    nd = Entity(cid=cid, entity_type=entity_type, content=content);
    root ++> nd;
    return nd;
}

def bind_fk(parent: Entity, child: Entity) {
    parent +>:Fk:+> child;
}

def bind_file_hub(entity: Entity, file_id: str) {
    fr = FileRef(fid=file_id);
    root ++> fr;
    entity +>:FileHub:+> fr;
    present = False;
    for h in entity.hub_ids {
        if h == file_id {
            present = True;
        }
    }
    if not present {
        entity.hub_ids.append(file_id);
    }
}

def replica_document(entity: Entity) -> dict {
    doc: dict = {};
    doc["entity_type"] = entity.entity_type;
    doc["content"] = entity.content;
    hubs: list[str] = [];
    for h in entity.hub_ids {
        hubs.append(h);
    }
    doc["hub_ids"] = sorted(hubs);
    return doc;
}

def replica_for(entity_cid: str) -> dict | None {
    for nd in [root -->][?:Entity] {
        if nd.cid == entity_cid {
            return replica_document(nd);
        }
    }
    return None;
}

def sort_manifest(docs: list[dict]) -> list[dict] {
    out: list[dict] = [];
    for d in docs {
        out.append(d);
    }
    if len(out) <= 1 {
        return out;
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            ta = out[i]["entity_type"];
            tb = out[j]["entity_type"];
            if tb < ta {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def collect_verbatim_manifest(root_cid: str) -> list[dict] {
    w = root spawn ManifestWalker(root_cid=root_cid, claimed={}, found=[]);
    out: list[dict] = [];
    for item in w.found {
        out.append(item);
    }
    return sort_manifest(out);
}
