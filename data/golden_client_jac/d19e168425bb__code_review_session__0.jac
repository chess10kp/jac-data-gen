cl {
    def:pub Status(active: bool) -> JsxElement {
        return <span className={("active" if active else "inactive")}>
            {("Active" if active else "Inactive")}
        </span>;
    }
}
