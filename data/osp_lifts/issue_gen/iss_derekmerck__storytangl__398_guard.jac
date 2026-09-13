node Block {
    has block_id: str;
    has title: str;
    has fragments: list[str] = [];
    has first_read_id: str = "";
    has continue_id: str = "";
}

node WorldBundle {
    has entry_id: str;
    has blocks: list[Block] = [];
}

edge Choice {
    has edge_id: str;
    has label: str;
}

walker Dfs {
    has claimed: dict[str, bool] = {};
    has order: list[Block] = [];

    can walk with Block entry {
        if here.block_id in self.claimed {
            skip;
        }
        self.claimed[here.block_id] = True;
        self.order.append(here);
        print(here.block_id);

        kids: list[Block] = [];
        for child in [here ->:Choice:->][?:Block] {
            kids.append(child);
        }

        pos: int = len(kids) - 1;
        while pos >= 0 {
            kid: Block = kids[pos];
            visit :0: [kid];
            pos -= 1;
        }
    }
}

def compile_world(bundle: WorldBundle) -> Block | None {
    for block in bundle.blocks {
        if block.block_id == bundle.entry_id {
            return block;
        }
    }
    return None;
}

def publication_order(root_node: Block) -> list[Block] {
    dfs_result = root_node spawn Dfs(claimed={});
    return dfs_result.order;
}

def find_block(root_node: Block, wanted: str) -> Block | None {
    pages: list[Block] = publication_order(root_node);
    for page in pages {
        if page.block_id == wanted {
            return page;
        }
    }
    return None;
}

def preview_block(block: Block) -> list[str] {
    preview: list[str] = [];
    for fragment in block.fragments {
        preview.append(fragment);
    }
    return preview;
}

def render_markdown(root_node: Block) -> str {
    pages: list[Block] = publication_order(root_node);
    markdown: str = "";

    for block in pages {
        markdown += "<a id=\"" + block.block_id + "\"></a>\n";
        markdown += "## " + block.title + "\n\n";

        for fragment in preview_block(block) {
            markdown += fragment + "\n\n";
        }

        if block.first_read_id != "" {
            target = find_block(root_node, block.first_read_id);
            if target != None {
                markdown += "**First read:** [" + target.title + "](#" +
                    target.block_id + ")\n\n";
            }
        }

        for child in [block ->:Choice:->][?:Block] {
            markdown += "- [" + child.title + "](#" + child.block_id + ")\n";
        }

        if block.continue_id != "" {
            target = find_block(root_node, block.continue_id);
            if target != None {
                markdown += "\n**Continue:** [" + target.title + "](#" +
                    target.block_id + ")\n";
            }
        }
        markdown += "\n";
    }
    return markdown;
}

def publish_gamebook(root_node: Block) -> str {
    return render_markdown(root_node);
}

test "diamond revisit is visited once" {
    graph_root = Block(block_id="root", title="Root");
    left = Block(block_id="left", title="Left");
    right = Block(block_id="right", title="Right");
    leaf = Block(block_id="leaf", title="Leaf");

    graph_root +>:Choice(edge_id="root-left", label="Left"):+> left;
    graph_root +>:Choice(edge_id="root-right", label="Right"):+> right;
    left +>:Choice(edge_id="left-leaf", label="Leaf"):+> leaf;
    right +>:Choice(edge_id="right-leaf", label="Leaf"):+> leaf;

    order = publication_order(graph_root);
    assert (len(order) == 4);
    assert (order[0].block_id == "root");
    assert (order[1].block_id == "left");
    assert (order[2].block_id == "leaf");
    assert (order[3].block_id == "right");
}

test "unknown identifiers are tolerated" {
    graph_root = Block(block_id="start", title="Start");
    known = find_block(graph_root, "start");
    missing = find_block(graph_root, "missing");

    assert (known != None);
    assert (known.block_id == "start");
    assert (missing == None);
}

test "empty block previews and publishes" {
    graph_root = Block(block_id="solo", title="Solo");
    preview = preview_block(graph_root);
    markdown = render_markdown(graph_root);

    assert (len(preview) == 0);
    assert ("Solo" in markdown);
    assert ("solo" in markdown);
}

test "bundle compilation selects its declared entry" {
    graph_root = Block(block_id="entry", title="Entry");
    other = Block(block_id="other", title="Other");
    bundle = WorldBundle(entry_id="entry");
    bundle.blocks.append(other);
    bundle.blocks.append(graph_root);

    compiled = compile_world(bundle);
    assert (compiled != None);
    assert (compiled.block_id == "entry");
}
