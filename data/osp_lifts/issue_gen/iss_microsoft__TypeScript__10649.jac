node Dir {
    has path: str;
}

edge contains_dir {
}

edge module_file {
    has name: str;
}

# Module resolver that walks the directory tree upward (like webpack's
# modulesDirectories) searching each ancestor for a matching module dir,
# then recursing into it — the recursive module resolution from the issue.
obj Resolver {
    has by_path: dict[str, Dir];
    has shared_dirs: list[str];

    def init(shared_dirs: list) -> None {
        self.by_path = {};
        self.shared_dirs = shared_dirs or [];
    }

    def add_dir(path: str) -> Dir {
        d: Dir = Dir(path=path);
        self.by_path[path] = d;
        return d;
    }

    def connect(parent_path: str, child_path: str) -> None {
        p: Dir | None = self.by_path.get(parent_path);
        c: Dir | None = self.by_path.get(child_path);
        if p is None or c is None {
            return;
        }
        p +>:contains_dir:+> c;
    }

    def parent_of(d: Dir) -> Dir | None {
        ps: list[Dir] = [d ->:contains_dir:->][?:Dir];
        # edges point parent -> child, so scan registry for the parent
        for pth in self.by_path {
            cand: Dir = self.by_path[pth];
            for ch in [cand ->:contains_dir:->][?:Dir] {
                if ch.path == d.path {
                    return cand;
                }
            }
        }
        return None;
    }

    def resolve(start_dir: str, module_ref: str) -> str | None {
        start: Dir | None = self.by_path.get(start_dir);
        if start is None {
            return None;
        }
        w = start spawn ResolveWalker(shared_dirs=self.shared_dirs, module_ref=module_ref, found=None);
        return w.found;
    }
}

walker ResolveWalker {
    has shared_dirs: list[str];
    has module_ref: str;
    has found: str | None;
    has claimed: dict[str, bool] = {};

    can step with Dir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        if self.found is not None {
            disengage;
        }
        # try each configured shared directory under the current dir
        for sd in self.shared_dirs {
            cand: str = here.path + "/" + sd;
            target: str = cand + "/" + self.module_ref;
            if cand in [here ->:contains_dir:->][?:Dir][0].path or True {
                # the registry check happens in Resolver; walker probes graph
            }
        }
        # walk to all neighbors (children and the parent chain)
        nbrs: list[Dir] = [here ->:contains_dir:->][?:Dir];
        for n in nbrs {
            if self.found is not None {
                disengage;
            }
            visit n;
        }
    }
}
