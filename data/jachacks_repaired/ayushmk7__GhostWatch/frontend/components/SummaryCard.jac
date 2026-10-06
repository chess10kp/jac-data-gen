import from .ui_helpers { toneClass }

def:pub SummaryCard(card: dict[str, str]) -> JsxElement {
    return
        <article className={toneClass(card["tone"])}>
            <div className="gw-summary-label">{card["label"]}</div>
            <div className="gw-summary-value">{card["value"]}</div>
            <div className="gw-summary-delta">{card["delta"]}</div>
            <svg
                className="gw-summary-spark"
                viewBox="0 0 280 48"
                fill="none"
                aria-hidden="true"
            >
                <polyline
                    points={card["spark"]}
                    stroke="rgba(220,239,255,0.82)"
                    strokeWidth="2.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                ></polyline>
            </svg>
        </article>;
}
