def:pub Alert(tone: str = "info", children: JsxElement = None) -> JsxElement {
    return <div className={"ui-alert ui-alert-" + tone} role="alert">
        {children}
    </div>;
}
