"""microsoft/TypeScript#10649 — recursive module root resolution."""

glob MODULE_SEARCH_KINDS: list[str] = ["shared", "node_modules"];

node Store {
    has paths: dict[str, Dir] = {};
    has modules: dict[str, bool] = {};
}

node Dir {
    has path: str;
}

edge Up {}

walker ModuleResolve {
    has claimed: dict[str, bool] = {};
    has specifier: str = "";
    has modules: dict[str, bool] = {};
    has kinds: list[str] = [];
    has hit: str = "";

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        if self.hit == "" {
            for kind in self.kinds {
                target: str = here.path + "/" + kind + "/" + self.specifier;
                if target in self.modules {
                    if self.modules[target] {
                        self.hit = target;
                        print("resolved", target);
                    }
                }
            }
        }
        if self.hit != "" {
            disengage;
        } else {
            ups: list[Dir] = [here ->:Up:->][?:Dir];
            if ups {
                visit :0: [ups[0]];
            } else {
                disengage;
            }
        }
    }
}

walker RootCollector {
    has claimed: dict[str, bool] = {};
    has kinds: list[str] = [];
    has results: list[str] = [];

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        for kind in self.kinds {
            base: str = here.path + "/" + kind;
            self.results.append(base);
        }
        ups: list[Dir] = [here ->:Up:->][?:Dir];
        if ups {
            visit :0: [ups[0]];
        } else {
            print("roots_done", len(self.results));
            disengage;
        }
    }
}

walker Demo {
    can run with root entry {
        demo_resolution();
        disengage;
    }
}

def make_store() -> Store {
    s = Store();
    root ++> s;
    return s;
}

def add_directory(store: Store, path: str, parent_path: str) -> None {
    if path in store.paths {
        return;
    }
    nd = Dir(path=path);
    store.paths[path] = nd;
    root ++> nd;
    if parent_path != "" {
        if parent_path != path {
            if parent_path in store.paths {
                par: Dir = store.paths[parent_path] as Dir;
                nd +>:Up:+> par;
            }
        }
    }
}

def register_module(store: Store, module_path: str) -> None {
    store.modules[module_path] = True;
}

def resolve_module(store: Store, specifier: str, from_path: str) -> str | None {
    if from_path not in store.paths {
        return None;
    }
    start: Dir = store.paths[from_path] as Dir;
    kinds: list[str] = MODULE_SEARCH_KINDS;
    w = start spawn ModuleResolve(
        claimed={},
        specifier=specifier,
        modules=store.modules,
        kinds=kinds,
        hit=""
    );
    if w.hit == "" {
        return None;
    }
    return w.hit;
}

def collect_search_roots(store: Store, from_path: str) -> list[str] {
    if from_path not in store.paths {
        empty: list[str] = [];
        return empty;
    }
    start: Dir = store.paths[from_path] as Dir;
    kinds: list[str] = MODULE_SEARCH_KINDS;
    w = start spawn RootCollector(claimed={}, kinds=kinds, results=[]);
    out: list[str] = sorted(w.results);
    return out;
}

def demo_resolution() -> None {
    s = make_store();
    add_directory(s, "/repo", "");
    add_directory(s, "/repo/apps", "/repo");
    add_directory(s, "/repo/apps/web", "/repo/apps");
    add_directory(s, "/repo/apps/web/src", "/repo/apps/web");
    register_module(s, "/repo/apps/web/shared/components/Button");
    hit: str | None = resolve_module(s, "components/Button", "/repo/apps/web/src");
    print("demo", hit);
}

with entry {
    root spawn Demo;
}

test "resolve_walks_up_to_shared" {
    s = make_store();
    add_directory(s, "/repo", "");
    add_directory(s, "/repo/apps", "/repo");
    add_directory(s, "/repo/apps/web", "/repo/apps");
    add_directory(s, "/repo/apps/web/src", "/repo/apps/web");
    register_module(s, "/repo/apps/web/shared/components/Button");
    got: str | None = resolve_module(s, "components/Button", "/repo/apps/web/src");
    assert got == "/repo/apps/web/shared/components/Button";
}

test "resolve_node_modules_kind" {
    s = make_store();
    add_directory(s, "/r", "");
    register_module(s, "/r/node_modules/pkg/index");
    got: str | None = resolve_module(s, "pkg/index", "/r");
    assert got == "/r/node_modules/pkg/index";
}

test "resolve_missing_module" {
    s = make_store();
    add_directory(s, "/r", "");
    got: str | None = resolve_module(s, "nope", "/r");
    assert got is None;
}

test "resolve_unknown_from" {
    s = make_store();
    got: str | None = resolve_module(s, "x", "/missing");
    assert got is None;
}

test "collect_roots_sorted" {
    s = make_store();
    add_directory(s, "/a", "");
    add_directory(s, "/a/b", "/a");
    add_directory(s, "/a/b/c", "/a/b");
    got: list[str] = collect_search_roots(s, "/a/b/c");
    expect: list[str] = [
        "/a/b/c/node_modules",
        "/a/b/c/shared",
        "/a/b/node_modules",
        "/a/b/shared",
        "/a/node_modules",
        "/a/shared"
    ];
    assert got == expect;
}

test "collect_unknown_from" {
    s = make_store();
    got: list[str] = collect_search_roots(s, "/nope");
    empty: list[str] = [];
    assert got == empty;
}
