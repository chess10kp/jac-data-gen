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
