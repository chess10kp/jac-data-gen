"""Scene-reconstruction support ordering, lifted to OSP.

Adjacency dicts become SceneItem nodes joined by typed HoldsUp /
RestsOn edges; the two deque BFS loops become flooding walkers. The
claim map is the explicit cycle policy: jac 0.36.1 walkers do not
dedupe on cyclic graphs (mutual-support cycles are expected here), so
every entry is guarded once with `skip` on revisit.
Ref: NVlabs/SimFoundry#4
"""
node SceneItem {
    has name: str;
}
edge HoldsUp {}   # supporter -> dependent
edge RestsOn {}   # dependent -> supporter

"""Loader handle: id-string parameters resolve through this lookup map."""
obj Scene {
    has items: dict[str, SceneItem];
    has names: list[str];

    def resolve(name: str) -> SceneItem | None {
        return self.items.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_scene(items: list[str], rests_on: list[tuple[str, str]]) -> Scene {
    scene = Scene(items={}, names=[]);
    for name in items {
        it = SceneItem(name=name);
        root ++> it;
        scene.items[name] = it;
        scene.names.append(name);
    }
    for (item, sup) in rests_on {
        sup_node = scene.items[sup];
        item_node = scene.items[item];
        sup_node +>:HoldsUp:+> item_node;
        item_node +>:RestsOn:+> sup_node;
    }
    return scene;
}

walker FalloutFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with SceneItem entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        # No disengage here: this walker instance is shared across the
        # frontier, and disengage on one dead end would truncate siblings.
        # Claim-map exhaustion terminates the flood.
        visit [->:HoldsUp:->];
    }
}

walker SupportFlood {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with SceneItem entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [->:RestsOn:->];
    }
}

"""Everything that falls when ``item`` is removed, itself included."""
def fallout_of(scene: Scene, item: str) -> list[str] {
    start = scene.resolve(item);
    if start is None {
        return [item];
    }
    w = start spawn FalloutFlood(claimed={});
    return sorted(w.members);
}

"""Transitive closure of everything holding ``item`` up, itself included."""
def supporters_of(scene: Scene, item: str) -> list[str] {
    start = scene.resolve(item);
    if start is None {
        return [item];
    }
    w = start spawn SupportFlood(claimed={});
    return sorted(w.members);
}

walker ReachProbe {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;

    can step with SceneItem entry {
        if here.name == self.target and not (self.found) {
            self.found = True;
            disengage;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [->:RestsOn:->] else { disengage; }
    }
}

"""True when ``candidate`` transitively supports ``item``."""
def is_supported_by(scene: Scene, item: str, candidate: str) -> bool {
    start = scene.resolve(item);
    if start is None or candidate not in scene.items {
        return False;
    }
    if item == candidate {
        return False;
    }
    w = start spawn ReachProbe(claimed={}, target=candidate);
    return w.found;
}
