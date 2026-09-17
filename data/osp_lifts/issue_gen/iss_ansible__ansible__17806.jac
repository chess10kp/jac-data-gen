# ansible/ansible#17806 - hostvars[host][variable] recursive templating
# Hand-rolled var-resolution graph lifted to idiomatic OSP:
# Var nodes carry raw template strings; refs edges point at dependencies.
# Resolution is a recursive traversal with claim-map (resolve-once + skip on
# revisit) so diamond dependency graphs terminate.

node Var {
    has host: str;
    has name: str;
    has raw: str;
    has value: str = "";
    has resolved: bool = False;
}

edge Refs {}

# split "{{ expr }}" -> inner expression, or None if literal
def template_refs(raw: str) -> list[str] | None {
    xs: list[str] = [];
    depth: int = 0;
    cur: str = "";
    for ch in raw {
        if ch == "{" {
            depth += 1;
            if depth == 2 { cur = ""; continue; }
        } else if ch == "}" {
            depth -= 1;
            if depth == 0 { xs.append(cur); cur = ""; continue; }
        }
        if depth >= 2 { cur += ch; }
    }
    return xs;
}

# build the hostvars graph: one Var node per (host, key); refs edges to deps
def build_hostvars(hostvars: dict[str, dict[str, str]]) -> dict[str, Var] {
    idx: dict[str, Var] = {};
    for hname in sorted(hostvars.keys()) {
        for vname in sorted(hostvars[hname].keys()) {
            nd = Var(host=hname, name=vname, raw=hostvars[hname][vname]);
            idx[hname + "." + vname] = nd;
        }
    }
    # wire dependency edges after all nodes exist (diamond-safe)
    for key in sorted(idx.keys()) {
        refs = template_refs(idx[key].raw);
        if refs != None {
            for r in refs {
                if r in idx {
                    idx[key] +>:Refs:+> idx[r];
                }
            }
        }
    }
    return idx;
}

walker Resolve {
    has idx: dict[str, Var] = {};
    has claimed: dict[str, bool] = {};

    can step with Var entry {
        if here.host + "." + here.name in self.claimed { skip; }
        self.claimed[here.host + "." + here.name] = True;
        refs = template_refs(here.raw);
        if refs == None {
            here.value = here.raw;
        } else {
            # resolve dependencies first, then interpolate recursively
            kids: list[Var] = [];
            for dep in [here ->:Refs:->][?:Var] {
                kids.append(dep);
            }
            visit kids;
            out: str = here.raw;
            for dep in [here ->:Refs:->][?:Var] {
                out = out.replace("{{ " + dep.name + " }}", dep.value);
                out = out.replace("{{" + dep.name + "}}", dep.value);
            }
            here.value = out;
        }
        here.resolved = True;
    }
}

def resolve_all(hostvars: dict[str, dict[str, str]]) -> dict[str, dict[str, str]] {
    idx = build_hostvars(hostvars);
    anchor = Var(host="__anchor__", name="__anchor__", raw="");
    root ++> anchor;
    for key in sorted(idx.keys()) {
        anchor +>:Refs:+> idx[key];
    }
    wk = anchor spawn Resolve(idx=idx, claimed={});
    out: dict[str, dict[str, str]] = {};
    for key in sorted(idx.keys()) {
        h = idx[key].host;
        if h not in out {
            out[h] = {};
        }
        out[h][idx[key].name] = idx[key].value;
    }
    return out;
}

walker demo {
    can go with Var entry {
        res = resolve_all(
            {
                "localhost": {"test_var": "this is localhost",
                              "groupvar": "{{ test_var }}"},
                "otherhost": {"test_var": "this is otherhost"}
            }
        );
        print(res);
        self.disengage;
    }
}

with entry {
    n = Var(host="boot", name="boot", raw="x");
    root ++> n;
    root spawn demo();
}
