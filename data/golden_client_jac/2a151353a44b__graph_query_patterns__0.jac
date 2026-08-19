cl {
    def:pub SearchResults() -> JsxElement {
        has query: str = "";
        has results: list = [];

        # Run when query changes
        async can with [query] entry {
            if query {
                results = await search_api(query);
            }
        }

        return <div>
            <input
                value={query}
                onChange={lambda e: ChangeEvent { query = e.target.value; }}
            />
            <ul>
                {[<li>{r}</li> for r in results]}
            </ul>
        </div>;
    }
}
