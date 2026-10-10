"""Route guard: model the malformed-id 400 contract on UUID path params.

Demonstrates that a request walker validates the path segment BEFORE any
store lookup is attempted, returning 400 for a non-UUID and never touching
the (mocked) store. The walker also refuses to echo the bad value back in
its message, so a malicious caller cannot probe via reflected text.
"""

import from uuid { UUID }

# --- domain entities (what the API would otherwise look up) ---

node Board {
    has board_id: str = "";
    has title: str = "";
}

node Column {
    has column_id: str = "";
    has name: str = "";
}

node Card {
    has card_id: str = "";
    has text: str = "";
}

node Organization {
    has org_id: str = "";
    has name: str = "";
}

# --- the (mock) store: a single sentinel we can detect being touched ---

node StoreProbe {
    has touched: bool = False;
    has label: str = "store";
}

# --- the route archetypes: the relationship that names a request param ---

edge BoardRoute: any --> any { has path_segment: str = ""; }
edge ColumnRoute: any --> any { has path_segment: str = ""; }
edge CardRoute: any --> any { has path_segment: str = ""; }
edge OrgRoute: any --> any { has path_segment: str = ""; }

# --- the guard: a small helper that parses-or-fails without echoing input ---

def path_uuid(name: str, raw: str) -> str | None {
    parsed = None;
    try {
        parsed = str(UUID(raw));
    } except Exception as e {
        print(f"[GUARD] {name} must be a uuid");
        return None;
    }
    return parsed;
}

# --- the request walker: validates FIRST, looks up SECOND ---

walker GetRequest {
    has param_name: str = "";
    has param_value: str = "";
    has status: int = 0;
    has body: str = "";

    can start with Root entry {
        parsed = path_uuid(self.param_name, self.param_value);
        if parsed is None {
            self.status = 400;
            self.body = f"{self.param_name} must be a uuid";
            disengage;
        }
        store = StoreProbe(label="store");
        store.touched = True;
        root ++> store;
        self.status = 200;
        self.body = f"looked up {parsed}";
        visit [-->];
    }
}

# --- cascade + cycle demo: typed Parent edges with an explicit visited set ---

edge Parent: any --> any { }

node TreeNode {
    has label: str = "";
}

walker CascadeMarker {
    has visited: list[str] = [];
    has mark_order: list[str] = [];

    can start with Root entry {
        visit [->:Parent:->];
    }

    can descend with TreeNode entry {
        key = here.label;
        if key in self.visited {
            print(f"[CYCLE] already visited {key}; disengaging");
            disengage;
        }
        self.visited.append(key);
        self.mark_order.append(key);
        print(f"[MARK] {key}");
        visit [->:Parent:->];
    }
}

# --- demonstration wiring ---

with entry {
    print("=== malformed-id guard demo ===");
    req = GetRequest(param_name="board_id", param_value="not-a-uuid");
    root spawn req;
    echo_allowed = "not-a-uuid" in req.body;
    print(f"  status={req.status} body={req.body} echoed_input={echo_allowed}");

    print("=== well-formed id demo ===");
    good = GetRequest(
        param_name="column_id",
        param_value="550e8400-e29b-41d4-a716-446655440000"
    );
    root spawn good;
    print(f"  status={good.status} body={good.body}");

    print("=== per-route 400 assertion ===");
    cases = [
        ("board_id",        "boards/:board_id"),
        ("column_id",       "columns/:column_id/cards"),
        ("card_id",         "cards/:card_id"),
        ("organization_id", "auth org path"),
    ];
    for (param, route) in cases {
        r = GetRequest(param_name=param, param_value="zzz-malformed");
        root spawn r;
        ok = r.status == 400;
        no_echo = "zzz-malformed" not in r.body;
        print(f"  {route}: status={r.status} ok={ok} no_echo={no_echo}");
    }

    print("=== cascade over typed Parent edges with cycle guard ===");
    a = TreeNode(label="A");
    b = TreeNode(label="B");
    c = TreeNode(label="C");
    root +>:Parent:+> a;
    a +>:Parent:+> b;
    b +>:Parent:+> c;
    c +>:Parent:+> a;
    walker_inst = CascadeMarker();
    root spawn walker_inst;
    print(f"  order={walker_inst.mark_order}");
}
