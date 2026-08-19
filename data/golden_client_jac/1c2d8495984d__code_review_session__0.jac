cl {
    def:pub SearchBox(onSearch: any = None) -> JsxElement {
        has query: str = "";

        return <input
            type="text"
            value={query}
            onChange={lambda e: ChangeEvent {
                query = e.target.value;
                if onSearch { onSearch(e.target.value); }
            }}
            placeholder="Search..."
        />;
    }
}
