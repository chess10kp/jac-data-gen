"""Transitive dependency audit — modelcontextprotocol/typescript-sdk#2042."""

node DepGraph {
    has pkgs: dict[str, Pkg] = {};
}

node Pkg {
    has name: str;
    has version: str;
    has severity: str = "none";
}

edge Depends {}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can collect with Pkg entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        print here.name;
        kids: list[Pkg] = [];
        for ch in [here ->:Depends:->][?:Pkg] {
            kids.append(ch);
        }
        visit kids;
    }
}

walker PathWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has parent_of: dict[str, str] = {};
    has found: list[str] = [];

    can walk with Pkg entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name == self.target {
            chain: list[str] = [];
            cur: str = self.target;
            while cur != "" {
                chain.append(cur);
                if cur in self.parent_of {
                    cur = self.parent_of[cur];
                } else {
                    cur = "";
                }
            }
            self.found = reverse_list(chain);
            print self.found;
            disengage;
        }
        kids: list[Pkg] = [];
        for ch in [here ->:Depends:->][?:Pkg] {
            if not (ch.name in self.claimed) {
                self.parent_of[ch.name] = here.name;
            }
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        } else {
            visit :0: kids;
        }
    }
}

walker AuditDemo {
    can run with DepGraph entry {
        rn = seed_sdk_vuln_graph(here);
        fails = audit_fails(here, rn, "high");
        print fails;
        disengage;
    }
}

def reverse_list(xs: list[str]) -> list[str] {
    rev: list[str] = [];
    i = len(xs) - 1;
    while i >= 0 {
        rev.append(xs[i]);
        i = i - 1;
    }
    return rev;
}

def severity_rank(sev: str) -> int {
    if sev == "high" {
        return 2;
    }
    if sev == "moderate" {
        return 1;
    }
    return 0;
}

def audit_threshold(level: str) -> int {
    if level == "high" {
        return 2;
    }
    if level == "moderate" {
        return 1;
    }
    return 0;
}

def new_graph -> DepGraph {
    g = DepGraph(pkgs={});
    root ++> g;
    return g;
}

def get_pkg(g: DepGraph, name: str) -> Pkg | None {
    if name in g.pkgs {
        return g.pkgs[name];
    }
    return None;
}

def add_package(g: DepGraph, name: str, version: str, severity: str) -> None {
    p = Pkg(name=name, version=version, severity=severity);
    g.pkgs[name] = p;
}

def add_dependency(g: DepGraph, parent: str, child: str) -> None {
    pp = get_pkg(g, parent);
    cc = get_pkg(g, child);
    if pp == None {
        return;
    }
    if cc == None {
        return;
    }
    pp +>:Depends:+> cc;
}

def seed_sdk_vuln_graph(g: DepGraph) -> str {
    root_name = "@modelcontextprotocol/sdk";
    add_package(g, root_name, "1.29.0", "none");
    add_package(g, "ajv", "8.18.0", "none");
    add_package(g, "fast-uri", "3.1.0", "high");
    add_package(g, "hono", "4.12.14", "moderate");
    add_package(g, "@hono/node-server", "1.19.14", "none");
    add_package(g, "express-rate-limit", "8.4.0", "moderate");
    add_package(g, "ip-address", "10.1.0", "moderate");
    add_dependency(g, root_name, "ajv");
    add_dependency(g, "ajv", "fast-uri");
    add_dependency(g, root_name, "hono");
    add_dependency(g, root_name, "@hono/node-server");
    add_dependency(g, "@hono/node-server", "hono");
    add_dependency(g, root_name, "express-rate-limit");
    add_dependency(g, "express-rate-limit", "ip-address");
    return root_name;
}

def transitive_dependencies(g: DepGraph, root_name: str) -> list[str] {
    rp = get_pkg(g, root_name);
    if rp == None {
        return [];
    }
    w = rp spawn CollectWalker();
    out: list[str] = [];
    for nm in w.names {
        if nm != root_name {
            out.append(nm);
        }
    }
    return sorted(out);
}

def failing_packages(g: DepGraph, root_name: str, audit_level: str) -> list[str] {
    thr = audit_threshold(audit_level);
    deps = transitive_dependencies(g, root_name);
    out: list[str] = [];
    for nm in deps {
        p = g.pkgs[nm];
        if severity_rank(p.severity) >= thr {
            out.append(nm);
        }
    }
    return sorted(out);
}

def audit_fails(g: DepGraph, root_name: str, audit_level: str) -> bool {
    fps = failing_packages(g, root_name, audit_level);
    return len(fps) > 0;
}

def dependency_path(g: DepGraph, root_name: str, target_name: str) -> list[str] {
    if root_name == target_name {
        if get_pkg(g, root_name) == None {
            return [];
        }
        return [root_name];
    }
    rp = get_pkg(g, root_name);
    tp = get_pkg(g, target_name);
    if rp == None {
        return [];
    }
    if tp == None {
        return [];
    }
    w = rp spawn PathWalker(target=target_name);
    return w.found;
}

with entry {
    g = new_graph();
    g spawn AuditDemo();
}
