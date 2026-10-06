def:pub Card(className: str = "", children: JsxElement = None) -> JsxElement {
    return <section className={"ui-card " + className}>
        {children}
    </section>;
}

def:pub CardHeader(children: JsxElement = None) -> JsxElement {
    return <div className="ui-card-header">
        {children}
    </div>;
}

def:pub CardTitle(children: JsxElement = None) -> JsxElement {
    return <h2 className="ui-card-title">{children}</h2>;
}

def:pub CardDescription(children: JsxElement = None) -> JsxElement {
    return <p className="ui-card-description">{children}</p>;
}

def:pub CardContent(children: JsxElement = None) -> JsxElement {
    return <div className="ui-card-content">
        {children}
    </div>;
}
