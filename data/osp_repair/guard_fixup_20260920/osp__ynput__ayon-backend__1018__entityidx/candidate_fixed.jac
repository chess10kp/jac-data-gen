"""Project entity index: folder paths, inheritance and cross-type chains.

ynput/ayon-backend#1018 lifted to OSP: folders become FolderNode
archetypes with typed ChildFolder edges; the cross-type link maps become
typed HostsTask / OwnsProduct / HasVersion edges so the chain query is one
walk per hop. Path building and attribute inheritance are ascent walkers
with explicit claim-map cycle policy; subtree listing is a once-only
flood. Unknown-id tolerance follows the source: canonical_path("ghost")
-> "ghost", subtree_folders("ghost") -> ["ghost"], reads on missing ids
never raise. The single polymorphic ``attach_chain(task=/product=/version=)``
signature is preserved.
"""
node FolderNode {
    has name: str;
    has attrs_json: dict;
}
node TaskNode { has name: str; }
node ProductNode { has name: str; }
node VersionNode { has name: str; }

edge ChildFolder {}
edge HostsTask {}
edge OwnsProduct {}
edge HasVersion {}

"""Index handle: id resolution through these lookup maps is domain API."""
obj Index {
    has folders: dict[str, FolderNode];
    has tasks: dict[str, TaskNode] = {};
    has products: dict[str, ProductNode] = {};
    has versions: dict[str, VersionNode] = {};

    def resolve(name: str) -> FolderNode | None {
        return self.folders.get(name);
    }
}

def build_index(roots: list[str]) -> Index {
    ix = Index(folders={});
    for n in roots {
        f = FolderNode(name=n, attrs_json={});
        root ++> f;
        ix.folders[n] = f;
    }
    return ix;
}

def add_folder(ix: Index, name: str, parent: str | None = None, attrs: dict | None = None) {
    if parent is not None and ix.resolve(parent) is None {
        raise KeyError("unknown parent folder");
    }
    a: dict = {};
    if attrs is not None {
        a = attrs;
    }
    f = FolderNode(name=name, attrs_json=a);
    root ++> f;
    ix.folders[name] = f;
    if parent is not None {
        p = ix.resolve(parent);
        if p is not None {
            p +>:ChildFolder:+> f;
        }
    }
}

walker PathAscent {
    has visited: dict[str, bool];
    has parts: list[str] = [];

    can step with FolderNode entry {
        if here.name in self.visited {
            skip;  # corrupt cycles stop, never hang
        }
        self.visited[here.name] = True;
        self.parts.append(here.name);
        parents: list[FolderNode] = [here <-:ChildFolder:<-];
        if len(parents) == 0 {
            disengage;
        }
        visit [parents[0]];
    }
}

"""Canonical path from the ancestor chain; root segment first.

Unknown ids tolerate like the source: a lone segment of itself.
"""
def canonical_path(ix: Index, folder: str) -> str | None {
    f = ix.resolve(folder);
    if f is None {
        return folder;  # source: parts=[folder], no ancestors
    }
    w = f spawn PathAscent(visited={});
    segs: list[str] = [];
    i = len(w.parts) - 1;
    while i >= 0 {
        segs.append(w.parts[i]);
        i -= 1;
    }
    out = "";
    for s in segs {
        if len(out) > 0 {
            out += "/";
        }
        out += s;
    }
    return out;
}

walker SubtreeFlood {
    has claimed: dict[str, bool];
    has found: list[FolderNode] = [];

    can step with FolderNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here);
        visit [->:ChildFolder:->];
    }
}

def subtree_folders(ix: Index, root_name: str) -> list[str] {
    start = ix.resolve(root_name);
    if start is None {
        return [root_name];  # source tolerance: the unknown id itself
    }
    w = start spawn SubtreeFlood(claimed={});
    names: list[str] = [];
    for f in w.found {
        names.append(f.name);
    }
    return sorted(names);
}

walker InheritAscent {
    has attr: str;
    has visited: dict[str, bool];
    has value: Any = None;

    can step with FolderNode entry {
        if here.name in self.visited {
            skip;
        }
        self.visited[here.name] = True;
        if self.value is None and self.attr in here.attrs_json.keys() {
            self.value = here.attrs_json[self.attr];
        }
        parents: list[FolderNode] = [here <-:ChildFolder:<-];
        if len(parents) == 0 or self.value is not None {
            disengage;
        }
        visit [parents[0]];
    }
}

"""Nearest ancestor (or self) carrying ``attr``; None otherwise."""
def inherited_attribute(ix: Index, folder: str, attr: str) -> Any {
    f = ix.resolve(folder);
    if f is None {
        return None;
    }
    w = f spawn InheritAscent(attr=attr, visited={});
    return w.value;
}

"""Wire one link per call site; each hop validated (source signature)."""
def attach_chain(ix: Index, task: str | None = None,
                 product: tuple[str, str] | None = None,
                 version: tuple[str, str] | None = None,
                 folder: str | None = None) {
    if task is not None {
        if folder is None or ix.resolve(folder) is None {
            raise KeyError("unknown folder");
        }
        t = TaskNode(name=task);
        root ++> t;
        ix.folders[folder] +>:HostsTask:+> t;
        ix.tasks[task] = t;
    } elif product is not None {
        if product[1] not in ix.tasks.keys() {
            raise KeyError("unknown task");
        }
        p = ProductNode(name=product[0]);
        root ++> p;
        ix.tasks[product[1]] +>:OwnsProduct:+> p;
        ix.products[product[0]] = p;
    } elif version is not None {
        if version[1] not in ix.products.keys() {
            raise KeyError("unknown product");
        }
        v = VersionNode(name=version[0]);
        root ++> v;
        ix.products[version[1]] +>:HasVersion:+> v;
        ix.versions[version[0]] = v;
    }
}

"""Cross-type chain query: folders -> tasks -> products -> versions."""
def versions_in_subtree(ix: Index, root_name: str) -> list[str] {
    start = ix.resolve(root_name);
    if start is None {
        return [];  # nothing can live under an unknown folder
    }
    flood = start spawn SubtreeFlood(claimed={});
    vids: list[str] = [];
    for f in flood.found {
        tasks: list[TaskNode] = [f ->:HostsTask:->];
        for t in tasks {
            prods: list[ProductNode] = [t ->:OwnsProduct:->];
            for p in prods {
                vers: list[VersionNode] = [p ->:HasVersion:->];
                for v in vers {
                    vids.append(v.name);
                }
            }
        }
    }
    return sorted(vids);
}

def entities_of_type(ix: Index, etype: str, root_name: str | None = None) -> list[str] {
    # mixed-entity listing filtered to one type, optionally scoped
    if etype == "folder" {
        if root_name is not None {
            return subtree_folders(ix, root_name);
        }
        names: list[str] = [];
        for k in ix.folders.keys() {
            names.append(k);
        }
        return sorted(names);  # no root: all folder names
    }
    if etype == "task" {
        return sorted(ix.tasks.keys());
    }
    if etype == "product" {
        return sorted(ix.products.keys());
    }
    return sorted(ix.versions.keys());
}
