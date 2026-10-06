import from .FeatureGlyph { FeatureGlyph }

def:pub FeatureCard(feature: dict[str, str]) -> JsxElement {
    return
        <article
            className={"gw-feature-card gw-glass-panel gw-fade-up " + feature["delay"]}
        >
            <div className="gw-feature-icon">
                <FeatureGlyph kind={feature["kind"]}/>
            </div>
            <h3 className="gw-feature-title">{feature["title"]}</h3>
            <p className="gw-feature-body">{feature["body"]}</p>
        </article>;
}
