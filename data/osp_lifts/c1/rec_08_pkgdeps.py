"""Nested dependency lockfile (npm-style).

Installed packages nest exactly like on-disk ``node_modules``: each
dependency version lives under the single package that requires it,
so ``parent`` / ``deps`` pointers form a tree. The id registry is
public API state; ``resolve`` raises KeyError for unknown ids.
"""


class Package:
    def __init__(self, pid, version):
        self.pid = pid
        self.version = version
        self.parent = None       # Package | None (lockfile root)
        self.deps = []           # list[Package], nested dependencies


def register(registry, parent, pid, version):
    """Install ``pid`` under ``parent`` (None for root) and index it.

    Raises ValueError when ``pid`` is already registered.
    """
    if pid in registry:
        raise ValueError(f"duplicate package id: {pid}")
    pkg = Package(pid, version)
    registry[pid] = pkg
    if parent is not None:
        pkg.parent = parent
        parent.deps.append(pkg)
    return pkg


def resolve(registry, pid):
    """Look up a package by id; KeyError when absent (dangling ref)."""
    return registry[pid]


def install_path(pkg):
    """Nesting path of ``pkg``, root-first, segments joined by ' / '."""
    segs = []
    cur = pkg
    while cur is not None:
        segs.append(cur.pid)
        cur = cur.parent
    return " / ".join(reversed(segs))


def dep_tree_size(pkg):
    """Number of packages at or below ``pkg``, counting it."""
    return 1 + sum(dep_tree_size(d) for d in pkg.deps)


def versions_under(pkg, prefix):
    """Versions of packages under ``pkg`` whose pid starts with prefix."""
    found = []
    if pkg.pid.startswith(prefix):
        found.append(pkg.version)
    for d in pkg.deps:
        found.extend(versions_under(d, prefix))
    return sorted(found)
