def:pub Dialog(open: bool = False, children: JsxElement = None) -> JsxElement {
    if not open {
        return <></>;
    }
    return <div className="ui-dialog-backdrop" role="dialog" aria-modal="true">
        <div className="ui-dialog">
            {children}
        </div>
    </div>;
}

def:pub DialogHeader(children: JsxElement = None) -> JsxElement {
    return <div className="ui-dialog-header">{children}</div>;
}

def:pub DialogTitle(children: JsxElement = None) -> JsxElement {
    return <h2 className="ui-dialog-title">{children}</h2>;
}

def:pub DialogContent(children: JsxElement = None) -> JsxElement {
    return <div className="ui-dialog-content">{children}</div>;
}

def:pub DialogFooter(children: JsxElement = None) -> JsxElement {
    return <div className="ui-dialog-footer">{children}</div>;
}
