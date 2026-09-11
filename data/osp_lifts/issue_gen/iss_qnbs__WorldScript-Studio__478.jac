"""qnbs/WorldScript-Studio#478 — PWA offline manifest require-graph closure."""

obj OfflineManifest {
    def register_asset(asset_id: str) -> None;
    def require(asset: str, needs: str) -> None;
    def offline_closure(`root: str) -> list[str];
}

node Asset {
    has asset_id: str;
}

edge Requires {}

walker OfflineClosureWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        matches = [root-->][?:Asset, asset_id == self.origin];
        if matches {
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Asset entry {
        if here.asset_id in self.claimed {
            skip;
        }
        self.claimed[here.asset_id] = True;
        if here.asset_id != self.origin {
            self.hits.append(here.asset_id);
        }
        visit [->:Requires:->];
    }
}

impl OfflineManifest.register_asset(asset_id: str) -> None {
    target = asset_id;
    if not [root-->][?:Asset, asset_id == target] {
        root ++> Asset(asset_id=asset_id);
    }
}

impl OfflineManifest.require(asset: str, needs: str) -> None {
    a_list = [root-->][?:Asset, asset_id == asset];
    if a_list {
        a = a_list[0];
    } else {
        a = root ++> Asset(asset_id=asset);
    }
    n_list = [root-->][?:Asset, asset_id == needs];
    if n_list {
        n = n_list[0];
    } else {
        n = root ++> Asset(asset_id=needs);
    }
    a +>:Requires:+> n;
}

impl OfflineManifest.offline_closure(`root: str) -> list[str] {
    target = `root;
    if not [root-->][?:Asset, asset_id == target] {
        return [];
    }
    w = root spawn OfflineClosureWalker(origin=`root);
    return sorted(w.hits);
}
