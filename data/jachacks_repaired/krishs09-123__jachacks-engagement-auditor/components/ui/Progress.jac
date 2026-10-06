def:pub Progress(value: int = 0, label: str = "") -> JsxElement {
    return <div className="ui-progress" aria-label={label}>
        <div className="ui-progress-track">
            <div className="ui-progress-fill" style={{"width": f"{value}%"}} />
        </div>
        <span className="ui-progress-value">{value}/100</span>
    </div>;
}
