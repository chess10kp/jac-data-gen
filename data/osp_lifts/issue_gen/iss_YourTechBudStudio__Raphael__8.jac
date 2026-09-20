"""Archive and restore with inherited causes. YourTechBudStudio/Raphael#8."""

node GraphHub {
    has label: str = "hub";
}

node Entity {
    has id: str;
    has etype: str;
    has slug: str;
    has revision: int;
    has content: str;
}

edge Parent {}

node ArchiveCause {
    has owner: str;
    has reason_key: str;
}

edge HasCause {}

glob USER_REASON = "user";

walker UpArchiveProbe {
    has claimed: dict[str, bool] = {};
    has blocked: bool = False;
    has origins: list[str] = [];

    can ascend with Entity entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        for c in [here ->:HasCause:->][?:ArchiveCause] {
            self.blocked = True;
            tag: str = here.id + ":" + c.owner + ":" + c.reason_key;
            self.origins.append(tag);
        }
        ups: list[Entity] = [here ->:Parent:->][?:Entity];
        if ups {
            visit :0: ups;
        } else {
            disengage;
        }
    }
}

walker FindEntity {
    has sought: str = "";
    has hit: Entity | None = None;
    has claimed: dict[str, bool] = {};

    can from_hub with GraphHub entry {
        kids: list[Entity] = [here -->][?:Entity];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }

    can scan with Entity entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        if here.id == self.sought {
            self.hit = here;
            disengage;
        }
        downs: list[Entity] = [here <-:Parent:<-][?:Entity];
        for d in downs {
            visit :0: [d];
        }
        disengage;
    }
}

walker ListAll {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can from_hub with GraphHub entry {
        seeds: list[Entity] = [here -->][?:Entity];
        if seeds {
            visit :0: seeds;
        } else {
            disengage;
        }
    }

    can walk with Entity entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.ids.append(here.id);
        chs: list[Entity] = [here <-:Parent:<-][?:Entity];
        for ch in chs {
            visit :0: [ch];
        }
        disengage;
    }
}

walker DemoRun {
    can run with GraphHub entry {
        print(seed_issue_fixture(here));
        got = get_entity(here, "11");
        print(got);
        disengage;
    }
}

def locate_entity(graph_root: GraphHub, entity_id: str) -> Entity | None {
    w = graph_root spawn FindEntity(sought=entity_id, hit=None, claimed={});
    return w.hit;
}

def effective_state(ent: Entity) -> dict {
    w = ent spawn UpArchiveProbe(claimed={}, blocked=False, origins=[]);
    orig: list[str] = sorted(w.origins);
    return {"archived": w.blocked, "origins": orig};
}

def get_entity(graph_root: GraphHub, entity_id: str) -> dict {
    ent = locate_entity(graph_root, entity_id);
    if ent is None {
        return {"id": entity_id, "found": False, "archived": False, "origins": []};
    }
    eff = effective_state(ent);
    return {
        "id": ent.id,
        "found": True,
        "archived": eff["archived"],
        "origins": eff["origins"],
        "revision": ent.revision,
        "slug": ent.slug,
        "content": ent.content,
    };
}

def archive_entity(
    graph_root: GraphHub,
    entity_id: str,
    owner: str,
    reason_key: str | None = None,
) -> dict {
    ent = locate_entity(graph_root, entity_id);
    if ent is None {
        return {"ok": False, "id": entity_id, "error": "unknown"};
    }
    rk: str = USER_REASON;
    if reason_key is not None {
        rk = reason_key;
    }
    for c in [ent ->:HasCause:->][?:ArchiveCause] {
        if c.owner == owner and c.reason_key == rk {
            eff = effective_state(ent);
            return {
                "ok": True,
                "id": entity_id,
                "revision": ent.revision,
                "archived": eff["archived"],
            };
        }
    }
    cause = ArchiveCause(owner=owner, reason_key=rk);
    ent +>:HasCause:+> cause;
    ent.revision += 1;
    eff2 = effective_state(ent);
    return {
        "ok": True,
        "id": entity_id,
        "revision": ent.revision,
        "archived": eff2["archived"],
    };
}

def restore_entity(graph_root: GraphHub, entity_id: str, owner: str) -> dict {
    ent = locate_entity(graph_root, entity_id);
    if ent is None {
        return {"ok": False, "id": entity_id, "error": "unknown"};
    }
    victims: list[ArchiveCause] = [];
    for c in [ent ->:HasCause:->][?:ArchiveCause] {
        if c.owner == owner and c.reason_key == USER_REASON {
            victims.append(c);
        }
    }
    removed = False;
    if victims {
        removed = True;
        for c in victims {
            destroy c;
        }
        ent.revision += 1;
    }
    eff = effective_state(ent);
    return {
        "ok": True,
        "id": entity_id,
        "revision": ent.revision,
        "archived": eff["archived"],
        "removed": removed,
    };
}

def list_entities(graph_root: GraphHub, include_archived: bool = False) -> list[str] {
    w = graph_root spawn ListAll(claimed={}, ids=[]);
    out: list[str] = [];
    for eid in sorted(w.ids) {
        info = get_entity(graph_root, eid);
        if include_archived or not info["archived"] {
            out.append(eid);
        }
    }
    return sorted(out);
}

def update_entity(graph_root: GraphHub, entity_id: str, content: str) -> dict {
    ent = locate_entity(graph_root, entity_id);
    if ent is None {
        return {"ok": False, "id": entity_id, "error": "unknown"};
    }
    eff = effective_state(ent);
    if eff["archived"] {
        return {"ok": False, "id": entity_id, "error": "archived"};
    }
    ent.content = content;
    ent.revision += 1;
    return {"ok": True, "id": entity_id, "revision": ent.revision};
}

def link_child(parent: Entity, child: Entity) {
    child +>:Parent:+> parent;
}

def seed_diamond_fixture(graph_root: GraphHub) {
    top = Entity(id="top", etype="project", slug="top", revision=1, content="t");
    left = Entity(id="left", etype="note", slug="l", revision=1, content="l");
    right = Entity(id="right", etype="note", slug="r", revision=1, content="r");
    bottom = Entity(id="bottom", etype="note", slug="b", revision=1, content="b");
    graph_root ++> top;
    link_child(top, left);
    link_child(top, right);
    link_child(left, bottom);
    link_child(right, bottom);
}

def seed_issue_fixture(graph_root: GraphHub) -> GraphHub {
    proj = Entity(id="1", etype="project", slug="root", revision=1, content="root");
    note = Entity(id="11", etype="note", slug="n11", revision=1, content="eleven");
    graph_root ++> proj;
    link_child(proj, note);
    return graph_root;
}

with entry {
    hub = GraphHub();
    root ++> hub;
    root spawn DemoRun;
}
