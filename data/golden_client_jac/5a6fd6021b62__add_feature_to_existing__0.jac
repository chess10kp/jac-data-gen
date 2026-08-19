cl def:pub app -> JsxElement {
    has darkMode: bool = False;
    return <div class={"container " + ("theme-dark" if darkMode else "theme-light")}>...</div>;
}
