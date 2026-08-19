cl {
    def:pub Footer(version: str, year: int) -> JsxElement {
        return <p>Version: {version} - (c) {year}</p>;
    }
}
