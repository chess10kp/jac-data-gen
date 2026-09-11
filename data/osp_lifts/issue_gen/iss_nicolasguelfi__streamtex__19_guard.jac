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

test "diamond revisit keeps complete closure" {
    reg = Registry();
    root = Directory(path="blocks");
    left = Directory(path="blocks/left");
    right = Directory(path="blocks/right");
    shared = Directory(path="blocks/shared");
    item = Block(name="glossary", path="blocks/shared/bck_glossary.py");

    register_directory(reg, root, "local", 0, "");
    register_directory(reg, left, "shared", 1, "left");
    register_directory(reg, right, "shared", 1, "right");
    register_directory(reg, shared, "shared", 1, "shared");
    add_child(root, left);
    add_child(root, right);
    add_child(left, shared);
    add_child(right, shared);
    add_block(reg, shared, item);
    scan_registry(reg);

    assert (len(reg.manifest) == 1);
    assert (get_block(reg, "glossary").path == "blocks/shared/bck_glossary.py");
}

test "unknown block is tolerated" {
    reg = Registry();
    missing = get_block(reg, "does_not_exist");
    assert (missing == None);
}

test "local block shadows shared block" {
    reg = Registry();
    local_dir = Directory(path="project/blocks");
    shared_dir = Directory(path="shared-blocks/blocks");
    local = Block(name="terms", path="project/blocks/bck_terms.py");
    shared = Block(name="terms", path="shared-blocks/blocks/bck_terms.py");

    register_directory(reg, local_dir, "local", 0, "");
    register_directory(reg, shared_dir, "shared", 1, "");
    add_block(reg, local_dir, local);
    add_block(reg, shared_dir, shared);
    scan_registry(reg);

    assert (get_block(reg, "terms").path == "project/blocks/bck_terms.py");
}

test "recursive subdirectory metadata is preserved" {
    reg = Registry();
    root = Directory(path="shared-blocks/blocks");
    trainers = Directory(path="shared-blocks/blocks/trainers");
    trainer = Block(name="trainer_ng", path="shared-blocks/blocks/trainers/bck_trainer_ng.py");

    register_directory(reg, root, "shared", 1, "");
    register_directory(reg, trainers, "shared", 1, "trainers");
    add_child(root, trainers);
    add_block(reg, trainers, trainer);
    scan_registry(reg);

    assert (get_block(reg, "trainer_ng").source_dir == "shared-blocks/blocks/trainers");
    assert (get_block(reg, "trainer_ng").subdirectory == "trainers");
}
