def:pub Table(className: str = "", children: JsxElement = None) -> JsxElement {
    return <div className="ui-table-wrap">
        <table className={"ui-table " + className}>
            {children}
        </table>
    </div>;
}

def:pub TableHead(children: JsxElement = None) -> JsxElement {
    return <thead>{children}</thead>;
}

def:pub TableBody(children: JsxElement = None) -> JsxElement {
    return <tbody>{children}</tbody>;
}

def:pub TableRow(children: JsxElement = None) -> JsxElement {
    return <tr>{children}</tr>;
}

def:pub TableHeader(children: JsxElement = None) -> JsxElement {
    return <th>{children}</th>;
}

def:pub TableCell(children: JsxElement = None) -> JsxElement {
    return <td>{children}</td>;
}
