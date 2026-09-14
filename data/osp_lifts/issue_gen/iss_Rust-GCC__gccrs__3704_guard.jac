# Rust-GCC/gccrs#3704: recursive call traversal over nested package structures.

node Package {
    has name: str;
}

node Routine {
    has rid: str;
}

edge Contains {}
edge Defines {}
edge Calls {}

walker CallClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Routine entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.found.append(here.rid);
        print(here.rid);
        for callee in [here ->:Calls:->][?:Routine] {
            visit :0: [callee];
        }
    }
}

walker FindRoutine {
    has wanted: str = "";
    has claimed_packages: dict[str, bool] = {};
    has result: str = "";

    can scan_package with Package entry {
        if here.name in self.claimed_packages {
            skip;
        }
        self.claimed_packages[here.name] = True;
        print(here.name);
        for child in [here ->:Contains:->][?:Package] {
            visit :0: [child];
        }
        for routine in [here ->:Defines:->][?:Routine] {
            visit :0: [routine];
        }
    }

    can scan_routine with Routine entry {
        print(here.rid);
        if here.rid == self.wanted {
            self.result = here.rid;
        }
    }
}

def build_package(name: str) -> Package {
    return Package(name=name);
}

def nest_package(parent: Package, child: Package) -> None {
    parent +>:Contains:+> child;
}

def add_routine(package: Package, routine_id: str) -> Routine {
    routine = Routine(rid=routine_id);
    package +>:Defines:+> routine;
    return routine;
}

def add_call(caller: Routine, callee: Routine) -> None {
    caller +>:Calls:+> callee;
}

def call_closure(start: Routine) -> list[str] {
    w = start spawn CallClosure();
    return w.found;
}

def find_routine(package: Package, routine_id: str) -> str {
    w = package spawn FindRoutine(wanted=routine_id);
    return w.result;
}

test "diamond revisit with recursive back edge" {
    package = build_package("compiler");
    a = add_routine(package, "a");
    b = add_routine(package, "b");
    c = add_routine(package, "c");
    d = add_routine(package, "d");
    add_call(a, b);
    add_call(a, c);
    add_call(b, d);
    add_call(c, d);
    add_call(d, a);
    assert (sorted(call_closure(a)) == ["a", "b", "c", "d"]);
}

test "unknown routine is tolerated" {
    package = build_package("empty");
    assert (find_routine(package, "missing") == "");
}

test "self recursive routine is visited once" {
    package = build_package("recursive");
    loop = add_routine(package, "loop");
    add_call(loop, loop);
    assert (call_closure(loop) == ["loop"]);
}

test "nested package lookup handles package cycle" {
    outer = build_package("outer");
    inner = build_package("inner");
    nest_package(outer, inner);
    nest_package(inner, outer);
    add_routine(inner, "nested_entry");
    assert (find_routine(outer, "nested_entry") == "nested_entry");
}

test "isolated routine closure" {
    package = build_package("single");
    only = add_routine(package, "only");
    assert (call_closure(only) == ["only"]);
}
