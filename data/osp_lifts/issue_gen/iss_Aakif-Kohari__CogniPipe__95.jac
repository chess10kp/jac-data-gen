"""Aakif-Kohari/CogniPipe#95 — Workflow dependsOn cycle detection."""

obj StepStore { has steps: dict[str, Step] = {}; }
node Step { has name: str; }
edge DependsOn {}

def load_steps(steps: list[tuple[str, list[str]]]) -> StepStore {
    store = StepStore();
    for (name, deps) in steps {
        if name not in store.steps {
            nd = Step(name=name);
            root ++> nd;
            store.steps[name] = nd;
        }
    }
    for (name, deps) in steps {
        src = store.steps.get(name, None);
        if src is None { continue; }
        for dep in deps {
            dst = store.steps.get(dep, None);
            if dst is not None { src +>:DependsOn:+> dst; }
        }
    }
    return store;
}

def detect_cycles(store: StepStore) -> list[str] {
    gray: dict[str, bool] = {};
    black: dict[str, bool] = {};
    cycles: list[str] = [];

    def dfs(name: str) -> None {
        if name in black { return; }
        if name in gray {
            cycles.append("Circular dependency: " + name);
            return;
        }
        gray[name] = True;
        nd = store.steps.get(name, None);
        if nd is not None {
            for nxt in [nd ->:DependsOn:->][?:Step] {
                dfs(nxt.name);
            }
        }
        del gray[name];
        black[name] = True;
    }

    for name in sorted(store.steps.keys()) {
        if name not in black { dfs(name); }
    }
    return cycles;
}
