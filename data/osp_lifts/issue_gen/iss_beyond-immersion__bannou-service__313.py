"""Location-hierarchy encounter proximity queries.

Encounters are attached to locations in a parent/child hierarchy (realm >
city > district > room). The exact-location query only returned
encounters at the queried location; the hierarchy integration walks the
parent chain upward (a while loop over ``parent_id`` rows) for ancestor
encounters ("all encounters in this city") and recursively descends a
children index for descendant encounters ("this room and all sub-rooms").
An encounter is "near" a location when it sits at that location, at any
ancestor, or at any descendant.
Ref: beyond-immersion/bannou-service#313
"""


def ancestors_of(locations, loc_id):
    """Sorted ids of every ancestor of ``loc_id`` (parents upward).

    ``locations`` is a list of ``{"id": ..., "parent_id": ...}`` rows in
    any order; a missing or unknown ``loc_id`` yields no ancestors, and a
    parent id naming no row still counts as an ancestor before the chain
    stops.
    """
    by_id = {row["id"]: row for row in locations}
    out = []
    cur = by_id.get(loc_id)
    while cur is not None and cur.get("parent_id") is not None:
        pid = cur["parent_id"]
        out.append(pid)
        cur = by_id.get(pid)
    return sorted(out)


def descendants_of(locations, loc_id):
    """Sorted ids of every descendant of ``loc_id`` (children downward)."""
    children = {}
    for row in locations:
        pid = row.get("parent_id")
        if pid is not None:
            children.setdefault(pid, []).append(row["id"])
    out = []

    def descend(pid):
        for child in children.get(pid, []):
            out.append(child)
            descend(child)

    descend(loc_id)
    return sorted(out)


def find_encounters(locations, encounters, loc_id):
    """Sorted ids of encounters "near" ``loc_id``.

    Near means: at the location itself, at any ancestor, or at any
    descendant. ``encounters`` is a list of ``{"id": ..., "location_id":
    ...}`` rows; an encounter at a location absent from ``locations``
    only ever matches an exact query on that location id.
    """
    near = {loc_id}
    near.update(ancestors_of(locations, loc_id))
    near.update(descendants_of(locations, loc_id))
    return sorted(e["id"] for e in encounters if e["location_id"] in near)
