cl {
    import from react { useEffect }

    glob POLL_MS: int = 5000;

    def:pub LiveData() -> JsxElement {
        has data: any = None;

        async def fetch_data() -> None {
            try {
                result: any = root spawn get_live_data();
                if result.reports and result.reports.length > 0 {
                    data = result.reports[0];
                }
            } except Exception as e {
                print(f"poll failed: {e}");
            }
        }

        async can with entry { await fetch_data(); }

        useEffect(lambda {
            interval = setInterval(lambda { fetch_data(); }, POLL_MS);
            return lambda { clearInterval(interval); };
        }, []);

        return <div>{data and <p>Last updated: {data["timestamp"]}</p>}</div>;
    }
}
