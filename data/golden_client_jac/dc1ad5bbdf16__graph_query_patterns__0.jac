cl import from "@jac/runtime" { useLocation, useNavigate }

cl {
    def:pub SearchResults() -> JsxElement {
        location = useLocation();
        navigate = useNavigate();

        # Parse query parameters from location.search
        searchParams = URLSearchParams(location.search);
        query = searchParams.get("q") or "";
        page = int(searchParams.get("page") or "1");

        def updatePage(newPage: int) -> None {
            navigate(f"/search?q={query}&page={newPage}");
        }

        return <div>
            <h2>Results for: {query}</h2>
            <p>Page: {page}</p>

            <button
                onClick={lambda -> None { updatePage(page - 1); }}
                disabled={page <= 1}
            >
                Previous
            </button>

            <button onClick={lambda -> None { updatePage(page + 1); }}>
                Next
            </button>
        </div>;
    }

    # URL: /search?q=hello&page=2
}
