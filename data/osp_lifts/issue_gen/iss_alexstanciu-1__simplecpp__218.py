"""Rebuild-fanout analysis for dependency-grouped generated units.

A source edit in a large strict project still fans out across hundreds
of generated objects because the project generates one broad unit:
every edit invalidates everything. The remediation decomposes the
project into generated units whose includes are tracked per unit, so a
body-only edit rebuilds only the units that (transitively) include the
edited source, plus the link.

The unit graph is kept as an adjacency map -- generated unit id -> the
source units it imports -- and ``affected`` answers "what rebuilds" by
walking the REVERSE adjacency (who imports me) breadth-first from the
changed sources with a visited set: import graphs can contain cycles,
and a unit reached through two import paths must still rebuild only
once. ``fanout`` is the size of that set -- the rebuild fanout the
edit would cause, the number the ``explain-build`` visibility wants to
make inspectable.
Ref: alexstanciu-1/simplecpp#218
"""


def _reverse_edges(units):
    """source unit -> the unit ids that import it (reverse adjacency)."""
    rev = {}
    for unit, imports in units.items():
        for src in imports:
            rev.setdefault(src, []).append(unit)
    return rev


def affected(units, changed):
    """Sorted ids of every unit transitively importing a changed source.

    Changed sources count when they are themselves known units (they
    rebuild too); a changed id that is not a unit key only propagates
    to the units that import it. Duplicate entries in ``changed`` are
    harmless.
    """
    rev = _reverse_edges(units)
    seen = set()
    queue = list(changed)
    while queue:
        cur = queue.pop(0)
        if cur in seen:
            continue  # diamond: a unit reached via two import paths rebuilds once
        seen.add(cur)
        queue.extend(rev.get(cur, []))
    return sorted(n for n in seen if n in units)


def fanout(units, changed):
    """How many units an edit of ``changed`` sources would rebuild."""
    return len(affected(units, changed))
