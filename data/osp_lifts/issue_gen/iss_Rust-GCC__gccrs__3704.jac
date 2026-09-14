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
