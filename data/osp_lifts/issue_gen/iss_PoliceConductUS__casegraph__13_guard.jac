"""PoliceConductUS/casegraph#13: recursive package indexing in OSP."""

edge CONTAINS {}
edge DERIVED_FROM {}

node Package {
    has package_id: str;
    has managed_writes: bool = False;
}

node Folder {
    has package_id: str;
    has folder_id: str;
    has relative_path: str;
}

node Source {
    has package_id: str;
    has path: str;
    has media_type: str;
    has size: int;
    has sha256: str;
    has supported: bool;
    has status: str;
}

node Artifact {
    has package_id: str;
    has path: str;
    has sidecar_path: str;
    has source_sha256: str;
    has content: str;
    has validated: bool = True;
}

obj Store {
    has packages: dict[str, Package] = {};
    has folders: dict[str, Folder] = {};
    has sources: dict[str, Source] = {};
    has artifacts: dict[str, Artifact] = {};

    can get(key: str) -> Artifact | None {
        if key in self.artifacts {
            return self.artifacts[key];
        }
        return None;
    }
}

walker InventoryWalker {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can start with entry {
        print("CaseGraph indexer ready");
    }

    can scan_package with Package entry {
        key = "p:" + here.package_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        print("indexing package " + here.package_id);
        for folder in [here ->:CONTAINS:->][?:Folder] {
            visit :0: [folder];
        }
    }

    can scan_folder with Folder entry {
        key = "f:" + here.package_id + ":" + here.folder_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        for child in [here ->:CONTAINS:->][?:Folder] {
            visit :0: [child];
        }
        for source in [here ->:CONTAINS:->][?:Source] {
            visit :0: [source];
        }
    }

    can scan_source with Source entry {
        key = "s:" + here.package_id + ":" + here.path;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        self.count += 1;
        print(here.path + " [" + here.status + "]");
    }
}

def new_store -> Store {
    return Store();
}

def supported_type(media_type: str) -> bool {
    return media_type == "application/pdf"
        or media_type == "text/markdown"
        or media_type == "application/yaml";
}

def without_pdf(path: str) -> str {
    if path.endswith(".pdf") {
        return path[0:len(path) - 4];
    }
    return path;
}

def add_package(store: Store, package_id: str, managed_writes: bool) -> bool {
    if package_id in store.packages {
        return False;
    }
    pkg = Package(package_id=package_id, managed_writes=managed_writes);
    store.packages[package_id] = pkg;
    return True;
}

def add_folder(
    store: Store,
    package_id: str,
    folder_id: str,
    parent_id: str
) -> bool {
    if package_id not in store.packages or folder_id == parent_id {
        return False;
    }
    key = package_id + ":" + folder_id;
    folder: Folder;
    if key in store.folders {
        folder = store.folders[key];
    } else {
        folder = Folder(
            package_id=package_id,
            folder_id=folder_id,
            relative_path=folder_id
        );
        store.folders[key] = folder;
    }
    if parent_id == "" {
        store.packages[package_id] +>:CONTAINS:+> folder;
        return True;
    }
    parent_key = package_id + ":" + parent_id;
    if parent_key not in store.folders {
        return False;
    }
    store.folders[parent_key] +>:CONTAINS:+> folder;
    return True;
}

def add_source(
    store: Store,
    package_id: str,
    folder_id: str,
    path: str,
    media_type: str,
    size: int,
    sha256: str
) -> bool {
    if package_id not in store.packages {
        return False;
    }
    folder_key = package_id + ":" + folder_id;
    if folder_key not in store.folders {
        return False;
    }
    source_key = package_id + ":" + path;
    supported = supported_type(media_type);
    status = "indexed";
    if supported == False {
        status = "unsupported";
    }
    source: Source;
    created = False;
    if source_key in store.sources {
        source = store.sources[source_key];
        source.size = size;
        source.sha256 = sha256;
        source.media_type = media_type;
        source.supported = supported;
        source.status = status;
    } else {
        source = Source(
            package_id=package_id,
            path=path,
            media_type=media_type,
            size=size,
            sha256=sha256,
            supported=supported,
            status=status
        );
        store.sources[source_key] = source;
        created = True;
    }
    artifact_key = package_id + ":" + without_pdf(path) + ".md";
    prior = store.get(artifact_key);
    if prior is not None and prior.source_sha256 != sha256 {
        source.status = "possible_stale_derivation";
    }
    store.folders[folder_key] +>:CONTAINS:+> source;
    return created;
}

def index_package(store: Store, package_id: str) -> int {
    if package_id not in store.packages {
        return 0;
    }
    pkg = store.packages[package_id];
    w = pkg spawn InventoryWalker(claimed={});
    return w.count;
}

def index_folder(store: Store, package_id: str, folder_id: str) -> int {
    key = package_id + ":" + folder_id;
    if key not in store.folders {
        return 0;
    }
    folder = store.folders[key];
    w = folder spawn InventoryWalker(claimed={});
    return w.count;
}

def extract_pdf(
    store: Store,
    package_id: str,
    source_path: str,
    extracted_text: str,
    extraction_ok: bool
) -> bool {
    source_key = package_id + ":" + source_path;
    if source_key not in store.sources {
        return False;
    }
    source = store.sources[source_key];
    if source.media_type != "application/pdf"
        or source.supported == False {
        return False;
    }
    if extraction_ok == False {
        source.status = "extraction_failed";
        return False;
    }
    pkg = store.packages[package_id];
    if pkg.managed_writes == False {
        return False;
    }
    artifact_path = without_pdf(source.path) + ".md";
    artifact_key = package_id + ":" + artifact_path;
    prior = store.get(artifact_key);
    if prior is not None {
        if prior.source_sha256 == source.sha256 {
            return False;
        }
        source.status = "possible_stale_derivation";
        return False;
    }
    artifact = Artifact(
        package_id=package_id,
        path=artifact_path,
        sidecar_path=artifact_path + ".casegraph.yaml",
        source_sha256=source.sha256,
        content=extracted_text
    );
    store.artifacts[artifact_key] = artifact;
    source +>:DERIVED_FROM:+> artifact;
    return True;
}

with entry {
    root spawn InventoryWalker;
}

test "diamond revisit is claimed once" {
    s = new_store();
    assert (add_package(s, "pkg", True));
    assert (add_folder(s, "pkg", "a", ""));
    assert (add_folder(s, "pkg", "b", ""));
    assert (add_folder(s, "pkg", "c", "a"));
    assert (add_folder(s, "pkg", "c", "b"));
    assert (add_source(s, "pkg", "c", "ruling.pdf", "application/pdf", 12, "sha-a"));
    assert (index_package(s, "pkg") == 1);
}

test "unknown identifiers are tolerated" {
    s = new_store();
    assert (index_package(s, "missing") == 0);
    assert (index_folder(s, "missing", "root") == 0);
    assert (add_source(s, "missing", "root", "x.pdf", "application/pdf", 1, "x") == False);
}

test "pdf artifacts are immutable by source hash" {
    s = new_store();
    assert (add_package(s, "pkg", True));
    assert (add_folder(s, "pkg", "root", ""));
    assert (add_source(s, "pkg", "root", "ruling.pdf", "application/pdf", 8, "sha-a"));
    assert (extract_pdf(s, "pkg", "ruling.pdf", "# ruling", True));
    assert (extract_pdf(s, "pkg", "ruling.pdf", "# duplicate", True) == False);
    assert (add_source(s, "pkg", "root", "ruling.pdf", "application/pdf", 9, "sha-b") == False);
    assert (s.sources["pkg:ruling.pdf"].status == "possible_stale_derivation");
    assert (extract_pdf(s, "pkg", "ruling.pdf", "# changed", True) == False);
}

test "unsupported files remain inventoried" {
    s = new_store();
    assert (add_package(s, "pkg", False));
    assert (add_folder(s, "pkg", "root", ""));
    assert (add_source(s, "pkg", "root", "image.zip", "application/zip", 4, "zip"));
    assert (index_package(s, "pkg") == 1);
    assert (s.sources["pkg:image.zip"].status == "unsupported");
}
