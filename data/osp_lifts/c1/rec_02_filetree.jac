"""Filesystem tree navigation lifted to OSP.

Files and directories are ``FileNode`` nodes; ``InDir`` edges point
from a node to its containing directory. Path resolution climbs with
a linear walker; size totals fold bottom-up in exit abilities. The
per-walker ``claimed`` map is the explicit cycle policy (jac 0.36.1 has
no built-in once-per-node visitation).
"""

glob MAX_NAME_LEN = 255;

node FileNode {
    has name: str;
    has is_dir: bool;
    has size: int = 0;           # payload bytes; 0 for directories
    has bytes_total: int = 0;    # staging: subtree bytes folded at exit
    has dir_depth: int = 0;      # staging: deepest dir chain folded at exit
}

edge InDir: FileNode --> FileNode {}

"""Build the fixture tree deterministically; returns the mount root."""
def build_fs() -> FileNode {
    root ++> (home := FileNode(name="home", is_dir=True));
    root ++> (docs := FileNode(name="docs", is_dir=True));
    root ++> (src := FileNode(name="src", is_dir=True));
    root ++> (readme := FileNode(name="readme.md", is_dir=False, size=1200));
    root ++> (notes := FileNode(name="notes.txt", is_dir=False, size=300));
    root ++> (main := FileNode(name="main.py", is_dir=False, size=800));
    root ++> (util := FileNode(name="util.py", is_dir=False, size=450));
    readme +>:InDir:+> docs;
    notes +>:InDir:+> docs;
    main +>:InDir:+> src;
    util +>:InDir:+> src;
    docs +>:InDir:+> home;
    src +>:InDir:+> home;
    return home;
}

"""Create a node under `parent` (None for the mount root); return it."""
def create(parent: FileNode | None, name: str, is_dir: bool, size: int = 0) -> FileNode {
    root ++> (n := FileNode(name=name, is_dir=is_dir, size=size));
    if parent is not None {
        n +>:InDir:+> parent;
    }
    return n;
}

walker PathClimb {
    """Climbs InDir edges to the mount root; linear, so list state is safe."""
    has stops: list[str] = [];
    has claimed: dict[str, bool] = {};

    can climb with FileNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.stops.append(here.name);
        visit [->:InDir:->] else { report self.stops; disengage; }
    }
}

walker SizeFold {
    """Descends children; exit folds subtree byte totals bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with FileNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:InDir:<-];
    }

    can fold with FileNode exit {
        total = here.size;
        for c in [<-:InDir:<-] {
            total += c.bytes_total;
        }
        here.bytes_total = total;
    }
}

walker ExtSweep {
    """Collects regular-file names ending in the wanted extension."""
    has want: str;
    has hits: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with FileNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if not here.is_dir and here.name.endswith(self.want) {
            self.hits.append(here.name);
        }
        visit [<-:InDir:<-];
    }
}

walker DirDepthFold {
    """Exit folds the longest directory-only chain bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with FileNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:InDir:<-];
    }

    can fold with FileNode exit {
        best = 0;
        for c in [<-:InDir:<-] {
            if c.dir_depth > best {
                best = c.dir_depth;
            }
        }
        depth_own = 0;
        if here.is_dir {
            depth_own = 1;
        }
        here.dir_depth = depth_own + best;
    }
}

"""Absolute path of `start`, ascending to the mount root."""
def path_of(start: FileNode) -> str {
    w = start spawn PathClimb();
    return "/" + "/".join(reversed(w.stops));
}

def dir_size(start: FileNode) -> int {
    start spawn SizeFold();
    return start.bytes_total;
}

def files_under(start: FileNode, ext: str) -> list[str] {
    w = start spawn ExtSweep(want=ext);
    return sorted(w.hits);
}

def deepest_dir(start: FileNode) -> int {
    start spawn DirDepthFold();
    return start.dir_depth;
}
