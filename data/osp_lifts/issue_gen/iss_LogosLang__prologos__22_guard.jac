"""Between-form orchestration — LogosLang/prologos#22."""

node Hub {
    has hid: str = "top";
}

node Form {
    has name: str;
    has kind: str;
    has deps: list[str] = [];
    has cid: str = "";
}

edge Member {}
edge Depends {}

walker RegWalker {
    has claimed: dict[str, bool] = {};
    has registry: dict[str, bool] = {};

    can on_hub with Hub entry {
        seeds: list[Form] = [];
        for fm in [here ->:Member:->][?:Form] {
            seeds.append(fm);
        }
        visit :0: seeds else { disengage; }
        print("reg phase start");
    }

    can on_form with Form entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.registry[here.name] = True;
        print(f"register {here.name}");
        nexts: list[Form] = [];
        for dep_fm in [here ->:Depends:->][?:Form] {
            nexts.append(dep_fm);
        }
        visit :0: nexts;
    }
}

walker ElabWalker {
    has claimed: dict[str, bool] = {};
    has registry: dict[str, bool] = {};
    has results: dict[str, str] = {};

    can on_hub with Hub entry {
        seeds: list[Form] = [];
        for fm in [here ->:Member:->][?:Form] {
            seeds.append(fm);
        }
        visit :0: seeds else { disengage; }
        print("elab phase start");
    }

    can on_form with Form entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        ready: bool = True;
        for dep_nm in here.deps {
            if dep_nm not in self.registry {
                ready = False;
            }
        }
        if here.kind == "defn" {
            if ready {
                self.results[here.name] = "elaborated";
            } else {
                self.results[here.name] = "blocked";
            }
        } else {
            self.results[here.name] = "registered";
        }
        print(f"elab {here.name} {self.results[here.name]}");
        nexts: list[Form] = [];
        for dep_fm in [here ->:Depends:->][?:Form] {
            nexts.append(dep_fm);
        }
        visit :0: nexts;
    }
}

def build_hub(specs: list[list]) -> Hub {
    hub_node = Hub(hid="top");
    root ++> hub_node;
    name_map: dict[str, Form] = {};
    for spec in specs {
        nm: str = spec[0];
        kd: str = spec[1];
        dep_list: list[str] = spec[2];
        cid_val: str = f"{nm}:{kd}";
        fm = Form(name=nm, kind=kd, deps=dep_list, cid=cid_val);
        name_map[nm] = fm;
        hub_node +>:Member:+> fm;
    }
    for spec in specs {
        src_nm: str = spec[0];
        dep_names: list[str] = spec[2];
        src_fm = name_map[src_nm];
        for dep_nm in dep_names {
            if dep_nm in name_map {
                tgt_fm = name_map[dep_nm];
                src_fm +>:Depends:+> tgt_fm;
            }
        }
    }
    return hub_node;
}

def sequential_process(specs: list[list]) -> dict[str, str] {
    results: dict[str, str] = {};
    for spec in specs {
        nm: str = spec[0];
        kd: str = spec[1];
        dep_names: list[str] = spec[2];
        if kd == "defn" {
            ready: bool = True;
            for dep_nm in dep_names {
                dep_ok: bool = False;
                if dep_nm in results {
                    st: str = results[dep_nm];
                    if st == "elaborated" {
                        dep_ok = True;
                    }
                }
                if not dep_ok {
                    ready = False;
                }
            }
            if ready {
                results[nm] = "elaborated";
            } else {
                results[nm] = "blocked";
            }
        } else {
            results[nm] = "registered";
        }
    }
    return results;
}

def bsp_process(specs: list[list]) -> dict[str, str] {
    hub_node = build_hub(specs);
    reg_w = hub_node spawn RegWalker(claimed={});
    elab_w = hub_node spawn ElabWalker(claimed={}, registry=reg_w.registry);
    return elab_w.results;
}

def get_status(results: dict[str, str], name: str) -> str {
    if name in results {
        return results[name];
    }
    return "missing";
}

test "mutual_rec_bsp_elaborates" {
    specs: list[list] = [
        ["even?", "defn", ["odd?"]],
        ["odd?", "defn", ["even?"]],
    ];
    seq: dict[str, str] = sequential_process(specs);
    bsp: dict[str, str] = bsp_process(specs);
    assert seq["even?"] == "blocked";
    assert seq["odd?"] == "blocked";
    assert bsp["even?"] == "elaborated";
    assert bsp["odd?"] == "elaborated";
}

test "diamond_revisit_registry" {
    specs: list[list] = [
        ["top", "defn", ["left", "right"]],
        ["left", "defn", ["shared"]],
        ["right", "defn", ["shared"]],
        ["shared", "spec", []],
    ];
    hub_node = build_hub(specs);
    reg_w = hub_node spawn RegWalker(claimed={});
    bsp: dict[str, str] = bsp_process(specs);
    names: list[str] = [];
    for nm in reg_w.registry {
        names.append(nm);
    }
    assert sorted(names) == ["left", "right", "shared", "top"];
    assert bsp["top"] == "elaborated";
    assert bsp["left"] == "elaborated";
    assert bsp["right"] == "elaborated";
    assert bsp["shared"] == "registered";
}

test "unknown_dep_tolerated" {
    specs: list[list] = [["foo", "defn", ["ghost"]]];
    bsp: dict[str, str] = bsp_process(specs);
    assert bsp["foo"] == "blocked";
    assert get_status(bsp, "ghost") == "missing";
}

test "linear_chain_parity" {
    specs: list[list] = [
        ["a", "defn", ["b"]],
        ["b", "defn", ["c"]],
        ["c", "spec", []],
    ];
    seq: dict[str, str] = sequential_process(specs);
    bsp: dict[str, str] = bsp_process(specs);
    assert seq["a"] == "blocked";
    assert seq["b"] == "blocked";
    assert seq["c"] == "registered";
    assert bsp["a"] == "elaborated";
    assert bsp["b"] == "elaborated";
    assert bsp["c"] == "registered";
}

test "spec_only_registered" {
    specs: list[list] = [["nat", "spec", []]];
    bsp: dict[str, str] = bsp_process(specs);
    assert bsp["nat"] == "registered";
    assert get_status(bsp, "nat") == "registered";
    assert get_status(bsp, "missing") == "missing";
}
