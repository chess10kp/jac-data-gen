// PROGRAM iss_modelcontextprotocol__typescript-sdk__2042.jac

node Package {
    has name: str;
    has version: str;
    has at_risk: bool = False;
    has fixed: str = "";
    has closure: list[Package] = [];
    has findings: list[str] = [];
    has requirements: dict[str, str] = {};
    has match: Package | None = None;
}

edge Depends {}

walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has origin: Package | None = None;

    can step with Package entry {
        if self.origin == None {
            self.origin = here;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.origin.closure.append(here);
        print(here.name);
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

walker AuditWalk {
    has claimed: dict[str, bool] = {};
    has origin: Package | None = None;

    can step with Package entry {
        if self.origin == None {
            self.origin = here;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.at_risk {
            self.origin.findings.append(here.name);
            self.origin.requirements[here.name] = here.fixed;
        }
        print(here.name);
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

walker FindWalk {
    has claimed: dict[str, bool] = {};
    has origin: Package | None = None;
    has target: str = "";

    can step with Package entry {
        if self.origin == None {
            self.origin = here;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name == self.target {
            self.origin.match = here;
        }
        print(here.name);
        for kid in [here ->:Depends:->][?:Package] {
            visit :0: [kid];
        }
    }
}

def dependency_closure(root: Package) -> list[Package] {
    root.closure = [];
    root spawn ClosureWalk;
    return root.closure;
}

def vulnerable_transitives(root: Package) -> list[str] {
    root.findings = [];
    root.requirements = {};
    root spawn AuditWalk;
    return root.findings;
}

def fixed_requirements(root: Package) -> dict[str, str] {
    root.findings = [];
    root.requirements = {};
    root spawn AuditWalk;
    return root.requirements;
}

def find_package(root: Package, wanted: str) -> Package | None {
    root.match = None;
    root spawn FindWalk(target=wanted);
    return root.match;
}
