import from .ui_helpers { walkerStateClass }

def:pub WalkerStatusItem(status_item: dict[str, str]) -> JsxElement {
    return
        <div className="gw-right-item">
            <div>
                <strong>{status_item["name"]}</strong>
            </div>
            <span className={walkerStateClass(status_item["state"])}>
                {status_item["state"]}
            </span>
        </div>;
}
