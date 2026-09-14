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

test "diamond lineage claims each block once" {
    catalog = create_catalog();
    register_block(catalog, make_spec("a", "1", "rows", "polars", "parquet", 4));
    register_block(catalog, make_spec("b", "1", "rows", "polars", "parquet", 8));
    register_block(catalog, make_spec("c", "1", "rows", "datafusion", "parquet", 12));
    register_block(catalog, make_spec("d", "1", "rows", "polars", "parquet", 20));
    assert (link_blocks(catalog, "d", "b"));
    assert (link_blocks(catalog, "d", "c"));
    assert (link_blocks(catalog, "b", "a"));
    assert (link_blocks(catalog, "c", "a"));
    lineage = upstream_lineage(catalog, "d");
    assert (len(lineage) == 4);
    assert (sorted(lineage) == ["a", "b", "c", "d"]);
}

test "unknown identifiers are tolerated" {
    catalog = create_catalog();
    register_block(catalog, make_spec("only", "1", "rows", "polars", "parquet", 1));
    assert (link_blocks(catalog, "missing", "only") == False);
    assert (link_blocks(catalog, "only", "missing") == False);
    assert (upstream_lineage(catalog, "missing") == []);
    assert (downstream_lineage(catalog, "missing") == []);
}

test "downstream traversal follows workflow edges" {
    catalog = create_catalog();
    register_block(catalog, make_spec("source", "1", "rows", "polars", "parquet", 2));
    register_block(catalog, make_spec("middle", "1", "rows", "polars", "parquet", 3));
    register_block(catalog, make_spec("sink", "1", "rows", "datafusion", "parquet", 30));
    assert (link_blocks(catalog, "middle", "source"));
    assert (link_blocks(catalog, "sink", "middle"));
    descendants = downstream_lineage(catalog, "source");
    assert (sorted(descendants) == ["middle", "sink", "source"]);
}

test "slow block threshold handles boundary values" {
    catalog = create_catalog();
    register_block(catalog, make_spec("fast", "1", "rows", "polars", "parquet", 9));
    register_block(catalog, make_spec("slow", "1", "rows", "datafusion", "parquet", 10));
    assert (sorted(slow_blocks(catalog, 10)) == ["slow"]);
    assert (sorted(slow_blocks(catalog, 11)) == []);
}
