"""0cwa/avbcompose#14 — Repo manifest source graph with cascade remove-project.

Manifest projects form a dependency tree; remove-project must cascade to
dependents. The store keeps parent pointers, a children adjacency dict, and
applies removals in two phases: collect the deletion set via stack walk, then
disconnect and purge outside the walk.
"""
import from __future__ { annotations }
class SourceGraph {
    def init(self: SourceGraph) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.children_of: dict[(str, list[str])] = {};
        self.removed: set[str] = `set();
    }
    def add_project(self: SourceGraph, name: str, parent: (str | None) = None) -> None {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent project");
        }
        self.parent_of[name] = parent;
        self.children_of.setdefault(name, []);
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(name);
        }
    }
    def _collect_subtree(self: SourceGraph, root_id: str) -> list[str] {
        stack = [root_id];
        seen: set[str] = `set();
        out: list[str] = [];
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            for ch in self.children_of.get(cur, []) {
                stack.append(ch);
            }
        }
        return out;
    }
    def cascade_remove(self: SourceGraph, project_id: str) -> list[str] {
        if (project_id not in self.parent_of) {
            raise KeyError("unknown project");
        }
        to_remove = self._collect_subtree(project_id);
        changed = [];
        for pid in to_remove {
            if (pid not in self.removed) {
                self.removed.add(pid);
                changed.append(pid);
            }
        }
        return sorted(changed);
    }
    def active_projects(self: SourceGraph) -> list[str] {
        return sorted(
            p
            for p in self.parent_of
            if (p not in self.removed)
        );
    }
}

