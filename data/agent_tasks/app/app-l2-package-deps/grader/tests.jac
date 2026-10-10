import from deps { Package, DependsOn, TransitiveDeps, InstallOrder }

def pk(n: str) -> Package {
    return Package(name=n, version="1.0.0");
}

def valid_order(order: list[str], start: Package, pkgs: list[Package]) -> bool {
    names = [p.name for p in pkgs];
    if sorted(order) != sorted(names) or len(set(order)) != len(order) {
        return False;
    }
    if order[-1] != start.name {
        return False;
    }
    for p in pkgs {
        for d in [p ->:DependsOn:->] {
            if order.index(d.name) > order.index(p.name) {
                return False;
            }
        }
    }
    return True;
}

test "transitive deps with a diamond" {
    app = pk("app"); web = pk("web"); db = pk("db"); log = pk("log"); fmt = pk("fmt");
    app +>:DependsOn:+> web;
    app +>:DependsOn:+> db;
    web +>:DependsOn:+> log;
    db +>:DependsOn:+> log;
    log +>:DependsOn:+> fmt;
    r = app spawn TransitiveDeps();
    assert len(r.reports) == 1;
    assert r.reports[0] == ["db", "fmt", "log", "web"];
    assert (log spawn TransitiveDeps()).reports[0] == ["fmt"];
    assert len((fmt spawn TransitiveDeps()).reports[0]) == 0;
}

test "install order respects dependencies" {
    app = pk("app"); web = pk("web"); db = pk("db"); log = pk("log"); fmt = pk("fmt"); cli = pk("cli");
    app +>:DependsOn:+> web;
    app +>:DependsOn:+> db;
    app +>:DependsOn:+> cli;
    web +>:DependsOn:+> log;
    db +>:DependsOn:+> log;
    log +>:DependsOn:+> fmt;
    cli +>:DependsOn:+> fmt;
    r = app spawn InstallOrder();
    assert len(r.reports) == 1;
    assert valid_order(r.reports[0], app, [app, web, db, log, fmt, cli]), f"bad order {r.reports[0]}";
    r2 = web spawn InstallOrder();
    assert r2.reports[0] == ["fmt", "log", "web"];
}

test "single package installs alone" {
    solo = pk("solo");
    assert (solo spawn InstallOrder()).reports[0] == ["solo"];
}

test "cycle detected" {
    a = pk("a"); b = pk("b"); c = pk("c"); top = pk("top");
    top +>:DependsOn:+> a;
    a +>:DependsOn:+> b;
    b +>:DependsOn:+> c;
    c +>:DependsOn:+> a;
    assert (top spawn InstallOrder()).reports[0] == "CYCLE";
    assert (a spawn InstallOrder()).reports[0] == "CYCLE";
}

test "cycle elsewhere in graph does not matter" {
    a = pk("a"); b = pk("b"); x = pk("x"); y = pk("y");
    a +>:DependsOn:+> b;
    x +>:DependsOn:+> y;
    y +>:DependsOn:+> x;
    x +>:DependsOn:+> a;
    assert (a spawn InstallOrder()).reports[0] == ["b", "a"];
}
