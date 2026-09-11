"""keboola/agnes-the-ai-analyst#677 — cross-document entity linking (OSP lift)."""

obj EntityGraph {
    def mention(doc: str, entity: str) -> None;
    def linked_entities(entity: str, max_hops: int) -> list[str];
    def bridge(a: str, b: str) -> list[str] | None;
}

node Document {
    has doc_id: str;
}

node Entity {
    has name: str;
}

edge Mentions {}
edge CoMention {}

def _ensure_doc(doc_id: str) -> Document {
    for d in [root-->][?:Document] {
        if d.doc_id == doc_id { return d; }
    }
    return root ++> Document(doc_id=doc_id);
}

def _ensure_entity(name: str) -> Entity {
    for e in [root-->][?:Entity] {
        if e.name == name { return e; }
    }
    return root ++> Entity(name=name);
}

def _ensure_comention(a: Entity, b: Entity) -> None {
    for tgt in [a ->:CoMention:->][?:Entity] {
        if tgt.name == b.name { return; }
    }
    a +>:CoMention:+> b;
    b +>:CoMention:+> a;
}

walker LinkedWalker {
    has seed: str;
    has max_hops: int;
    has claimed: dict[str, bool] = {};
    has depth_map: dict[str, int] = {};
    has hits: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Entity, name == self.seed];
        if matches {
            self.depth_map[self.seed] = 0;
            visit [matches[0]];
        } else { disengage; }
    }

    can step with Entity entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        d = self.depth_map.get(here.name, 0);
        if here.name != self.seed { self.hits.append(here.name); }
        if d >= self.max_hops { skip; }
        for tgt in [here ->:CoMention:->][?:Entity] {
            if tgt.name not in self.claimed {
                self.depth_map[tgt.name] = d + 1;
                visit [tgt];
            }
        }
    }
}

walker BridgeWalker {
    has src: str;
    has dst: str;
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has found: bool = False;
    has result: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Entity, name == self.src];
        if matches {
            self.parent[self.src] = "";
            visit [matches[0]];
        } else { disengage; }
    }

    can step with Entity entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name == self.dst {
            self.found = True;
            path: list[str] = [];
            cur = self.dst;
            while cur != "" {
                path.append(cur);
                if cur == self.src { break; }
                cur = self.parent.get(cur, "");
            }
            self.result = [];
            i = len(path) - 1;
            while i >= 0 {
                self.result.append(path[i]);
                i -= 1;
            }
            disengage;
        }
        for tgt in [here ->:CoMention:->][?:Entity] {
            if tgt.name not in self.claimed {
                self.parent[tgt.name] = here.name;
                visit [tgt];
            }
        }
    }
}

impl EntityGraph.mention(doc: str, entity: str) -> None {
    d = _ensure_doc(doc);
    e = _ensure_entity(entity);
    d +>:Mentions:+> e;
    for other in [d ->:Mentions:->][?:Entity] {
        if other.name != entity { _ensure_comention(e, other); }
    }
}

impl EntityGraph.linked_entities(entity: str, max_hops: int) -> list[str] {
    matches = [root-->][?:Entity, name == entity];
    if not matches { return []; }
    w = root spawn LinkedWalker(
        seed=entity, max_hops=max_hops, claimed={}, depth_map={}, hits=[],
    );
    return sorted(w.hits);
}

impl EntityGraph.bridge(a: str, b: str) -> list[str] | None {
    if a == b {
        for e in [root-->][?:Entity] { if e.name == a { return [a]; } }
        return None;
    }
    a_matches = [root-->][?:Entity, name == a];
    b_matches = [root-->][?:Entity, name == b];
    if not a_matches or not b_matches { return None; }
    w = root spawn BridgeWalker(
        src=a, dst=b, claimed={}, parent={}, found=False, result=[],
    );
    if w.found { return w.result; }
    return None;
}
