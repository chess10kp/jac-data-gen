# iss_SanchayPahalwani__BlockWorks__1.jac

node BlockSpec {
    has block_id: str;
    has version: str;
    has output_schema: str;
    has engine: str = "polars";
    has storage: str = "parquet";
    has elapsed_ms: int = 0;
}

node Block {
    has block_id: str;
    has version: str;
    has output_schema: str;
    has engine: str;
    has storage: str;
    has elapsed_ms: int;
}

node Catalog {
    has blocks: dict[str, Block] = {};
}

edge Contains {}
edge DependsOn {}
edge Feeds {}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Block entry {
        if here.block_id in self.claimed { skip; }
        self.claimed[here.block_id] = True;
        self.found.append(here.block_id);
        print(here.block_id);
        for dep in [here ->:DependsOn:->][?:Block] {
            visit :0: [dep];
        }
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Block entry {
        if here.block_id in self.claimed { skip; }
        self.claimed[here.block_id] = True;
        self.found.append(here.block_id);
        print(here.block_id);
        for child in [here ->:Feeds:->][?:Block] {
            visit :0: [child];
        }
    }
}

walker SlowWalk {
    has threshold: int = 0;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_catalog with Catalog entry {
        print("catalog");
        for block in [here ->:Contains:->][?:Block] {
            visit :0: [block];
        }
    }

    can step_block with Block entry {
        if here.block_id in self.claimed { skip; }
        self.claimed[here.block_id] = True;
        print(here.block_id);
        if here.elapsed_ms >= self.threshold {
            self.found.append(here.block_id);
        }
    }
}

def create_catalog() -> Catalog {
    return Catalog(blocks={});
}

def make_spec(
    block_id: str,
    version: str,
    output_schema: str,
    engine: str,
    storage: str,
    elapsed_ms: int
) -> BlockSpec {
    return BlockSpec(
        block_id=block_id,
        version=version,
        output_schema=output_schema,
        engine=engine,
        storage=storage,
        elapsed_ms=elapsed_ms
    );
}

def register_block(catalog: Catalog, spec: BlockSpec) -> Block {
    block = Block(
        block_id=spec.block_id,
        version=spec.version,
        output_schema=spec.output_schema,
        engine=spec.engine,
        storage=spec.storage,
        elapsed_ms=spec.elapsed_ms
    );
    catalog.blocks[spec.block_id] = block;
    catalog +>:Contains:+> block;
    return block;
}

def link_blocks(
    catalog: Catalog,
    downstream_id: str,
    upstream_id: str
) -> bool {
    if downstream_id not in catalog.blocks { return False; }
    if upstream_id not in catalog.blocks { return False; }
    downstream = catalog.blocks[downstream_id];
    upstream = catalog.blocks[upstream_id];
    downstream +>:DependsOn:+> upstream;
    upstream +>:Feeds:+> downstream;
    return True;
}

def upstream_lineage(catalog: Catalog, block_id: str) -> list[str] {
    if block_id not in catalog.blocks { return []; }
    target = catalog.blocks[block_id];
    w = target spawn LineageWalk(claimed={}, found=[]);
    return w.found;
}

def downstream_lineage(catalog: Catalog, block_id: str) -> list[str] {
    if block_id not in catalog.blocks { return []; }
    target = catalog.blocks[block_id];
    w = target spawn DescendantWalk(claimed={}, found=[]);
    return w.found;
}

def slow_blocks(catalog: Catalog, threshold: int) -> list[str] {
    w = catalog spawn SlowWalk(threshold=threshold, claimed={}, found=[]);
    return w.found;
}
