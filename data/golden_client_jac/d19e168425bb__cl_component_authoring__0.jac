cl {
    def:pub Status(active: bool) -> JsxElement {
        return <span>
            {("Active" if active else "Inactive")}
        </span>;
    }
}
