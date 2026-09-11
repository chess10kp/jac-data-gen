"""guardian/giant#744 — Workspace lazy-loading tree with expand-on-demand tracking."""
import from __future__ { annotations }
class WorkspaceTree {
    def init(self: WorkspaceTree) -> None {
        self._parent_of: dict[(str, (str | None))] = {};
        self._children_of: dict[(str, list[str])] = {};
        self._loaded: set[str] = `set();
        self._expandable: dict[(str, bool)] = {};
    }
}
def load_workspace(folders: list[tuple[(str, (str | None), bool)]]) -> WorkspaceTree {
    tree = WorkspaceTree();
    for (name, parent, has_children) in folders {
        if ((parent is not None) and (parent not in tree._parent_of)) {
            raise KeyError("unknown parent folder");
        }
        tree._parent_of[name] = parent;
        tree._children_of.setdefault(name, []);
        tree._expandable[name] = has_children;
        if (parent is not None) {
            tree._children_of.setdefault(parent, []).append(name);
        }
    }
    return tree;
}
def mark_loaded(tree: WorkspaceTree, folder_ids: list[str]) -> list[str] {
    newly: list[str] = [];
    for fid in folder_ids {
        if ((fid in tree._parent_of) and (fid not in tree._loaded)) {
            tree._loaded.add(fid);
            newly.append(fid);
        }
    }
    return sorted(newly);
}
def expandable_folders(tree: WorkspaceTree) -> list[str] {
    out: list[str] = [];
    for name in sorted(tree._parent_of) {
        if (tree._expandable.get(name) and (name not in tree._loaded)) {
            out.append(name);
        }
    }
    return out;
}
def loaded_children(tree: WorkspaceTree, folder: str) -> list[str] {
    if ((folder not in tree._parent_of) or (folder not in tree._loaded)) {
        return [];
    }
    return sorted(
        ch
        for ch in tree._children_of.get(folder, [])
        if (ch in tree._loaded)
    );
}
def ancestor_path(tree: WorkspaceTree, folder: str) -> list[str] {
    if (folder not in tree._parent_of) {
        return [];
    }
    chain: list[str] = [];
    cur: (str | None) = folder;
    seen: set[str] = `set();
    while (cur is not None) {
        if (cur in seen) {
            break;
        }
        seen.add(cur);
        chain.append(cur);
        cur = tree._parent_of.get(cur);
    }
    return `list(reversed(chain));
}

