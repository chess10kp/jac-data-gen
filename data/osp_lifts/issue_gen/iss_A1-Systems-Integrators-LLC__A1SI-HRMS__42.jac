"""A1-Systems-Integrators-LLC/A1SI-HRMS#42 — Project tree archive and descendants."""

obj ProjectStore {
    has projects: dict[str, Project] = {};
}

node Project {
    has pid: str;
    has active: bool = True;
}

edge ChildOf {}

def load_projects(
    projects: list[str],
    parent_edges: list[tuple[str, str]],
) -> ProjectStore {
    store = ProjectStore();
    for pid in projects {
        if pid not in store.projects {
            nd = Project(pid=pid);
            root ++> nd;
            store.projects[pid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = store.projects.get(parent, None);
        c = store.projects.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    return store;
}

def get_descendants(store: ProjectStore, project_id: str) -> list[str] {
    anchor = store.projects.get(project_id, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {project_id: True};
    snap: list[str] = [];
    for ch in [anchor ->:ChildOf:->][?:Project] {
        if ch.pid not in claimed {
            claimed[ch.pid] = True;
            snap.append(ch.pid);
        }
    }
    i = 0;
    while i < len(snap) {
        pid = snap[i];
        i += 1;
        nd = store.projects.get(pid, None);
        if nd is None { continue; }
        for ch in [nd ->:ChildOf:->][?:Project] {
            if ch.pid not in claimed {
                claimed[ch.pid] = True;
                snap.append(ch.pid);
            }
        }
    }
    out: list[str] = [];
    for pid in claimed.keys() {
        if pid != project_id { out.append(pid); }
    }
    return sorted(out);
}

def child_count(store: ProjectStore, project_id: str) -> int {
    anchor = store.projects.get(project_id, None);
    if anchor is None { return 0; }
    return len([anchor ->:ChildOf:->][?:Project]);
}

def archive_project(store: ProjectStore, project_id: str) -> list[str] {
    if project_id not in store.projects { return []; }
    targets = sorted([project_id] + get_descendants(store, project_id));
    for pid in targets {
        nd = store.projects.get(pid, None);
        if nd is not None { nd.active = False; }
    }
    return targets;
}

def active_projects(store: ProjectStore) -> list[str] {
    out: list[str] = [];
    for pid in sorted(store.projects.keys()) {
        if store.projects[pid].active { out.append(pid); }
    }
    return out;
}
