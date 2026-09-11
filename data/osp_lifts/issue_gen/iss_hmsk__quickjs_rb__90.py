"""JS-value to host-value conversion with ancestor-scoped cycle detection.

hmsk/quickjs.rb#90: converting nested values must reject genuine cycles
while preserving non-cyclic shared references -- the same object reachable
under several parents must materialize under each of them. The regression
described in the issue used one global ever-seen set, which nilled every
shared subobject after its first occurrence; the correct machinery tracks
only the ancestor path currently being converted. Reconstructed as an
in-memory value graph plus the hand-rolled recursive converter with
per-path bookkeeping.
"""


class CycleError(ValueError):
    """A value is its own ancestor: a genuine reference cycle."""


class ValueGraph:
    def __init__(self):
        self.objects = {}  # vid -> [(key, child_vid)] in insertion order
        self.scalars = {}  # vid -> primitive string

    def add_object(self, vid):
        if vid in self.objects or vid in self.scalars:
            raise ValueError("duplicate vid")
        self.objects[vid] = []

    def add_scalar(self, vid, val):
        if vid in self.objects or vid in self.scalars:
            raise ValueError("duplicate vid")
        self.scalars[vid] = val

    def add_prop(self, pid, key, cid):
        """Attach child cid under key on object pid."""
        if pid not in self.objects:
            raise KeyError(pid)
        if cid not in self.objects and cid not in self.scalars:
            raise KeyError(cid)
        self.objects[pid].append((key, cid))


def convert(graph, root):
    """Materialize the value tree rooted at root.

    Shared non-cyclic references appear fully under every parent; a value
    that is its own ancestor raises CycleError.
    """
    def walk(vid, ancestors):
        if vid in graph.objects:
            if vid in ancestors:
                raise CycleError("cyclic reference")
            out = {}
            for key, cid in graph.objects[vid]:  # nested lookup recursion
                out[key] = walk(cid, ancestors | {vid})
            return out
        if vid in graph.scalars:
            return graph.scalars[vid]
        raise KeyError(vid)

    return walk(root, frozenset())


def leaf_paths(graph, root):
    """Sorted "path=value" strings for every scalar materialization.

    A diamond makes the same leaf appear once per distinct root-to-leaf
    path; this is the observable that distinguishes per-path tracking from
    a global visited set.
    """
    paths = []

    def walk(vid, prefix, ancestors):
        if vid in graph.objects:
            if vid in ancestors:
                raise CycleError("cyclic reference")
            for key, cid in graph.objects[vid]:
                walk(cid, prefix + "/" + key, ancestors | {vid})
            return
        if vid in graph.scalars:
            paths.append(prefix + "=" + graph.scalars[vid])
            return
        raise KeyError(vid)

    walk(root, "", frozenset())
    return sorted(paths)
