"""0cwa/avbcompose#14 — Repo manifest source graph with cascade remove-project."""

node ProjectNode {
    has name: str;
    has removed: bool = False;
}

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
