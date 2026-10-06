def:pub Badge(tone: str = "neutral", className: str = "", children: JsxElement = None) -> JsxElement {
    return <span className={"ui-badge ui-badge-" + tone + " " + className}>
        {children}
    </span>;
}
