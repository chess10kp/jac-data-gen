cl {
    def:pub DataView() -> JsxElement {
        has data: any = None;
        has loading: bool = True;
        has error: str = "";

        async can with entry {
            await fetch_data();
        }

        async def fetch_data() -> None {
            loading = True;
            error = "";
            try {
                result = root spawn get_data();
                if result.reports and result.reports.length > 0 {
                    data = result.reports[0];
                }
            } except Exception as e {
                error = f"Failed to load: {e}";
            }
            loading = False;
        }

        if loading {
            return <div className="skeleton">
                <div className="skeleton-line"></div>
                <div className="skeleton-line"></div>
            </div>;
        }

        if error {
            return <div className="error">
                <p>{error}</p>
                <button onClick={lambda -> None { fetch_data(); }}>
                    Retry
                </button>
            </div>;
        }

        return <div className="data">
            {JSON.stringify(data)}
        </div>;
    }
}
