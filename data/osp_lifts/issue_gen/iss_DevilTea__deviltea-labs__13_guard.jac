"""Guard: DevilTea/deviltea-labs#13."""

obj WidgetGraph { has widgets: dict[str, Widget] = {}; }
node Widget { has wid: str; }
edge DependsOn {}

walker BlockerWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    can step with Widget entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        self.chain.append(here.wid);
        parents = [here <-:DependsOn:<-][?:Widget];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.wid < pick.wid { pick = p; }
        }
        visit [pick];
    }
}

def load_widget_graph(
    widgets: list[str],
    depends: list[tuple[str, str]],
) -> WidgetGraph {
    g = WidgetGraph();
    for wid in widgets {
        if wid not in g.widgets {
            nd = Widget(wid=wid);
            root ++> nd;
            g.widgets[wid] = nd;
        }
    }
    for (parent, child) in depends {
        p = g.widgets.get(parent, None);
        c = g.widgets.get(child, None);
        if p is not None and c is not None { p +>:DependsOn:+> c; }
    }
    return g;
}

def transitive_deps(g: WidgetGraph, widget_id: str) -> list[str] {
    if widget_id not in g.widgets { return []; }
    claimed: dict[str, bool] = {widget_id: True};
    snap: list[str] = [widget_id];
    i = 0;
    while i < len(snap) {
        wid = snap[i];
        i += 1;
        anchor = g.widgets.get(wid, None);
        if anchor is None { continue; }
        for dep in [anchor ->:DependsOn:->][?:Widget] {
            if dep.wid not in claimed {
                claimed[dep.wid] = True;
                snap.append(dep.wid);
            }
        }
    }
    ids: list[str] = [];
    for wid in claimed.keys() { ids.append(wid); }
    ids.sort();
    return ids;
}

def compile_blockers(g: WidgetGraph, widget_id: str) -> list[str] {
    anchor = g.widgets.get(widget_id, None);
    if anchor is None { return []; }
    w = anchor spawn BlockerWalk(claimed={}, chain=[]);
    return w.chain;
}

test "survey widget dependency closure" {
    g = load_widget_graph(
        ["survey", "duration", "budget", "recommend"],
        [
            ("survey", "duration"),
            ("survey", "budget"),
            ("duration", "recommend"),
        ],
    );
    assert transitive_deps(g, "survey") == [
        "budget",
        "duration",
        "recommend",
        "survey",
    ];
    assert compile_blockers(g, "recommend") == ["recommend", "duration", "survey"];
    assert compile_blockers(g, "survey") == ["survey"];
}

test "diamond adversarial dependency revisit" {
    g = load_widget_graph(
        ["root", "left", "right", "leaf"],
        [("right", "leaf"), ("root", "left"), ("left", "leaf"), ("root", "right")],
    );
    assert transitive_deps(g, "root") == ["leaf", "left", "right", "root"];
}

test "cycle terminates compile blockers" {
    g = load_widget_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert compile_blockers(g, "a") == ["a", "c", "b"];
    assert transitive_deps(g, "b") == ["a", "b", "c"];
}

test "unknown widget tolerant" {
    g = load_widget_graph(["solo"], []);
    assert transitive_deps(g, "missing") == [];
    assert compile_blockers(g, "missing") == [];
}
