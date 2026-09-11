"""Tag taxonomy store, lifted to OSP.

The id-keyed ``parent`` dict becomes Tag nodes joined by mirrored typed
edges (ChildOf upward, HasChild downward); the ancestor chain-walk and
descendant stack-loop become flooding walkers. The merge guard is the
issue's fix: re-parenting is a two-phase collect-then-rewire, and when
the source IS the target's parent, the survivor is detached (rooted)
instead of being pointed at itself. No node deletion: merged tags are
flagged and disconnected.
Ref: PersonalClaw/PersonalClaw#761
"""
node Tag {
    has tid: int;
    has name: str;
    has merged: bool = False;
}
edge ChildOf {}   # tag -> parent
edge HasChild {}  # parent -> tag

"""Loader handle: tag ids resolve through this lookup map."""
obj TagStore {
    has tags: dict[int, Tag];
    has roster: list[int];

    def resolve(tid: int) -> Tag | None {
        return self.tags.get(tid);
    }
}

def build_store() -> TagStore {
    return TagStore(tags={}, roster=[]);
}

def add_tag(store: TagStore, tag_id: int, name: str, parent_id: int | None = None) -> None {
    t = Tag(tid=tag_id, name=name);
    root ++> t;
    store.tags[tag_id] = t;
    store.roster.append(tag_id);
    if parent_id is not None {
        set_parent(store, tag_id, parent_id);
    }
}

walker AncestorClimb {
    has claimed: dict[int, bool] = {};
    has start_id: int = 0;
    has found: list[int] = [];

    can step with Tag entry {
        if here.tid in self.claimed or here.merged {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.start_id {
            self.found.append(here.tid);
        }
        visit [->:ChildOf:->];
    }
}

"""All ancestor ids above ``tag_id``, sorted; loop-guarded."""
def ancestors(store: TagStore, tag_id: int) -> list[int] {
    start = store.resolve(tag_id);
    if start is None {
        return [];
    }
    w = start spawn AncestorClimb(claimed={}, start_id=tag_id);
    return sorted(w.found);
}

walker DescendFlood {
    has claimed: dict[int, bool] = {};
    has root_id: int = 0;
    has found: list[int] = [];

    can step with Tag entry {
        if here.tid in self.claimed or here.merged {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.root_id {
            self.found.append(here.tid);
        }
        visit [->:HasChild:->];
    }
}

"""All descendant ids below ``tag_id`` (exclusive), sorted."""
def descendants(store: TagStore, tag_id: int) -> list[int] {
    start = store.resolve(tag_id);
    if start is None {
        return [];
    }
    w = start spawn DescendFlood(claimed={}, root_id=tag_id);
    return sorted(w.found);
}

# Detach ``tag_id`` from its current parent on both edge types.
def disconnect_child(store: TagStore, tag_id: int) -> None {
    t = store.tags[tag_id];
    ups = [t->:ChildOf:->];
    for p in ups {
        t del ->:ChildOf:-> p;
        p del ->:HasChild:-> t;
    }
}

"""Re-parent ``tag_id``; raises ValueError('tag_cycle') on cycles."""
def set_parent(store: TagStore, tag_id: int, parent_id: int | None) -> None {
    if parent_id is None {
        disconnect_child(store, tag_id);
        return;
    }
    if parent_id == tag_id or tag_id in ancestors(store, parent_id) {
        raise ValueError("tag_cycle");
    }
    disconnect_child(store, tag_id);
    t = store.tags[tag_id];
    p = store.tags[parent_id];
    t +>:ChildOf:+> p;
    p +>:HasChild:+> t;
}

"""Fold ``source_id`` into ``target_id`` (two-phase collect-then-rewire).

Returns {'moved': n}. When the source IS the target's parent, the naive
re-parent would point the survivor at itself; the survivor is rooted
instead -- never a self-cycle.
"""
def merge_tags(store: TagStore, source_id: int, target_id: int) -> dict[str, int] {
    src = store.tags[source_id];
    tgt = store.tags[target_id];
    kids = [src->:HasChild:->];  # phase 1: collect before mutating
    moved = 0;
    for c in kids {              # phase 2: rewire outside any walk
        src del ->:HasChild:-> c;
        c del ->:ChildOf:-> src;
        if c.tid == target_id {
            disconnect_child(store, target_id);  # survivor becomes a root
        } else {
            c +>:ChildOf:+> tgt;
            tgt +>:HasChild:+> c;
        }
        moved += 1;
    }
    disconnect_child(store, source_id);
    src.merged = True;
    return {"moved": moved};
}
