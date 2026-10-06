def:pub FlowCard(step: dict[str, str]) -> JsxElement {
    return
        <article
            className={"gw-flow-card gw-glass-panel gw-fade-up " + step["delay"]}
        >
            <div className="gw-flow-step">
                Step{step["step"]}
            </div>
            <div className="gw-flow-name">
                {step["title"]}
            </div>
            <div className="gw-flow-copy">
                {step["body"]}
            </div>
            <div className="gw-flow-pulse"></div>
        </article>;
}
