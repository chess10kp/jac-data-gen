cl {
    def:pub DataFetcher() -> JsxElement {
        has data: list = [];
        has loading: bool = True;
        has error: str = "";

        async can with entry {
            try {
                data = list(await some_async_operation());
            } except Exception as e {
                error = str(e);
            }
            loading = False;
        }

        if loading {
            return <p>Loading...</p>;
        }

        if error {
            return <p>Error: {error}</p>;
        }

        return <ul>
            {[<li>{item}</li> for item in data]}
        </ul>;
    }
}
