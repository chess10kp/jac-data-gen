def:pub Tabs(className: str = "", children: JsxElement = None) -> JsxElement {
    return <div className={"ui-tabs " + className}>
        {children}
    </div>;
}

def:pub TabList(children: JsxElement = None) -> JsxElement {
    return <div className="ui-tab-list">
        {children}
    </div>;
}

def:pub TabButton(active: bool = False, onClick: any = None, children: JsxElement = None) -> JsxElement {
    class_name: str = "ui-tab-button";
    if active {
        class_name = "ui-tab-button active";
    }
    return <button
        type="button"
        className={class_name}
        onClick={onClick}
    >
        {children}
    </button>;
}

def:pub TabPanel(children: JsxElement = None) -> JsxElement {
    return <div className="ui-tab-panel">
        {children}
    </div>;
}
