"""hertz-contrib/swagger-generate#15 — IDL schema expansion with circular reference guards."""

obj SchemaGraph { has messages: dict[str, MsgNode] = {}; }
node MsgNode { has name: str; }
edge RefsTo {}

walker SchemaWalk {
    has visiting: dict[str, bool] = {};
    has emitted: dict[str, bool] = {};
    has names: list[str] = [];

    can step with MsgNode entry {
        if here.name in self.visiting { skip; }
        if here.name in self.emitted { skip; }
        self.visiting[here.name] = True;
        self.emitted[here.name] = True;
        self.names.append(here.name);
        visit [->:RefsTo:->] else { disengage; };
        self.visiting[here.name] = False;
    }
}

walker CycleProbe {
    has visiting: dict[str, bool] = {};
    has found: bool = False;

    can step with MsgNode entry {
        if here.name in self.visiting {
            self.found = True;
            disengage;
        }
        self.visiting[here.name] = True;
        visit [->:RefsTo:->] else { disengage; };
        self.visiting[here.name] = False;
    }
}

def load_messages(
    messages: list[str],
    refs: list[tuple[str, str]],
) -> SchemaGraph {
    g = SchemaGraph(messages={});
    for m in messages {
        n = MsgNode(name=m);
        root ++> n;
        g.messages[m] = n;
    }
    for (src, dst) in refs {
        a = g.messages.get(src, None);
        b = g.messages.get(dst, None);
        if a is not None and b is not None { a +>:RefsTo:+> b; }
    }
    return g;
}

def safe_schema_names(g: SchemaGraph, roots: list[str]) -> list[str] {
    emitted: dict[str, bool] = {};
    visiting: dict[str, bool] = {};
    names: list[str] = [];
    for r in roots {
        anchor = g.messages.get(r, None);
        if anchor is None { continue; }
        w = anchor spawn SchemaWalk(visiting=visiting, emitted=emitted, names=names);
        names = w.names;
        emitted = w.emitted;
        visiting = w.visiting;
    }
    return sorted(names);
}

def has_cycle(g: SchemaGraph, start: str) -> bool {
    anchor = g.messages.get(start, None);
    if anchor is None { return False; }
    w = anchor spawn CycleProbe(visiting={}, found=False);
    return w.found;
}
