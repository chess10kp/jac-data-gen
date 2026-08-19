# components/Header.cl.jac -- automatically client-side
def:pub Header(title: str = "My App") -> JsxElement {
    return <header>{title}</header>;
}
