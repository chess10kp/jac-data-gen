cl {
    # jac:ignore[W5015]
    def:pub PassThrough(props: dict) -> JsxElement {
        return <Inner {**props} />;
    }
}
