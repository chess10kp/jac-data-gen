"""Rick1330/collabsphere#519 — workspace document tree endpoint."""

node Workspace {
    has workspace_id: str;
    has members: list[str] = [];
}

node DocumentItem {
    has item_id: str;
    has workspace_id: str;
    has kind: str;
    has name: str;
    has position: int = 0;
    has parent_id: str = "";
}

node TreeItem {
    has item_id: str;
    has kind: str;
    has name: str;
    has position: int = 0;
    has children: list[TreeItem] = [];
}

node TreeResponse {
    has code: str;
    has items: list[TreeItem] = [];
}

edge Contains {}

def ordered_documents(items: list[DocumentItem]) -> list[DocumentItem] {
    positions: list[int] = [];
    ordered: list[DocumentItem] = [];
    used: dict[str, bool] = {};
    for item in items {
        positions.append(item.position);
    }
    positions = sorted(positions);
    for position in positions {
        for item in items {
            if item.position == position and item.item_id not in used {
                ordered.append(item);
                used[item.item_id] = True;
                break;
            }
        }
    }
    return ordered;
}

walker TreeWalker {
    has workspace_id: str;
    has claimed: dict[str, bool] = {};
    has found: list[DocumentItem] = [];

    can collect_workspace with Workspace entry {
        print("document tree query");
        kids: list[DocumentItem] = [];
        for child in [here ->:Contains:->][?:DocumentItem] {
            if child.workspace_id == self.workspace_id and child.parent_id == "" {
                kids.append(child);
            }
        }
        kids = ordered_documents(kids);
        idx = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }

    can collect_item with DocumentItem entry {
        if here.item_id in self.claimed {
            skip;
        }
        if here.workspace_id != self.workspace_id {
            skip;
        }
        self.claimed[here.item_id] = True;
        self.found.append(here);
        kids: list[DocumentItem] = [];
        for child in [here ->:Contains:->][?:DocumentItem] {
            if child.workspace_id == self.workspace_id {
                kids.append(child);
            }
        }
        kids = ordered_documents(kids);
        idx = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

def get_documents_tree(
    workspace_id: str,
    requester_id: str,
    graph_root: Workspace
) -> TreeResponse {
    result = TreeResponse(code="OK");
    if graph_root.workspace_id != workspace_id {
        result.code = "WORKSPACE_NOT_FOUND";
        return result;
    }
    if requester_id not in graph_root.members {
        result.code = "NOT_WORKSPACE_MEMBER";
        return result;
    }

    w = graph_root spawn TreeWalker(workspace_id=workspace_id);
    views: dict[str, TreeItem] = {};
    for item in w.found {
        views[item.item_id] = TreeItem(
            item_id=item.item_id,
            kind=item.kind,
            name=item.name,
            position=item.position
        );
    }
    for item in w.found {
        view = views[item.item_id];
        if item.parent_id == "" {
            result.items.append(view);
        } elif item.parent_id in views {
            views[item.parent_id].children.append(view);
        }
    }
    return result;
}
