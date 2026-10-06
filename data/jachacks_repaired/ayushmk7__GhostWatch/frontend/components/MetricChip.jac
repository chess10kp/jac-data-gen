def:pub MetricChip(metric: dict[str, str]) -> JsxElement {
    return
        <div
            className={"gw-metric-chip gw-glass-panel gw-fade-up " + metric[
                "delay"
            ]}
        >
            <div className="gw-metric-value">
                {metric["value"]}
            </div>
            <div className="gw-metric-label">
                {metric["label"]}
            </div>
            <div className="gw-metric-detail">
                {metric["detail"]}
            </div>
        </div>;
}
