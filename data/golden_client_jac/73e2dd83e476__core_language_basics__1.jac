cl {
    def:pub app() -> JsxElement {
        api_url = import.meta.env.VITE_API_URL;
        return <div>{api_url}</div>;
    }
}
