def:pub SidebarNavButton(
    item: dict[str, str], activeSection: str, onPick: object
) -> JsxElement {
    iconLabel = item["icon"] if "icon" in item else "";
    noIconClass = " gw-sidebar-item--no-icon" if iconLabel == "" else "";
    buttonClass = (
        (
            "gw-sidebar-item is-active"
                if activeSection == item["label"]
                else "gw-sidebar-item"
        )
            + noIconClass
    );

    def handleClick() -> None {
        onPick(item["label"]);
    }
    return
        <button
            type="button"
            className={buttonClass}
            onClick={handleClick}
        >
            {iconLabel != "" and
                <span className="gw-sidebar-icon">
                    {iconLabel}
                </span>}
            <span className="gw-sidebar-copy">
                <strong>
                    {item["label"]}
                </strong>
                <span>
                    {item["meta"]}
                </span>
            </span>
        </button>;
}
