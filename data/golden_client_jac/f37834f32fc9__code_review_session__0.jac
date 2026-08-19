cl {
    def:pub DataComponent() -> JsxElement {
        has data: any = None;
        has loading: bool = True;
        has error: str = "";

        if loading {
            return <div className="spinner">Loading...</div>;
        }

        if error {
            return <div className="error">{error}</div>;
        }

        if data is None {
            return <div className="empty">No data available</div>;
        }

        return <div>{data}</div>;
    }
}
