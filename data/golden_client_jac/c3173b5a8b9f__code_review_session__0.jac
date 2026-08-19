cl {
    import from react { useEffect }

    def:pub DataFetcher() -> JsxElement {
        has data: list = [];

        useEffect(lambda -> None {
            data = list(fetch_data());
        }, []);

        return <ul>
            {[<li>{item}</li> for item in data]}
        </ul>;
    }
}
