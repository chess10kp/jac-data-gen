node Package {
    has ident: str;
    has module_present: bool = True;
    has api_claim: bool = True;
    has docs_claim: bool = True;
    has cargo_claim: bool = True;
}

node Consumer {
    has ident: str;
    has disposition: str;
}

edge Depends {}
edge Uses {}

walker DependencyClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Package entry {
        if here.ident in self.claimed {
            skip;
        }
        self.claimed[here.ident] = True;
        self.found.append(here.ident);
        print(here.ident);
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

walker ConsumerAudit {
    has claimed: dict[str, bool] = {};
    has status: dict[str, str] = {};
    has unresolved: list[str] = [];

    can inspect_package with Package entry {
        key = "p:" + here.ident;
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        print(here.ident);
        for consumer in [here ->:Uses:->][?:Consumer] {
            visit :0: [consumer];
        }
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }

    can inspect_consumer with Consumer entry {
        key = "c:" + here.ident;
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        self.status[here.ident] = here.disposition;
        print(here.ident);
        if here.disposition != "self-test"
            and here.disposition != "covered"
            and here.disposition != "migrated" {
            self.unresolved.append(here.ident);
        }
    }
}

def make_package(name: str) -> Package {
    return Package(ident=name);
}

def add_dependency(source: Package, target: Package) -> None {
    source +>:Depends:+> target;
}

def add_consumer(package: Package, consumer_id: str, disposition: str) -> Consumer {
    consumer = Consumer(ident=consumer_id, disposition=disposition);
    package +>:Uses:+> consumer;
    return consumer;
}

def dependency_closure(root_node: Package) -> list[str] {
    w = root_node spawn DependencyClosure(claimed={});
    return sorted(w.found);
}

def consumer_status(root_node: Package, consumer_id: str) -> str {
    w = root_node spawn ConsumerAudit(claimed={});
    if consumer_id in w.status {
        return w.status[consumer_id];
    }
    return "unknown";
}

def delete_governance(root_node: Package, ruling: str) -> bool {
    w = root_node spawn ConsumerAudit(claimed={});
    if ruling != "delete" {
        return False;
    }
    if len(w.unresolved) != 0 {
        return False;
    }
    root_node.module_present = False;
    root_node.api_claim = False;
    root_node.docs_claim = False;
    root_node.cargo_claim = False;
    return True;
}

def governance_state(package: Package) -> list[str] {
    state: list[str] = [];
    if package.module_present {
        state.append("module");
    }
    if package.api_claim {
        state.append("api");
    }
    if package.docs_claim {
        state.append("docs");
    }
    if package.cargo_claim {
        state.append("cargo");
    }
    return state;
}
