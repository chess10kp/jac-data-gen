"""Incremental index updates for a document section tree.

Reprocessing a large document rebuilds the whole hierarchical index even
when a revision touches two pages: a 500-page policy manual that receives
a 2-page edit regenerates summaries and tree structure for everything.
The incremental reindex below keeps the section tree as parent pointers
plus children lists, with a content hash per section. Changed sections
are detected by hash comparison between document versions
(``diff_versions``); affected subtrees are collected by recursive descent
over the children lists with a once-only guard for shared subtrees
(``rebuilt``); and summaries are recomputed only along the impacted
ancestor chains, walked link by link through the parent pointers
(``resummarized``). A section that is itself rebuilt is not resummarized,
and unknown section ids are skipped.
Ref: VectifyAI/PageIndex#316
"""


def diff_versions(old, new):
    """Section ids whose content hash differs between two document versions.

    ``old``/``new`` map section id -> ``{"parent": id | None, "children":
    [ids], "hash": str}``. Sections present in only one version count as
    changed (added or removed).
    """
    changed = set()
    for sid in old:
        if sid not in new or old[sid]["hash"] != new[sid]["hash"]:
            changed.add(sid)
    for sid in new:
        if sid not in old:
            changed.add(sid)
    return sorted(changed)


def reindex(tree, changed):
    """Rebuild only affected subtrees and impacted ancestor paths.

    ``tree`` maps section id -> ``{"parent": id | None, "children": [ids],
    "hash": str}`` and ``changed`` lists section ids detected as changed.
    ``rebuilt`` holds every changed section plus all of its descendants;
    ``resummarized`` holds the strict ancestors of changed sections that
    are not themselves rebuilt. Returns
    ``{"rebuilt": sorted, "resummarized": sorted}``.
    """
    rebuilt = set()
    resummarized = set()
    for sid in changed:
        if sid not in tree:
            continue  # unknown section: nothing to reindex
        rebuilt.add(sid)
        rebuilt |= _descendants(sid, tree)
        resummarized |= _ancestors(sid, tree)
    resummarized -= rebuilt
    return {"rebuilt": sorted(rebuilt), "resummarized": sorted(resummarized)}


def _descendants(sid, tree):
    """All sections beneath ``sid``: recursive descent over children lists."""
    out = set()
    _collect_descendants(sid, tree, out)
    return out


def _collect_descendants(sid, tree, out):
    for kid in tree[sid]["children"]:
        if kid in out:
            continue  # shared subtrees are swept once
        out.add(kid)
        _collect_descendants(kid, tree, out)


def _ancestors(sid, tree):
    """Strict ancestors of ``sid``: link-by-link parent-pointer walk."""
    out = set()
    cur = tree[sid]["parent"]
    while cur is not None:
        out.add(cur)
        cur = tree[cur]["parent"]
    return out
