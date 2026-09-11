"""Guard: 0cwa/avbcompose#14."""

node ProjectNode { has name: str; has removed: bool = False; }
edge ChildOf {}

obj SourceGraph {
    has projects: dict[str, ProjectNode] = {};

    def add_project(name: str, parent: str | None = None) {
        if parent is not None and self.projects.get(parent, None) is None {
            raise KeyError("unknown parent project");
        }
        n = ProjectNode(name=name);
        root ++> n;
        self.projects[name] = n;
        if parent is not None {
            p = self.projects.get(parent, None);
            if p is not None { p +>:ChildOf:+> n; }
        }
    }

    def cascade_remove(project_id: str) -> list[str] {
        start = self.projects.get(project_id, None);
        if start is None { raise KeyError("unknown project"); }
        w = start spawn SubtreeCollect(claimed={}, found=[]);
        changed: list[str] = [];
        for pid in w.found {
            n = self.projects.get(pid, None);
            if n is None or n.removed { continue; }
            n.removed = True;
            changed.append(pid);
        }
        return sorted(changed);
    }

    def active_projects() -> list[str] {
        out: list[str] = [];
        for k in self.projects.keys() {
            n = self.projects.get(k, None);
            if n is not None and not n.removed { out.append(k); }
        }
        return sorted(out);
    }
}

walker SubtreeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with ProjectNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:ChildOf:->] else { disengage; };
    }
}

test "cascade remove prunes subtree" {
    g = SourceGraph();
    g.add_project("manifest");
    g.add_project("device", parent="manifest");
    g.add_project("vendor", parent="manifest");
    g.add_project("hal", parent="device");
    g.add_project("app", parent="vendor");
    assert g.active_projects() == ["app", "device", "hal", "manifest", "vendor"];
    assert g.cascade_remove("device") == ["device", "hal"];
    assert g.active_projects() == ["app", "manifest", "vendor"];
}

test "second cascade remove" {
    g = SourceGraph();
    g.add_project("manifest");
    g.add_project("device", parent="manifest");
    g.add_project("vendor", parent="manifest");
    g.add_project("hal", parent="device");
    g.add_project("app", parent="vendor");
    g.cascade_remove("device");
    assert g.cascade_remove("vendor") == ["app", "vendor"];
    assert g.active_projects() == ["manifest"];
}

test "deep cascade" {
    d = SourceGraph();
    for i in range(5) {
        parent = ("p%d" % (i - 1)) if i > 0 else None;
        d.add_project("p%d" % i, parent=parent);
    }
    assert d.cascade_remove("p2") == ["p2", "p3", "p4"];
}

test "cycle once only collect" {
    c = SourceGraph();
    c.add_project("a");
    c.add_project("b", parent="a");
    c.projects["a"] +>:ChildOf:+> c.projects["b"];
    c.projects["b"] +>:ChildOf:+> c.projects["a"];
    w = c.projects["a"] spawn SubtreeCollect(claimed={}, found=[]);
    assert sorted(w.found) == ["a", "b"];
}

test "unknown project raises" {
    g = SourceGraph();
    try {
        g.cascade_remove("ghost");
        assert False;
    } except KeyError {
        assert True;
    }
}
