"""Dependency graph and impact analysis foundation, lifted to OSP.

Files, components, tasks, and tests become node archetypes; ownership,
dependence, and coverage become typed PartOf / DependsOn / Covers edges.
The chained reverse sweeps over dict-of-lists become a single walker over
typed edges: from each changed file it follows PartOf forward to the
owning components, then reverse DependsOn to every task depending on them,
then reverse Covers to the covering tests. The per-archetype claim map is
the cycle policy for diamonds (a task depending on two impacted components
is reached twice and reported once). A changed file owned by no component
dead-ends immediately, exactly like the source sweep.
Ref: thomascarter613/monad-workspace#165
"""
node File {
    has name: str;
}
node Component {
    has name: str;
}
node Task {
    has name: str;
}
node TestNode {
    has name: str;
}
edge PartOf {}
edge DependsOn {}
edge Covers {}

"""Loader handle: entity names resolve through these lookup maps."""
obj Model {
    has files: dict[str, File];
    has comps: dict[str, Component];
    has tasks: dict[str, Task];
    has tests: dict[str, TestNode];

    def resolve_file(name: str) -> File | None {
        return self.files.get(name);
    }
}

"""Deterministic fresh-graph builder from the {kind: {name: [rels]}} model."""
def load_model(model: dict) -> Model {
    m = Model(files={}, comps={}, tasks={}, tests={});
    comps_map: dict[str, list[str]] = model.get("components", {});
    tasks_map: dict[str, list[str]] = model.get("tasks", {});
    tests_map: dict[str, list[str]] = model.get("tests", {});
    for comp in comps_map.keys() {
        c = Component(name=comp);
        root ++> c;
        m.comps[comp] = c;
    }
    for comp in comps_map.keys() {
        owner = m.comps[comp];
        for fname in comps_map[comp] {
            f = m.resolve_file(fname);
            if f is None {
                f = File(name=fname);
                root ++> f;
                m.files[fname] = f;
            }
            f +>:PartOf:+> owner;
        }
    }
    for task in tasks_map.keys() {
        t = Task(name=task);
        root ++> t;
        m.tasks[task] = t;
        for dep in tasks_map[task] {
            dc = m.comps.get(dep);
            if dc is not None {
                t +>:DependsOn:+> dc;
            }
        }
    }
    for tst in tests_map.keys() {
        e = TestNode(name=tst);
        root ++> e;
        m.tests[tst] = e;
        for covered in tests_map[tst] {
            tk = m.tasks.get(covered);
            if tk is not None {
                e +>:Covers:+> tk;
            }
        }
    }
    return m;
}

"""Ripple walker: file -> components -> depending tasks -> covering tests."""
walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has comps: list[str] = [];
    has tasks: list[str] = [];
    has tests: list[str] = [];

    can on_file with File entry {
        # Cycle policy: one visit per file regardless of path count.
        if "f:" + here.name in self.claimed {
            skip;
        }
        self.claimed["f:" + here.name] = True;
        visit [->:PartOf:->];
    }

    can on_component with Component entry {
        if "c:" + here.name in self.claimed {
            skip;
        }
        self.claimed["c:" + here.name] = True;
        if here.name not in self.comps {
            self.comps.append(here.name);
        }
        visit [<-:DependsOn:<-];
    }

    can on_task with Task entry {
        if "t:" + here.name in self.claimed {
            skip;
        }
        self.claimed["t:" + here.name] = True;
        if here.name not in self.tasks {
            self.tasks.append(here.name);
        }
        visit [<-:Covers:<-];
    }

    can on_test with TestNode entry {
        if "e:" + here.name in self.claimed {
            skip;
        }
        self.claimed["e:" + here.name] = True;
        if here.name not in self.tests {
            self.tests.append(here.name);
        }
    }
}

"""Changed-file impact analysis: impacted components, tasks, and tests."""
def impacted(model: dict, changed_files: list) -> dict {
    m = load_model(model);
    comps: list[str] = [];
    tasks: list[str] = [];
    tests: list[str] = [];
    for fname in changed_files {
        f = m.resolve_file(fname);
        if f is None {
            continue;  # owned by no component: no impact, like the source
        }
        w = f spawn ImpactWalk(claimed={}, comps=[], tasks=[], tests=[]);
        for c in w.comps {
            if c not in comps {
                comps.append(c);
            }
        }
        for t in w.tasks {
            if t not in tasks {
                tasks.append(t);
            }
        }
        for e in w.tests {
            if e not in tests {
                tests.append(e);
            }
        }
    }
    return {"components": sorted(comps), "tasks": sorted(tasks), "tests": sorted(tests)};
}

"""Recommended verification for a change: tests covering impacted tasks."""
def recommend_tests(model: dict, changed_files: list) -> list {
    return impacted(model, changed_files)["tests"];
}


test "full ripple from one changed file" {
    model = {
        "components": {
            "web": ["src/a.py", "src/b.py"],
            "core": ["lib/c.py"],
            "docs": ["docs/readme.md"],
        },
        "tasks": {
            "build": ["web", "core"],
            "test-web": ["web"],
            "publish-docs": ["docs"],
        },
        "tests": {
            "e2e-web": ["test-web"],
            "unit-build": ["build"],
            "docs-lint": ["publish-docs"],
        },
    };
    res = impacted(model, ["src/a.py"]);
    assert res == {"components": ["web"], "tasks": ["build", "test-web"], "tests": ["e2e-web", "unit-build"]};
}

test "multiple changed files union their blast radii" {
    model = {
        "components": {
            "web": ["src/a.py", "src/b.py"],
            "core": ["lib/c.py"],
            "docs": ["docs/readme.md"],
        },
        "tasks": {
            "build": ["web", "core"],
            "test-web": ["web"],
            "publish-docs": ["docs"],
        },
        "tests": {
            "e2e-web": ["test-web"],
            "unit-build": ["build"],
            "docs-lint": ["publish-docs"],
        },
    };
    res = impacted(model, ["src/a.py", "lib/c.py"]);
    assert res == {"components": ["core", "web"], "tasks": ["build", "test-web"], "tests": ["e2e-web", "unit-build"]};
}

test "recommend_tests is the verification slice" {
    model = {
        "components": {"web": ["src/a.py"], "docs": ["docs/readme.md"]},
        "tasks": {"build": ["web"], "publish-docs": ["docs"]},
        "tests": {"unit-build": ["build"], "docs-lint": ["publish-docs"]},
    };
    assert recommend_tests(model, ["docs/readme.md"]) == ["docs-lint"];
    assert recommend_tests(model, ["src/a.py"]) == ["unit-build"];
}

test "diamond ownership reports shared targets once" {
    diamond = {
        "components": {"api": ["shared.py"], "cli": ["shared.py"]},
        "tasks": {"build-cli": ["cli"], "build-all": ["api", "cli"]},
        "tests": {"t-all": ["build-all"], "t-cli": ["build-cli"]},
    };
    res = impacted(diamond, ["shared.py"]);
    assert res == {
        "components": ["api", "cli"],
        "tasks": ["build-all", "build-cli"],
        "tests": ["t-all", "t-cli"],
    };
}

test "tasks on unimpacted components stay out" {
    model = {
        "components": {"web": ["src/a.py"], "docs": ["docs/readme.md"]},
        "tasks": {"build": ["web"], "publish-docs": ["docs"]},
        "tests": {"unit-build": ["build"], "docs-lint": ["publish-docs"]},
    };
    res = impacted(model, ["docs/readme.md"]);
    assert res == {"components": ["docs"], "tasks": ["publish-docs"], "tests": ["docs-lint"]};
}

test "unowned file and empty change set impact nothing" {
    model = {
        "components": {"web": ["src/a.py"]},
        "tasks": {"build": ["web"]},
        "tests": {"unit-build": ["build"]},
    };
    res = impacted(model, ["orphan.rs"]);
    assert res == {"components": [], "tasks": [], "tests": []};
    assert recommend_tests(model, ["orphan.rs"]) == [];
    res = impacted(model, []);
    assert res == {"components": [], "tasks": [], "tests": []};
}
