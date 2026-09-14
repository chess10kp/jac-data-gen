# iss_OpenIntegrationEngine__engine__337.jac

node Catalog {
    has label: str = "engine";
}
node Family {
    has name: str;
    has bom_version: str;
}
node Artifact {
    has key: str;
    has name: str;
    has family: str;
    has version: str;
    has source: str;
    has cves: int = 0;
}
edge HasFamily {}
edge HasArtifact {}
edge HasMember {}
edge DependsOn {}

walker DependencyScan {
    has start: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = {};

    can step with Artifact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.key != self.start { self.found.append(here.key); }
        print(here.key);
        for kid in [here ->:DependsOn:->][?:Artifact] {
            visit :0: [kid];
        }
    }
}

walker FamilyAudit {
    has claimed: dict[str, bool] = {};
    has mismatched: list[str] = {};

    can audit with Family entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.name);
        for member in [here ->:HasMember:->][?:Artifact] {
            if member.version != here.bom_version {
                self.mismatched.append(member.key);
            }
        }
    }
}

def find_artifact(cat: Catalog, key: str) -> Artifact | None {
    for art in [cat ->:HasArtifact:->][?:Artifact] {
        if art.key == key { return art; }
    }
    return None;
}

def find_family(cat: Catalog, name: str) -> Family | None {
    for fam in [cat ->:HasFamily:->][?:Family] {
        if fam.name == name { return fam; }
    }
    return None;
}

def new_catalog -> Catalog {
    return Catalog();
}

def add_family(cat: Catalog, name: str, bom_version: str) -> Family {
    fam: Family | None = find_family(cat, name);
    if fam is not None {
        fam.bom_version = bom_version;
        return fam;
    }
    fam = Family(name=name, bom_version=bom_version);
    cat +>:HasFamily:+> fam;
    return fam;
}

def add_artifact(
    cat: Catalog,
    key: str,
    name: str,
    family: str,
    version: str,
    source: str
) -> Artifact {
    old: Artifact | None = find_artifact(cat, key);
    if old is not None { return old; }
    fam: Family | None = find_family(cat, family);
    if fam is None { fam = add_family(cat, family, version); }
    art = Artifact(
        key=key, name=name, family=family,
        version=version, source=source
    );
    cat +>:HasArtifact:+> art;
    fam +>:HasMember:+> art;
    return art;
}

def add_dependency(cat: Catalog, from_key: str, to_key: str) -> bool {
    from_art: Artifact | None = find_artifact(cat, from_key);
    to_art: Artifact | None = find_artifact(cat, to_key);
    if from_art is None || to_art is None { return False; }
    from_art +>:DependsOn:+> to_art;
    return True;
}

def set_cves(cat: Catalog, key: str, count: int) -> bool {
    if count < 0 { return False; }
    art: Artifact | None = find_artifact(cat, key);
    if art is None { return False; }
    art.cves = count;
    return True;
}

def dependency_closure(cat: Catalog, key: str) -> list[str] {
    art: Artifact | None = find_artifact(cat, key);
    if art is None { return []; }
    scan = art spawn DependencyScan(start=key);
    return sorted(scan.found);
}

def family_drift(cat: Catalog, name: str) -> list[str] {
    fam: Family | None = find_family(cat, name);
    if fam is None { return []; }
    audit = fam spawn FamilyAudit();
    return sorted(audit.mismatched);
}

def cve_total(cat: Catalog) -> int {
    total: int = 0;
    for art in [cat ->:HasArtifact:->][?:Artifact] {
        total += art.cves;
    }
    return total;
}

def source_keys(cat: Catalog, source: str) -> list[str] {
    keys: list[str] = [];
    for art in [cat ->:HasArtifact:->][?:Artifact] {
        if art.source == source { keys.append(art.key); }
    }
    return sorted(keys);
}
