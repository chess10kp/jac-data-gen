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
