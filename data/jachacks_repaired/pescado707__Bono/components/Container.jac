"""Container component for the Jac client application."""

def:pub Container(children: any = None, maxWidth: str = "960px") -> JsxElement {
    return <div
        className="mx-auto px-4 w-full"
        style={{"maxWidth": maxWidth}}
    >
        {children}
    </div>;
}
