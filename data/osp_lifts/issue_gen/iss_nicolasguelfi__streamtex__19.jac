node Registry {
    has manifest: dict[str, Block] = {};
    has directories: list[Directory] = [];
}

node Directory {
    has path: str;
    has source_kind: str = "shared";
    has rank: int = 1;
    has subdirectory: str = "";
    has registry: Registry;
}

node Block {
    has name: str;
    has path: str;
    has loaded: bool = False;
    has kind: str = "atomic";
    has source_kind: str = "shared";
    has source_dir: str = "";
    has subdirectory: str = "";
}

edge Contains {}
edge Defines {}

walker ScanDirectories {
    has claimed: dict[str, bool] = {};

    can step with Directory entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scanning " + here.path);

        for block in [here ->:Defines:->][?:Block] {
            register_block(
                here.registry,
                block,
                here.source_kind,
                here.path,
                here.subdirectory
            );
        }

        for child in [here ->:Contains:->][?:Directory] {
            visit :0: [child];
        }
    }
}

def register_directory(
    registry: Registry,
    directory: Directory,
    source_kind: str,
    rank: int,
    subdirectory: str
) {
    directory.registry = registry;
    directory.source_kind = source_kind;
    directory.rank = rank;
    directory.subdirectory = subdirectory;
    registry.directories.append(directory);
}

def register_block(
    registry: Registry,
    block: Block,
    source_kind: str,
    source_directory: str,
    subdirectory: str
) {
    block.source_kind = source_kind;
    block.source_dir = source_directory;
    block.subdirectory = subdirectory;

    if block.name in registry.manifest {
        old: Block = registry.manifest[block.name];
        if old.source_kind == "local" and source_kind != "local" {
            print("shadowed shared block " + block.name);
        } else {
            print("Block name collision: " + block.name);
        }
    } else {
        registry.manifest[block.name] = block;
    }
}

def scan_registry(registry: Registry) {
    for directory in registry.directories {
        root spawn ScanDirectories;
        visit [directory];
    }
}

def get_block(registry: Registry, name: str) -> Block | None {
    if name in registry.manifest {
        return registry.manifest[name];
    }
    return None;
}

def get_manifest(registry: Registry) -> dict[str, Block] {
    return registry.manifest;
}

def add_block(
    registry: Registry,
    directory: Directory,
    block: Block
) {
    directory.registry = registry;
    directory +>:Defines:+> block;
}

def add_child(parent: Directory, child: Directory) {
    child.registry = parent.registry;
    parent +>:Contains:+> child;
}
