# Azure/AzureGraph#40
# Recursive request-body sanitizer: convert naive datetime leaves
# (mirroring R POSIXct/Date values) to unambiguous UTC ISO 8601 strings
# before JSON serialization, exactly as the suggested fix for
# call_graph_url() prescribes.

node BodyField {
    has key: str;
    has raw: str;              # original serialized leaf value
    has kind: str = "scalar";  # "datetime" | "date" | "scalar" | "dict"
    has fixed: str = "";       # unambiguous UTC ISO 8601 rendering
}

edge BodyMember {}

def looks_datetime(v: str) -> bool {
    # bare "YYYY-MM-DD HH:MM:SS" — offset-less, ambiguous (the bug)
    parts: list[str] = v.split(" ");
    if len(parts) != 2 { return False; }
    if len(parts[0]) != 10 { return False; }
    if len(parts[1]) != 8 { return False; }
    return True;
}

def to_utc_iso(v: str) -> str {
    # "YYYY-MM-DD HH:MM:SS" -> "YYYY-MM-DDTHH:MM:SSZ"
    parts: list[str] = v.split(" ");
    return parts[0] + "T" + parts[1] + "Z";
}

def to_utc_date(v: str) -> str {
    # Date leaf stays a plain ISO date; tagged UTC at the call site
    return v;
}

def sanitize_body(root_val: dict) -> dict {
    # Recursive pre-serialization pass: convert ambiguous leaves to UTC ISO
    out: dict = {};
    for k in sorted(root_val.keys()) {
        v = root_val[k];
        if type(v) == dict {
            out[k] = sanitize_body(v);
        } elif type(v) == list {
            conv: list = [];
            for item in v {
                s: str = item;
                if looks_datetime(s) {
                    conv.append(to_utc_iso(s));
                } else {
                    conv.append(s);
                }
            }
            out[k] = conv;
        } else {
            s: str = v;
            if looks_datetime(s) {
                out[k] = to_utc_iso(s);
            } else {
                out[k] = s;
            }
        }
    }
    return out;
}

def build_field_graph(body: dict) -> BodyField {
    # Flatten a body into an explicit node/edge graph; returns the root node.
    root_node = BodyField(key="__root__", raw="", kind="dict");
    for k in sorted(body.keys()) {
        v = body[k];
        nd: BodyField;
        if looks_datetime(v) {
            nd = BodyField(key=k, raw=v, kind="datetime", fixed=to_utc_iso(v));
        } else {
            nd = BodyField(key=k, raw=v, kind="scalar", fixed=v);
        }
        root_node +>:BodyMember:+> nd;
    }
    return root_node;
}

walker CollectBody {
    has claimed: dict[str, bool] = {};
    has seen_keys: list[str] = [];
    has conversions: int = 0;

    can step with BodyField entry {
        if here.key in self.claimed {
            skip;  # diamond revisit: claim-map, never disengage
        }
        self.claimed[here.key] = True;
        if here.kind == "datetime" {
            self.conversions += 1;
        } elif here.key != "__root__" {
            self.seen_keys.append(here.key);
        }
        kids: list[BodyField] = [here ->:BodyMember:->][?:BodyField];
        visit kids;
    }
}

def call_graph_url(body: dict) -> dict {
    # public API: returns the JSON-ready body with unambiguous UTC datetimes
    return sanitize_body(body);
}

def inspect_body(body: dict) -> dict {
    # public API: builds field graph, walks it; returns a result dict with
    # "keys" (sorted seen keys) and "conversions" (count of datetime fixes)
    root_node = build_field_graph(body);
    wk = root_node spawn CollectBody(claimed={});
    sk: list[str] = sorted(wk.seen_keys);
    res: dict = {};
    res["keys"] = sk;
    res["conversions"] = wk.conversions;
    return res;
}

test "sanitize converts ambiguous datetime leaves" {
    body: dict = {};
    body["start"] = "2022-07-31 14:05:19";
    body["label"] = "run";
    out = call_graph_url(body);
    assert out["start"] == "2022-07-31T14:05:19Z";
    assert out["label"] == "run";
}

test "sanitize leaves non-datetime leaves untouched" {
    body: dict = {};
    body["date_only"] = "2022-07-31";
    body["num"] = "42";
    out = call_graph_url(body);
    assert out["date_only"] == "2022-07-31";
    assert out["num"] == "42";
}

test "inspect_body walk counts keys and conversions" {
    body: dict = {};
    body["a"] = "2022-07-31 14:05:19";
    body["b"] = "x";
    res = inspect_body(body);
    assert res["keys"] == ["a", "b"];
    assert res["conversions"] == 1;
}

test "walker handles diamond revisit via claim-map" {
    root_node = build_field_graph({});
    dup = BodyField(key="d", raw="y", kind="scalar", fixed="y");
    mid1 = BodyField(key="m1", raw="", kind="dict", fixed="");
    mid2 = BodyField(key="m2", raw="", kind="dict", fixed="");
    root_node +>:BodyMember:+> mid1;
    root_node +>:BodyMember:+> mid2;
    mid1 +>:BodyMember:+> dup;
    mid2 +>:BodyMember:+> dup;
    leaf = BodyField(key="leaf", raw="2023-01-02 03:04:05", kind="datetime", fixed="2023-01-02T03:04:05Z");
    dup +>:BodyMember:+> leaf;
    wk = root_node spawn CollectBody(claimed={});
    assert len(sorted(wk.seen_keys)) == 3;
    assert wk.conversions == 1;
}

test "empty body yields empty result" {
    res = inspect_body({});
    assert res["keys"] == [];
    assert res["conversions"] == 0;
}
