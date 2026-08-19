"""Little X - Entry point combining backend and frontend."""

def:pub health() -> str {
    return "ok";
}

cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
