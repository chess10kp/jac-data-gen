cl {
    def:pub Inner(label: str, count: int = 0) -> JsxElement {
        return <div className="inner">{label}: {count}</div>;
    }

    def:pub PassThrough(label: str, count: int = 0) -> JsxElement {
        return <Inner label={label} count={count} />;
    }
}
