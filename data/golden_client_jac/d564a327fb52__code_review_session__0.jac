cl {
    def:pub SafeDataView() -> JsxElement {
        has data: any = None;
        has loading: bool = True;
        has error: str = "";

        async def load_data() -> None {
            loading = True;
            error = "";
            try {
                result: any = root spawn get_data();
                if result.reports and result.reports.length > 0 {
                    data = result.reports[0];
                }
            } except Exception as e {
                error = f"Failed to load: {e}";
            }
            loading = False;
        }

        async can with entry { await load_data(); }

        if loading { return <p>Loading...</p>; }
        if error {
            return <div>
                <p>{error}</p>
                <button onClick={lambda -> None { load_data(); }}>Retry</button>
            </div>;
        }
        return <div>{JSON.stringify(data)}</div>;
    }
}
