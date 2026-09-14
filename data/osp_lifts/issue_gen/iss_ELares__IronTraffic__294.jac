"""Idiomatic OSP lift for ELares/IronTraffic#294."""

node Store {
    has kind: str;
    has live: dict[str, str] = {};
    has staging: dict[str, str] = {};
    has tombstones: dict[str, bool] = {};
    has metadata: dict[str, str] = {};
    has records: dict[str, Item] = {};
    has dirty: bool = False;
    has initializing: bool = False;
}

node Item {
    has cid: str;
    has kind: str;
    has value: str;
    has phase: str = "live";
    has live: bool = True;
}

node Event {
    has variant: str;
    has kind: str;
    has cid: str = "";
    has value: str = "";
}

node MetaEvent {
    has key: str;
    has value: str;
}

node Config {
    has kind: str;
    has scope: str;
    has selector: str = "";
    has bookmarks: bool = True;
    has initial_list_strategy: str = "ListWatch";
    has page_size: int = 500;
    has list_semantic: str = "MostRecent";
    has timeout_seconds: int = 290;
    has streaming_lists: bool = False;
    has resync_seconds: int = 0;
    has backoff_name: str = "DefaultBackoff";
}

edge Contains {}
edge Ref {}

walker FinalizeWalker {
    has store: Store;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can scan_store with Store entry {
        print("scan " + here.kind);
        for item in [here ->:Contains:->][?:Item] {
            visit :0: [item];
        }
    }

    can scan_item with Item entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        if here.cid in self.store.live {
            here.live = True;
            here.phase = "live";
        } else {
            here.live = False;
            here.phase = "tombstone";
            self.store.tombstones[here.cid] = True;
        }
        print(here.cid);
        for child in [here ->:Ref:->][?:Item] {
            visit :0: [child];
        }
    }
}

def _record(store: Store, cid: str, kind: str, value: str, phase: str) -> Item {
    item: Item;
    if cid in store.records {
        item = store.records[cid];
    } else {
        item = Item(cid=cid, kind=kind, value=value, phase=phase);
        store.records[cid] = item;
        store +>:Contains:+> item;
    }
    item.kind = kind;
    item.value = value;
    item.phase = phase;
    item.live = phase == "live";
    return item;
}

def watch_config(kind: str) -> Config {
    scope: str = "namespace";
    if kind == "Gateway" {
        scope = "cluster";
    }
    return Config(kind=kind, scope=scope);
}

def apply_event(store: Store, event: Event) {
    if event.kind != store.kind {
        return;
    }
    if event.variant == "Apply" {
        store.live[event.cid] = event.value;
        store.tombstones.pop(event.cid);
        _record(store, event.cid, event.kind, event.value, "live");
    }
    if event.variant == "Delete" {
        store.live.pop(event.cid);
        store.staging.pop(event.cid);
        store.tombstones[event.cid] = True;
        _record(store, event.cid, event.kind, event.value, "tombstone");
    }
    if event.variant == "Init" {
        store.staging = {};
        store.initializing = True;
    }
    if event.variant == "InitApply" {
        store.staging[event.cid] = event.value;
        _record(store, event.cid, event.kind, event.value, "staging");
    }
    if event.variant == "InitDone" {
        store.live = store.staging;
        store.staging = {};
        store.tombstones = {};
        store.initializing = False;
        w = store spawn FinalizeWalker(store=store, claimed={});
    }
    store.dirty = True;
}

def apply_meta_event(store: Store, event: MetaEvent) {
    store.metadata[event.key] = event.value;
    store.dirty = True;
}

def spawn_kind(kind: str) -> Store {
    store = Store(kind=kind);
    w = store spawn FinalizeWalker(store=store, claimed={});
    print("watching " + kind);
    return store;
}
