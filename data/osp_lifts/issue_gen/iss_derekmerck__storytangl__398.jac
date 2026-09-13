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
