"""Knowledge-base tag taxonomy store.

Tags form a forest via ``parent_id``; several surfaces walk the
taxonomy. ``set_tag_parent`` rejects self- and multi-hop cycles by
walking the ancestor chain with a ``seen`` set, but ``merge_tags``
re-parented the source's children onto the target with no such guard:
merging a tag INTO its own child left the survivor pointing at itself
(``parent_id == id``), a latent infinite loop for any recursive
consumer of the taxonomy.
Ref: PersonalClaw/PersonalClaw#761
"""


class TagStore:
    def __init__(self):
        self.parent = {}  # tag_id -> parent_id | None
        self.names = {}   # tag_id -> display name
        self.merged = set()  # ids folded away by merge_tags

    def add_tag(self, tag_id, name, parent_id=None):
        self.names[tag_id] = name
        self.parent[tag_id] = parent_id


def ancestors(store, tag_id):
    """All ancestor ids above ``tag_id``, sorted. Guards against loops."""
    seen = set()
    cur = store.parent.get(tag_id)
    while cur is not None and cur not in seen:
        seen.add(cur)
        cur = store.parent.get(cur)
    return sorted(seen)


def descendants(store, tag_id):
    """All descendant ids below ``tag_id`` (exclusive), sorted."""
    seen = set()
    stack = [tid for tid, pid in store.parent.items()
             if pid == tag_id and tid not in store.merged]
    seen.update(stack)
    while stack:
        cur = stack.pop()
        for tid, pid in store.parent.items():
            if pid == cur and tid not in seen and tid not in store.merged:
                seen.add(tid)
                stack.append(tid)
    return sorted(seen)


def set_parent(store, tag_id, parent_id):
    """Re-parent ``tag_id``; raises ValueError('tag_cycle') on cycles."""
    if parent_id is None:
        store.parent[tag_id] = None
        return
    if parent_id == tag_id or tag_id in ancestors(store, parent_id):
        raise ValueError("tag_cycle")
    store.parent[tag_id] = parent_id


def merge_tags(store, source_id, target_id):
    """Fold ``source_id`` into ``target_id``: re-parent its children.

    When the source IS the target's parent, the naive re-parent would
    point the survivor at itself; the guard nulls it instead.
    Returns {'moved': n}.
    """
    moved = 0
    children = [t for t, p in store.parent.items() if p == source_id]
    for child in children:
        if child == target_id:
            store.parent[target_id] = None  # never self-cycle the survivor
        else:
            store.parent[child] = target_id
        moved += 1
    store.parent[source_id] = None
    store.merged.add(source_id)
    return {"moved": moved}
