node PlaneManifest {
    has generation: int = 0;
    has frozen: bool = False;
}

node Extension {
    has extension_id: str;
    has plane_id: str;
    has provider_id: str;
}

edge Declares {}
edge DependsOn {}

walker PlaneSnapshot {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has diagnostics: list[str] = [];

    can collect_manifest with PlaneManifest entry {
        print("collect manifest");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        for kid in [here ->:Declares:->][?:Extension] {
            visit :0: [kid];
        }
    }

    can collect_extension with Extension entry {
        print("collect extension " + here.extension_id);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.extension_id);
        if here.provider_id == "" {
            self.diagnostics.append("missing-provider:" + here.extension_id);
        }
        for kid in [here ->:DependsOn:->][?:Extension] {
            visit :0: [kid];
        }
    }
}

def new_manifest() -> PlaneManifest {
    return PlaneManifest();
}

def register_extension(
    manifest: PlaneManifest,
    extension: Extension | None
) -> bool {
    if manifest.frozen {
        return False;
    }
    if extension == None {
        return False;
    }
    for prior in [manifest ->:Declares:->][?:Extension] {
        if prior.extension_id == extension.extension_id {
            return False;
        }
        if prior.plane_id == extension.plane_id
            && prior.provider_id != extension.provider_id {
            return False;
        }
    }
    manifest +>:Declares:+> extension;
    manifest.generation += 1;
    return True;
}

def link_dependency(parent: Extension, child: Extension) -> None {
    parent +>:DependsOn:+> child;
}

def freeze_manifest(manifest: PlaneManifest) -> int {
    manifest.frozen = True;
    return manifest.generation;
}

def snapshot_extensions(manifest: PlaneManifest) -> list[str] {
    w = manifest spawn PlaneSnapshot(claimed={});
    return sorted(w.found);
}

def find_extension(
    manifest: PlaneManifest,
    extension_id: str
) -> Extension | None {
    for extension in [manifest ->:Declares:->][?:Extension] {
        if extension.extension_id == extension_id {
            return extension;
        }
    }
    return None;
}

def dispatch_provider(
    manifest: PlaneManifest,
    plane_id: str
) -> str | None {
    for extension in [manifest ->:Declares:->][?:Extension] {
        if extension.plane_id == plane_id && extension.provider_id != "" {
            return extension.provider_id;
        }
    }
    return None;
}

def diagnostics(manifest: PlaneManifest) -> list[str] {
    w = manifest spawn PlaneSnapshot(claimed={});
    return sorted(w.diagnostics);
}

test "diamond revisit is once only" {
    manifest = new_manifest();
    alpha = Extension(
        extension_id="alpha",
        plane_id="request",
        provider_id="core"
    );
    beta = Extension(
        extension_id="beta",
        plane_id="request",
        provider_id="core"
    );
    shared = Extension(
        extension_id="shared",
        plane_id="hook",
        provider_id="core"
    );
    assert(register_extension(manifest, alpha) == True);
    assert(register_extension(manifest, beta) == True);
    assert(register_extension(manifest, shared) == True);
    link_dependency(alpha, shared);
    link_dependency(beta, shared);
    assert(snapshot_extensions(manifest) == ["alpha", "beta", "shared"]);
}

test "unknown identifiers fail closed" {
    manifest = new_manifest();
    assert(find_extension(manifest, "missing") == None);
    assert(dispatch_provider(manifest, "unknown-plane") == None);
    assert(register_extension(manifest, None) == False);
    assert(snapshot_extensions(manifest) == []);
}

test "exclusive provider and immutable generation" {
    manifest = new_manifest();
    first = Extension(
        extension_id="first",
        plane_id="tool",
        provider_id="builtin"
    );
    conflict = Extension(
        extension_id="conflict",
        plane_id="tool",
        provider_id="plugin"
    );
    later = Extension(
        extension_id="later",
        plane_id="stream",
        provider_id="plugin"
    );
    assert(register_extension(manifest, first) == True);
    assert(register_extension(manifest, conflict) == False);
    assert(freeze_manifest(manifest) == 1);
    assert(register_extension(manifest, later) == False);
    assert(dispatch_provider(manifest, "tool") == "builtin");
}

test "diagnostics expose missing typed provider" {
    manifest = new_manifest();
    broken = Extension(
        extension_id="broken",
        plane_id="observer",
        provider_id=""
    );
    assert(register_extension(manifest, broken) == True);
    assert(diagnostics(manifest) == ["missing-provider:broken"]);
}
