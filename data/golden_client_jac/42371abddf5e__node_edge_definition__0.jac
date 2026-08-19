node Item {
    has name: str = "";
}

def:pub useItems() -> dict {
    has items: list[Item] = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    def handle_add(new_item: Item) {
        items = items + [new_item];
    }

    return {
        "items": items,
        "loading": loading,
        "handleAdd": handle_add,
    };
}
