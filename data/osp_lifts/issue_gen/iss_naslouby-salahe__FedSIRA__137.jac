node Catalog {
    has experiments: list[Experiment] = [];
    has completed: dict[str, bool] = {};
}

node Experiment {
    has name: str;
    has cells: list[str] = [];
    has blocked: bool = False;
}

edge DependsOn {}

walker DependencyOrder {
    has catalog: Catalog;
    has target: str;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can start with entry {
        print("planning " + self.target);
        for exp in self.catalog.experiments {
            if exp.name == self.target {
                visit [exp];
            }
        }
    }

    can step with Experiment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for dep in [here ->:DependsOn:->][?:Experiment] {
            visit :0: [dep];
        }
        self.order.append(here.name);
    }
}

walker CellEnumerator {
    has catalog: Catalog;
    has target: str;
    has claimed: dict[str, bool] = {};
    has cells: list[str] = [];

    can start with entry {
        print("enumerating " + self.target);
        for exp in self.catalog.experiments {
            if exp.name == self.target {
                visit [exp];
            }
        }
    }

    can step with Experiment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for cell in here.cells {
            self.cells.append(cell);
        }
    }
}

def plan(catalog: Catalog, name: str) -> list[str] {
    walker: DependencyOrder = root spawn DependencyOrder;
    walker.catalog = catalog;
    walker.target = name;
    return walker.order;
}

def cells(catalog: Catalog, name: str) -> list[str] {
    walker: CellEnumerator = root spawn CellEnumerator;
    walker.catalog = catalog;
    walker.target = name;
    return walker.cells;
}

def run(catalog: Catalog, name: str) -> str {
    for exp in catalog.experiments {
        if exp.name == name {
            if exp.blocked {
                return "Invalid";
            }
            catalog.completed[name] = True;
            return "Completed";
        }
    }
    return "Unknown";
}

def completion(catalog: Catalog, name: str) -> int {
    if name in catalog.completed {
        if catalog.completed[name] {
            return 1;
        }
    }
    return 0;
}
