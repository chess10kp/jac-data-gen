sv {
    def:pub fetch_items() -> list[dict] {
        return [{"id": 1, "name": "Item A"}];
    }
}

cl {
    def:pub ItemList() -> JsxElement {
        has items: list[dict] = [];

        async can with entry {
            result = await fetch_items();
            items = result;
        }

        return <ul>{[<li key={it["id"]}>{it["name"]}</li> for it in items]}</ul>;
    }
}
