node Component {
    has cid: str;
    has lane: str;
    has spec_hash: str;
    has input_hash: str;
    has artifact_hash: str;
}

node Artifact {
    has aid: str;
    has payload_hash: str;
}

node BuildManifest {
    has mid: str;
    has component_ids: list[str] = [];
}

edge DependsOn {}
edge Publishes {}
edge Uses {}

obj Registry {
    has components: dict[str, Component] = {};
    has artifacts: dict[str, Artifact] = {};
    has manifests: dict[str, BuildManifest] = {};
}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        for kid in [here ->:DependsOn:->][?:Component] {
            visit :0: [kid];
        }
        print(self.found);
    }
}

def new_registry() -> Registry {
    return Registry();
}

def register_component(
    reg: Registry,
    cid: str,
    lane: str,
    spec_hash: str,
    input_hash: str
) -> str {
    artifact_hash = lane + ":" + spec_hash + ":" + input_hash;
    component = Component(
        cid=cid,
        lane=lane,
        spec_hash=spec_hash,
        input_hash=input_hash,
        artifact_hash=artifact_hash
    );
    artifact = Artifact(aid=artifact_hash, payload_hash=artifact_hash);
    reg.components[cid] = component;
    if artifact_hash not in reg.artifacts {
        reg.artifacts[artifact_hash] = artifact;
        component +>:Publishes:+> artifact;
    }
    return artifact_hash;
}

def request_artifact(
    reg: Registry,
    cid: str,
    lane: str,
    spec_hash: str,
    input_hash: str
) -> str {
    if cid in reg.components {
        current = reg.components[cid];
        if current.lane == lane
            and current.spec_hash == spec_hash
            and current.input_hash == input_hash {
            return current.artifact_hash;
        }
    }
    return register_component(reg, cid, lane, spec_hash, input_hash);
}

def add_dependency(reg: Registry, parent_id: str, child_id: str) -> bool {
    if parent_id not in reg.components {
        return False;
    }
    if child_id not in reg.components {
        return False;
    }
    parent = reg.components[parent_id];
    child = reg.components[child_id];
    parent +>:DependsOn:+> child;
    return True;
}

def descendants(reg: Registry, start_id: str) -> list[str] {
    found: list[str] = [];
    if start_id not in reg.components {
        return found;
    }
    start = reg.components[start_id];
    walk_out = start spawn Descendants(claimed={});
    for cid in walk_out.found {
        if cid not in found {
            found.append(cid);
        }
    }
    return found;
}

def invalidation_plan(reg: Registry, changed_id: str) -> list[str] {
    affected: list[str] = descendants(reg, changed_id);
    if len(affected) > 0 {
        affected = affected[1:];
    }
    return sorted(affected);
}

def build_manifest(reg: Registry, component_ids: list[str]) -> str {
    ids: list[str] = sorted(component_ids);
    manifest_hash = "manifest";
    for cid in ids {
        if cid in reg.components {
            manifest_hash = manifest_hash + ":" + reg.components[cid].artifact_hash;
        }
    }
    if manifest_hash not in reg.manifests {
        manifest = BuildManifest(mid=manifest_hash, component_ids=ids);
        reg.manifests[manifest_hash] = manifest;
        for cid in ids {
            if cid in reg.components {
                manifest +>:Uses:+> reg.components[cid];
            }
        }
    }
    return manifest_hash;
}

def cache_lookup(reg: Registry, artifact_hash: str) -> bool {
    return artifact_hash in reg.artifacts;
}
