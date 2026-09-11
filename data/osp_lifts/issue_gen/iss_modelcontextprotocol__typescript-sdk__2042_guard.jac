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

test "diamond revisit has once-only closure" {
    root = Package(name="sdk", version="1.29.0");
    left = Package(name="left", version="1.0.0");
    right = Package(name="right", version="1.0.0");
    shared = Package(name="shared", version="1.0.0");
    leaf = Package(name="leaf", version="1.0.0");
    root +>: Depends :+> left;
    root +>: Depends :+> right;
    left +>: Depends :+> shared;
    right +>: Depends :+> shared;
    shared +>: Depends :+> leaf;
    got = dependency_closure(root);
    assert (len(got) == 5);
    assert (shared in got);
    assert (leaf in got);
}

test "unknown package is tolerated" {
    root = Package(name="sdk", version="1.29.0");
    dep = Package(name="ajv", version="8.18.0");
    root +>: Depends :+> dep;
    got = find_package(root, "missing");
    assert (got == None);
}

test "vulnerability audit records fixed requirements" {
    root = Package(name="sdk", version="1.29.0");
    uri = Package(name="fast-uri", version="3.1.0", at_risk=True, fixed=">=3.1.2");
    hono = Package(name="hono", version="4.12.14", at_risk=True, fixed=">=4.12.18");
    root +>: Depends :+> uri;
    root +>: Depends :+> hono;
    findings = vulnerable_transitives(root);
    requirements = fixed_requirements(root);
    assert (len(findings) == 2);
    assert ("fast-uri" in findings);
    assert ("hono" in findings);
    assert (requirements["fast-uri"] == ">=3.1.2");
    assert (requirements["hono"] == ">=4.12.18");
}

test "leaf package has no transitive findings" {
    root = Package(name="sdk", version="1.29.0");
    got = dependency_closure(root);
    findings = vulnerable_transitives(root);
    assert (len(got) == 1);
    assert (got[0] == root);
    assert (len(findings) == 0);
}
