cl {
    def:pub SearchResults() -> JsxElement {
        has query: str = "";
        has results: list = [];

        async can with [query] entry {
            if query {
                results = list(await search_api(query));
            } else {
                results = [];
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
