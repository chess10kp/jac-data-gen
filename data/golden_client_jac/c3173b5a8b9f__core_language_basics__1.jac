cl {
    import from react { useEffect }

    def:pub DataFetcher() -> JsxElement {
        has data: list = [];

        useEffect(lambda -> None {
            fetch_data();
        }, []);

        return <div>...</div>;
    }
}
