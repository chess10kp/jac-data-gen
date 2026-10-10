import from deps { Package, DependsOn, TransitiveDeps, InstallOrder }

def p(n: str) -> Package {
    return Package(name=n);
}

def dep(a: Package, b: Package) {
    a +>:DependsOn:+> b;
}

test "package with no dependencies" {
    solo = p("solo");
    t = solo spawn TransitiveDeps();
    assert len(t.reports) == 1;
    assert len(t.reports[0]) == 0;
    o = solo spawn InstallOrder();
    assert len(o.reports) == 1;
    assert list(o.reports[0]) == ["solo"];
}

test "chain transitive deps and order" {
    a = p("a");
    b = p("b");
    c = p("c");
    dep(a, b);
    dep(b, c);
    assert list((a spawn TransitiveDeps()).reports[0]) == ["b", "c"];
    assert list((a spawn InstallOrder()).reports[0]) == ["c", "b", "a"];
    assert list((b spawn TransitiveDeps()).reports[0]) == ["c"];
}

test "diamond counts the shared dependency once" {
    app = p("app");
    web = p("web");
    db = p("db");
    log = p("log");
    dep(app, web);
    dep(app, db);
    dep(web, log);
    dep(db, log);
    assert list((app spawn TransitiveDeps()).reports[0]) == ["db", "log", "web"];
    assert list((app spawn InstallOrder()).reports[0]) == ["log", "web", "db", "app"];
}

test "ties are broken alphabetically" {
    root_pkg = p("main");
    for n in ["zeta", "alpha", "mu"] {
        dep(root_pkg, p(n));
    }
    assert list((root_pkg spawn InstallOrder()).reports[0]) == ["alpha", "mu", "zeta", "main"];
    assert list((root_pkg spawn TransitiveDeps()).reports[0]) == ["alpha", "mu", "zeta"];
}

test "newly ready packages queue behind already ready ones" {
    top = p("top");
    x = p("x");
    b = p("b");
    a = p("a");
    dep(top, x);
    dep(top, b);
    dep(x, a);
    assert list((top spawn InstallOrder()).reports[0]) == ["a", "b", "x", "top"];
}

test "cycle is reported" {
    a = p("a");
    b = p("b");
    c = p("c");
    dep(a, b);
    dep(b, c);
    dep(c, a);
    assert (a spawn InstallOrder()).reports[0] == "CYCLE";
    assert list((a spawn TransitiveDeps()).reports[0]) == ["b", "c"];
}

test "cycle below the start is also reported" {
    top = p("top");
    a = p("a");
    b = p("b");
    dep(top, a);
    dep(a, b);
    dep(b, a);
    assert (top spawn InstallOrder()).reports[0] == "CYCLE";
}

test "only the reachable subgraph is ordered" {
    a = p("a");
    b = p("b");
    other = p("other");
    dep(a, b);
    dep(other, a);
    assert list((a spawn InstallOrder()).reports[0]) == ["b", "a"];
}
