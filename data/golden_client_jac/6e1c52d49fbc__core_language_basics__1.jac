cl {
    import from react { useEffect }

    def:pub DataLoader() -> JsxElement {
        has data: list = [];
        has loading: bool = True;

        # Run once on mount
        useEffect(lambda -> None {
            fetch_data();
        }, []);

        # Run when dependency changes
        useEffect(lambda -> None {
            refresh_data();
        }, [some_dep]);

        return <div>...</div>;
    }
}
