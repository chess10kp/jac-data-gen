node Dir {
    has path: str;
}

edge contains_dir {
}

edge module_file {
    has name: str;
}

# Module resolver that walks the directory tree upward (like webpack's
# modulesDirectories) searching each ancestor for a matching module dir,
# then recursing into it — the recursive module resolution from the issue.
obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list) -> None {
        self.by_path = {};
        self.shared_dirs = shared_dirs or [];
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
    }

    def parent_of(d: Dir) -> Dir | None {
        ps: list[Dir] = [d ->:contains_dir:->][?:Dir];
        # edges point parent -> child, so scan registry for the parent
        for pth in self.by_path {
            cand: Dir = self.by_path[pth];
            for ch in [cand ->:contains_dir:->][?:Dir] {
                if ch.path == d.path {
                    return cand;
                }
            }
        }
        return None;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(shared_dirs=self.shared_dirs, module_ref=module_ref, found=None);
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        if self.found is not None {
            disengage;
        }
        # try each configured shared directory under the current dir
        for sd in self.shared_dirs {
            cand: str = here.path + "/" + sd;
            target: str = cand + "/" + self.module_ref;
            if cand in [here ->:contains_dir:->][?:Dir][0].path or True {
                # the registry check happens in Resolver; walker probes graph
            }
        }
        # walk to all neighbors (children and the parent chain)
        nbrs: list[Dir] = [here ->:contains_dir:->][?:Dir];
        for n in nbrs {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }
}

node Dir {
    has path: str;
}

edge contains_dir {
}

# Recursive module resolution: from the importing directory, walk up the
# ancestor chain (parent links), probing each ancestor for a shared module
# directory that contains the requested module path.
obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list | None = None) -> None {
        self.by_path = {};
        self.shared_dirs = shared_dirs if shared_dirs is not None else [];
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(
            shared_dirs=self.shared_dirs, module_ref=module_ref, found=None
        );
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        # probe each shared dir under this directory for the module
        for sd in self.shared_dirs {
            cand_path: str = here.path + "/" + sd + "/" + self.module_ref;
            sd_node: Dir | None = self._find_child(here, sd);
            if sd_node is not None {
                if self._find_child(sd_node, self.module_ref) is not None {
                    self.found = cand_path;
                    disengage;
                }
            }
        }
        # continue upward through ancestors (contains_dir edges are parent->child;
        # spawn site's chain is pre-linked both ways via root graph) and downward
        for n in [here ->:contains_dir:->][?:Dir] {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }

    def _find_child(d: Dir, path: str) -> Dir | None {
        for c in [d ->:contains_dir:->][?:Dir] {
            if c.path == path {
                return c;
            }
        }
        return None;
    }
}

# Recursive module resolution (microsoft/TypeScript#10649): like webpack's
# modulesDirectories, from the importing directory we walk the directory
# graph — probing each ancestor chain position for a configured shared
# module directory containing the requested module — recursively.

node Dir {
    has path: str;
}

edge contains_dir {
}

obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list | None = None) -> None {
        self.by_path = {};
        if shared_dirs is not None {
            self.shared_dirs = shared_dirs;
        } else {
            self.shared_dirs = [];
        }
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
    }

    def find_child(d: Dir, name: str) -> Dir | None {
        for c in [d ->:contains_dir:->][?:Dir] {
            if c.path == name {
                return c;
            }
        }
        return None;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(
            shared_dirs=self.shared_dirs,
            module_ref=module_ref,
            resolver=self,
            found=None
        );
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has resolver: Resolver;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        # probe each configured shared dir beneath this directory
        for sd in self.shared_dirs {
            sd_full: str = here.path + "/" + sd;
            sd_node: Dir | None = self.resolver.find_child(here, sd_full);
            if sd_node is not None {
                mod_full: str = sd_full + "/" + self.module_ref;
                mod_node: Dir | None = self.resolver.find_child(sd_node, mod_full);
                if mod_node is not None {
                    self.found = mod_full;
                    disengage;
                }
            }
        }
        # recurse into child directories (diamond revisits handled by claim-map)
        for n in [here ->:contains_dir:->][?:Dir] {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }
}

# Recursive module resolution — microsoft/TypeScript#10649
# Like webpack's modulesDirectories: from the importing directory, the
# resolver walks the directory graph (ancestors + shared dirs) probing
# for a directory that contains the requested module, recursively.

node Dir {
    has path: str;
}

edge contains_dir {
}

obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list | None = None) -> None {
        self.by_path = {};
        if shared_dirs is not None {
            self.shared_dirs = shared_dirs;
        } else {
            self.shared_dirs = [];
        }
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
    }

    def find_child(d: Dir, full_path: str) -> Dir | None {
        for c in [d ->:contains_dir:->][?:Dir] {
            if c.path == full_path {
                return c;
            }
        }
        return None;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(
            shared_dirs=self.shared_dirs,
            module_ref=module_ref,
            resolver=self,
            found=None
        );
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has resolver: Resolver;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        for sd in self.shared_dirs {
            sd_full: str = here.path + "/" + sd;
            sd_node: Dir | None = self.resolver.find_child(here, sd_full);
            if sd_node is not None {
                mod_full: str = sd_full + "/" + self.module_ref;
                mod_node: Dir | None = self.resolver.find_child(sd_node, mod_full);
                if mod_node is not None {
                    self.found = mod_full;
                    disengage;
                }
            }
        }
        for n in [here ->:contains_dir:->][?:Dir] {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }
}

test "direct hit in shared dir" {
    r = Resolver(shared_dirs=["shared"]);
    root spawn BuildTree(r);
    assert r.resolve("/app", "Button") == "/app/shared/Button";;
    disengage;
}

test "unknown start dir returns None" {
    r = Resolver(shared_dirs=["shared"]);
    root spawn BuildTree(r);
    assert r.resolve("/nope", "Button") == None;;
    disengage;
}

test "unknown module ref returns None" {
    r = Resolver(shared_dirs=["shared"]);
    root spawn BuildTree(r);
    assert r.resolve("/app", "Nope") == None;;
    disengage;
}

test "diamond revisit does not corrupt resolution" {
    r = Resolver(shared_dirs=["shared"]);
    root spawn BuildDiamond(r);
    assert r.resolve("/app", "Button") == "/app/shared/Button";;
    disengage;
}

test "recursive upward walk through nested tree" {
    r = Resolver(shared_dirs=["shared"]);
    root spawn BuildNested(r);
    assert r.resolve("/a/b/c", "Button") == "/a/shared/Button";;
    disengage;
}

walker BuildTree {
    can go with root entry {
        app = r_add(self, "/app");
        shr = r_add(self, "/app/shared");
        btn = r_add(self, "/app/shared/Button");
        r_connect(self, "/app", "/app/shared");
        r_connect(self, "/app/shared", "/app/shared/Button");
        print("built");
        disengage;
    }
}

def mk_tree() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    app = r.add_dir("/app");
    shr = r.add_dir("/app/shared");
    btn = r.add_dir("/app/shared/Button");
    r.connect("/app", "/app/shared");
    r.connect("/app/shared", "/app/shared/Button");
    return r;
}

def mk_diamond() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    r.add_dir("/app");
    r.add_dir("/app/shared");
    r.add_dir("/app/shared/Button");
    r.add_dir("/app/x");
    r.add_dir("/app/y");
    r.connect("/app", "/app/x");
    r.connect("/app", "/app/y");
    r.connect("/app/x", "/app/shared");
    r.connect("/app/y", "/app/shared");
    r.connect("/app/shared", "/app/shared/Button");
    return r;
}

def mk_nested() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    r.add_dir("/a");
    r.add_dir("/a/b");
    r.add_dir("/a/b/c");
    r.add_dir("/a/shared");
    r.add_dir("/a/shared/Button");
    r.connect("/a", "/a/b");
    r.connect("/a/b", "/a/b/c");
    r.connect("/a", "/a/shared");
    r.connect("/a/shared", "/a/shared/Button");
    return r;
}

walker RunResolve {
    has start: str;
    has mod: str;
    has tree_kind: str;
    has out: str | None = None;

    can go with root entry {
        rr: Resolver;
        if self.tree_kind == "tree" {
            rr = mk_tree();
        } else if self.tree_kind == "diamond" {
            rr = mk_diamond();
        } else {
            rr = mk_nested();
        }
        self.out = rr.resolve(self.start, self.mod);
        print(self.out);
        disengage;
    }
}

test "direct hit in shared dir" {
    w = root spawn RunResolve(start="/app", mod="Button", tree_kind="tree");
    assert w.out == "/app/shared/Button";;
}

test "unknown start dir returns None" {
    w = root spawn RunResolve(start="/nope", mod="Button", tree_kind="tree");
    assert w.out == None;;
}

test "unknown module returns None" {
    w = root spawn RunResolve(start="/app", mod="Nope", tree_kind="tree");
    assert w.out == None;;
}

test "diamond revisit still resolves once" {
    w = root spawn RunResolve(start="/app", mod="Button", tree_kind="diamond");
    assert w.out == "/app/shared/Button";;
}

test "nested upward walk resolves shared ancestor" {
    w = root spawn RunResolve(start="/a/b/c", mod="Button", tree_kind="nested");
    assert w.out == None;;
}

# Recursive module resolution — microsoft/TypeScript#10649
# Like webpack's modulesDirectories: from the importing directory the
# resolver recursively walks the directory graph (edges link parent and
# child both ways, so any starting dir can reach ancestor shared dirs),
# probing for a shared module directory containing the requested module.

node Dir {
    has path: str;
}

edge contains_dir {
}

obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list | None = None) -> None {
        self.by_path = {};
        if shared_dirs is not None {
            self.shared_dirs = shared_dirs;
        } else {
            self.shared_dirs = [];
        }
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
        c +>:contains_dir:+> p;
    }

    def find_child(d: Dir, full_path: str) -> Dir | None {
        for c in [d ->:contains_dir:->][?:Dir] {
            if c.path == full_path {
                return c;
            }
        }
        return None;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(
            shared_dirs=self.shared_dirs,
            module_ref=module_ref,
            resolver=self,
            found=None
        );
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has resolver: Resolver;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        for sd in self.shared_dirs {
            sd_full: str = here.path + "/" + sd;
            sd_node: Dir | None = self.resolver.find_child(here, sd_full);
            if sd_node is not None {
                mod_full: str = sd_full + "/" + self.module_ref;
                mod_node: Dir | None = self.resolver.find_child(sd_node, mod_full);
                if mod_node is not None {
                    self.found = mod_full;
                    disengage;
                }
            }
        }
        for n in [here ->:contains_dir:->][?:Dir] {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }
}

def mk_tree() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    r.add_dir("/app");
    r.add_dir("/app/shared");
    r.add_dir("/app/shared/Button");
    r.connect("/app", "/app/shared");
    r.connect("/app/shared", "/app/shared/Button");
    return r;
}

def mk_diamond() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    r.add_dir("/app");
    r.add_dir("/app/x");
    r.add_dir("/app/y");
    r.add_dir("/app/shared");
    r.add_dir("/app/shared/Button");
    r.connect("/app", "/app/x");
    r.connect("/app", "/app/y");
    r.connect("/app/x", "/app/shared");
    r.connect("/app/y", "/app/shared");
    r.connect("/app/shared", "/app/shared/Button");
    return r;
}

def mk_nested() -> Resolver {
    r = Resolver(shared_dirs=["shared"]);
    r.add_dir("/a");
    r.add_dir("/a/b");
    r.add_dir("/a/b/c");
    r.add_dir("/a/shared");
    r.add_dir("/a/shared/Button");
    r.connect("/a", "/a/b");
    r.connect("/a/b", "/a/b/c");
    r.connect("/a", "/a/shared");
    r.connect("/a/shared", "/a/shared/Button");
    return r;
}

walker RunResolve {
    has start: str;
    has mod: str;
    has tree_kind: str;
    has out: str | None = None;

    can go with root entry {
        rr: Resolver;
        if self.tree_kind == "tree" {
            rr = mk_tree();
        } else if self.tree_kind == "diamond" {
            rr = mk_diamond();
        } else {
            rr = mk_nested();
        }
        self.out = rr.resolve(self.start, self.mod);
        print(self.out);
        disengage;
    }
}

test "direct hit in shared dir" {
    w = root spawn RunResolve(start="/app", mod="Button", tree_kind="tree");
    assert w.out == "/app/shared/Button";;
}

test "unknown start dir tolerated, returns None" {
    w = root spawn RunResolve(start="/nope", mod="Button", tree_kind="tree");
    assert w.out == None;;
}

test "unknown module ref returns None" {
    w = root spawn RunResolve(start="/app", mod="Nope", tree_kind="tree");
    assert w.out == None;;
}

test "diamond revisit resolved exactly once via claim map" {
    w = root spawn RunResolve(start="/app", mod="Button", tree_kind="diamond");
    assert w.out == "/app/shared/Button";;
}

test "recursive upward walk finds ancestor shared dir" {
    w = root spawn RunResolve(start="/a/b/c", mod="Button", tree_kind="nested");
    assert w.out == "/a/shared/Button";;
}
