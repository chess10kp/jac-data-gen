"""richlander/dotnet-inspect#4023 — Bounded call-graph overlay for annotated source."""

node Member {
    has name: str;
}

edge Calls {}

obj CallOverlayStore {
    has members: dict[str, Member] = {};
}

walker CalleeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 0;
    has cur_depth: int = 0;
    has anchor: str = "";

    can step with Member entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        if self.cur_depth < self.max_depth {
            self.cur_depth += 1;
            visit [->:Calls:->][?:Member];
            self.cur_depth -= 1;
        }
    }
}

walker CallerWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 0;
    has cur_depth: int = 0;
    has anchor: str = "";

    can step with Member entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        if self.cur_depth < self.max_depth {
            self.cur_depth += 1;
            visit [<-:Calls:<-][?:Member];
            self.cur_depth -= 1;
        }
    }
}

def load_overlay(
    member_names: list[str],
    call_edges: list[tuple[str, str]],
) -> CallOverlayStore {
    store = CallOverlayStore();
    for name in member_names {
        nd = Member(name=name);
        root ++> nd;
        store.members[name] = nd;
    }
    for (caller, callee) in call_edges {
        c = store.members.get(caller, None);
        d = store.members.get(callee, None);
        if c is not None and d is not None { c +>:Calls:+> d; }
    }
    return store;
}

def callees_within(store: CallOverlayStore, member: str, depth: int) -> list[str] {
    nd = store.members.get(member, None);
    if nd is None or depth < 0 { return []; }
    w = nd spawn CalleeWalk(claimed={}, max_depth=depth, anchor=member);
    return sorted(w.found);
}

def callers_within(store: CallOverlayStore, member: str, depth: int) -> list[str] {
    nd = store.members.get(member, None);
    if nd is None or depth < 0 { return []; }
    w = nd spawn CallerWalk(claimed={}, max_depth=depth, anchor=member);
    return sorted(w.found);
}

def fan_in(store: CallOverlayStore, member: str) -> int {
    nd = store.members.get(member, None);
    if nd is None { return 0; }
    callers = [m for m in [nd <-:Calls:<-][?:Member]];
    return len(callers);
}

test "bounded call overlay" {
    g = load_overlay(
        ["GetUser", "BuildUri", "GetFromJson", "Parse", "ParseList"],
        [
            ("GetUser", "BuildUri"), ("GetUser", "GetFromJson"),
            ("Parse", "ParseList"), ("ParseList", "Parse"),
        ],
    );
    assert callees_within(g, "GetUser", 2) == ["BuildUri", "GetFromJson"];
    assert fan_in(g, "GetFromJson") == 1;
}
