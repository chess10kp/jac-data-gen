"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover tree walk."""

glob MAX_HOVER: int = 64;

node Widget {
    has wid: str;
}

edge ChildWidget {}

obj WidgetTree {
    has widgets: dict[str, Widget] = {};
    has hovered: str = "";
}

walker AncestorWalk {
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Widget entry {
        if here.wid in self.claimed { disengage; }
        if len(self.chain) >= MAX_HOVER { disengage; }
        self.claimed[here.wid] = True;
        self.chain.append(here.wid);
        visit [here <-:ChildWidget:<-][?:Widget] else { disengage; }
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Widget entry {
        if here.wid not in self.claimed {
            if len(self.found) >= MAX_HOVER { disengage; }
            self.claimed[here.wid] = True;
            self.found.append(here.wid);
        }
        visit [->:ChildWidget:->][?:Widget];
    }
}

def load_widgets(
    widgets: list[str],
    parent_edges: list[tuple[str, str]],
    hovered_id: str | None = None,
) -> WidgetTree {
    tree = WidgetTree();
    for wid in widgets {
        nd = Widget(wid=wid);
        root ++> nd;
        tree.widgets[wid] = nd;
    }
    for (parent, child) in parent_edges {
        p = tree.widgets.get(parent, None);
        c = tree.widgets.get(child, None);
        if p is not None and c is not None { p +>:ChildWidget:+> c; }
    }
    if hovered_id is not None and hovered_id in tree.widgets {
        tree.hovered = hovered_id;
    }
    return tree;
}

def hovered_ancestors(store: WidgetTree) -> list[str] {
    if store.hovered == "" { return []; }
    nd = store.widgets.get(store.hovered, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk();
    return w.chain;
}

def hover_depth(store: WidgetTree) -> int {
    anc = hovered_ancestors(store);
    return len(anc) - 1 if len(anc) > 0 else 0;
}

def safe_hover_ids(store: WidgetTree) -> list[str] {
    if store.hovered == "" { return []; }
    nd = store.widgets.get(store.hovered, None);
    if nd is None { return []; }
    w = nd spawn DescendantWalk(claimed={store.hovered: True});
    return sorted(w.found);
}
