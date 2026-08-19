cl {
    import from react { useEffect }

    def:pub LiveData() -> JsxElement {
        has data: any = None;
        has loading: bool = True;

        async def fetch_data() -> None {
            try {
                result = root spawn get_live_data();
                if result.reports and result.reports.length > 0 {
                    data = result.reports[0];
                }
            } except Exception as e {
                print(f"Poll failed: {e}");
            }
            loading = False;
        }

        # Initial fetch
        async can with entry {
            await fetch_data();
        }

        # Poll every 5 seconds. The outer lambda must NOT be annotated `-> None`:
        # a cleanup effect returns a function, so `-> None` would be a type error.
        useEffect(lambda {
            interval = setInterval(lambda { fetch_data(); }, 5000);
            return lambda { clearInterval(interval); };
        }, []);

        return <div>
            {loading and <p>Loading...</p>}
            {data and <p>Last updated: {data["timestamp"]}</p>}
        </div>;
    }
}
