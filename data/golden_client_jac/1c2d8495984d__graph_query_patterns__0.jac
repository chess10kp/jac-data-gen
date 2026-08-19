cl {
    def:pub SearchBox() -> JsxElement {
        has query: str = "";

        return <input
            type="text"
            value={query}
            onChange={lambda e: ChangeEvent { query = e.target.value; }}
            placeholder="Search..."
        />;
    }
}
