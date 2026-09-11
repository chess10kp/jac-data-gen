node CacheNode {
    has cid: str;
    has lock_hash: str;
    has toolchain: str;
    has collected: list[str] = [];
    has invalidated: bool = False;
}
edge Depends {}

walker DependencyClosure {
    has claimed: dict[str, bool] = {};

    can step with CacheNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        here.collected.append(here.cid);
        print(here.cid);
        for kid in [here ->:Depends:->][?:CacheNode] {
            visit :0: [kid];
        }
    }
}

walker DependentClosure {
    has changed: str;
    has claimed: dict[str, bool] = {};
    has affected: list[str] = [];

    can step with CacheNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.changed {
            self.affected.append(here.cid);
            print(here.cid);
        }
        for parent in [->:Depends:-> here][?:CacheNode] {
            visit :0: [parent];
        }
    }
}

walker PathSearch {
    has target: str;
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has found: bool = False;

    can step with CacheNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.path.append(here.cid);
        if here.cid == self.target {
            self.found = True;
            print(here.cid);
            disengage;
        }
        for kid in [here ->:Depends:->][?:CacheNode] {
            if not self.found {
                visit :0: [kid];
            }
        }
        if not self.found {
            self.path.pop();
        }
    }
}

def cache_inputs(root: CacheNode) -> list[str] {
    root.collected = [];
    with entry {
        root spawn DependencyClosure;
    }
    return root.collected;
}

def cache_key(root: CacheNode) -> str {
    return root.cid + ":" + root.lock_hash + ":" + root.toolchain;
}

def dependency_path(root: CacheNode, target: str) -> list[str] {
    var walker = PathSearch(target=target);
    with entry {
        root spawn walker;
    }
    return walker.path;
}

def invalidate_dependents(root: CacheNode, changed: str) -> list[str] {
    var walker = DependentClosure(changed=changed);
    with entry {
        root spawn walker;
    }
    for cid in walker.affected {
        root.collected.append(cid);
    }
    root.invalidated = True;
    return walker.affected;
}

test "diamond revisit is once only" {
    root = CacheNode(cid="app", lock_hash="l1", toolchain="rust");
    left = CacheNode(cid="left", lock_hash="l1", toolchain="rust");
    right = CacheNode(cid="right", lock_hash="l1", toolchain="rust");
    leaf = CacheNode(cid="leaf", lock_hash="l1", toolchain="rust");
    root +>: Depends:+> left;
    root +>: Depends:+> right;
    left +>: Depends:+> leaf;
    right +>: Depends:+> leaf;
    assert (sorted(cache_inputs(root)) == ["app", "leaf", "left", "right"]);
}

test "unknown path target is tolerated" {
    root = CacheNode(cid="app", lock_hash="l1", toolchain="pnpm");
    child = CacheNode(cid="pkg", lock_hash="l2", toolchain="pnpm");
    root +>: Depends:+> child;
    assert (dependency_path(root, "missing") == []);
}

test "cache key includes lock and toolchain" {
    root = CacheNode(cid="frontend", lock_hash="abc", toolchain="node20");
    assert (cache_key(root) == "frontend:abc:node20");
}

test "dependent invalidation skips changed node" {
    root = CacheNode(cid="app", lock_hash="l1", toolchain="rust");
    dep = CacheNode(cid="contract", lock_hash="l2", toolchain="rust");
    root +>: Depends:+> dep;
    affected = invalidate_dependents(dep, "contract");
    assert (affected == []);
    assert (dep.invalidated == True);
}
