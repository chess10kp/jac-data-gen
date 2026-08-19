node Item {
    has title: str;
    has done: bool = False;
}


# Public - anyone can call.
def:pub list_items() -> list[Item] {
    return [root -->][?:Item];
}

def:pub add_item(title: str) -> Item {
    return (root ++> Item(title=title))[0];
}

def:pub toggle_item(id: str) -> Item | None {
    for i in [root -->][?:Item] {
        if jid(i) == id {
            i.done = not i.done;
            return i;
        }
    }
    return None;
}

def:pub delete_item(id: str) -> bool {
    for i in [root -->][?:Item] {
        if jid(i) == id {
            del i;
            return True;
        }
    }
    return False;
}


# Private - requires login; root is the current user's subgraph.
def:priv get_my_items() -> list[Item] {
    return [root -->][?:Item];
}


# Internal helper - the leading `_` keeps it OFF the API. (A plain `def` with no
# underscore would itself be registered as an authenticated endpoint.)
def _compute_age(item: Item) -> int {
    return len(item.title);
}
