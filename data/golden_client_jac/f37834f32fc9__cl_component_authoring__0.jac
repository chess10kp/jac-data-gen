cl {
    def:pub DataComponent() -> JsxElement {
        has data: any = None;
        has loading: bool = True;
        has error: str = "";

        # ... fetch data ...

        if loading {
            return <div className="spinner">Loading...</div>;
        }

        if error {
            return <div className="error">{error}</div>;
        }

        return <div>{data}</div>;
    }
}
