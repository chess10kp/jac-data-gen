"""nickbyrum2469/OmniForge#1 — Safe imported-asset deletion with usage cascade."""

obj AssetStore {
    has assets: dict[str, Asset] = {};
    has usage_index: dict[str, list[str]] = {};
    has scenes: dict[str, Scene] = {};
}

node Asset { has aid: str; }
node Scene { has sid: str; }

edge Derivative {}
edge SceneUses {}

walker DerivCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Asset] = [];

    can step with Asset entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        self.found.append(here);
        visit [->:Derivative:->][?:Asset];
    }
}

def load_asset_store(
    assets: list[str],
    derivative_edges: list[tuple[str, str]],
    scene_refs: list[tuple[str, str]],
) -> AssetStore {
    s = AssetStore();
    for aid in assets {
        if aid not in s.assets {
            nd = Asset(aid=aid);
            root ++> nd;
            s.assets[aid] = nd;
        }
    }
    for (parent, child) in derivative_edges {
        p = s.assets.get(parent, None);
        c = s.assets.get(child, None);
        if p is not None and c is not None { p +>:Derivative:+> c; }
    }
    for (scene, asset) in scene_refs {
        a = s.assets.get(asset, None);
        if a is None { continue; }
        if scene not in s.scenes {
            sc = Scene(sid=scene);
            root ++> sc;
            s.scenes[scene] = sc;
        }
        s.scenes[scene] +>:SceneUses:+> a;
        cur = s.usage_index.get(asset, []);
        if scene not in cur {
            s.usage_index[asset] = cur + [scene];
        }
    }
    return s;
}

def scene_usages(store: AssetStore, asset_id: str) -> list[str] {
    if asset_id not in store.assets { return []; }
    return sorted(set(store.usage_index.get(asset_id, [])));
}

def _remove_asset(store: AssetStore, a: Asset) {
    for sc in store.scenes.values() {
        for tgt in [sc ->:SceneUses:->][?:Asset] {
            if tgt.aid == a.aid { sc del ->:SceneUses:-> a; }
        }
    }
    for ch in [a ->:Derivative:->][?:Asset] { a del ->:Derivative:-> ch; }
    for par in [a <-:Derivative:<-][?:Asset] { par del ->:Derivative:-> a; }
    del a;
}

def delete_import(store: AssetStore, asset_id: str, force: bool = False) -> list[str] {
    start = store.assets.get(asset_id, None);
    if start is None { return []; }
    if scene_usages(store, asset_id) and not force {
        raise ValueError("asset still referenced by scene");
    }
    w = start spawn DerivCollect(claimed={}, found=[]);
    doomed = w.found;
    deleted_ids = sorted([a.aid for a in doomed]);
    for a in doomed { _remove_asset(store, a); }
    for aid in deleted_ids {
        store.assets.pop(aid, None);
        store.usage_index.pop(aid, None);
    }
    return deleted_ids;
}

def active_assets(store: AssetStore) -> list[str] {
    return sorted(store.assets.keys());
}
