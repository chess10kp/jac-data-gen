import from .ui_helpers { severityClass }

def:pub IncidentFeedButton(incident: dict[str, str], onPick: object) -> JsxElement {
    def handleClick() -> None {
        onPick(incident["title"]);
    }

    return
        <button type="button" className="gw-feed-row" onClick={handleClick}>
            <span className="gw-feed-time">{incident["time"]}</span>
            <span className={severityClass(incident["severity"])}>
                {incident["severity"]}
            </span>
            <span className="gw-feed-copy">
                <strong>{incident["title"]}</strong>
                <span>{incident["detail"]}</span>
            </span>
            <span className="gw-feed-hint">{incident["hint"]}</span>
        </button>;
}
