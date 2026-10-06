def:pub PreviewShellStrip() -> JsxElement {
    return
        <div className="gw-preview-shell gw-glass-panel gw-fade-up gw-stagger-3">
            <div className="gw-preview-topbar">
                <div className="gw-preview-topbar-left">
                    <div className="gw-preview-pill gw-preview-pill-wide"></div>
                    <div className="gw-preview-pill gw-preview-pill-small"></div>
                </div>
                <div className="gw-preview-topbar-right">
                    <div className="gw-preview-dot"></div>
                    <div className="gw-preview-dot"></div>
                </div>
            </div>
            <div className="gw-preview-body">
                <div className="gw-preview-sidebar gw-glass-panel">
                    <div
                        className="gw-preview-sidebar-line"
                        style={{"width": "80%"}}
                    ></div>
                    <div
                        className="gw-preview-sidebar-line"
                        style={{"width": "92%"}}
                    ></div>
                    <div
                        className="gw-preview-sidebar-line"
                        style={{"width": "86%"}}
                    ></div>
                    <div
                        className="gw-preview-sidebar-line"
                        style={{"width": "68%"}}
                    ></div>
                    <div
                        className="gw-preview-sidebar-line"
                        style={{"width": "74%"}}
                    ></div>
                </div>
                <div className="gw-preview-content">
                    <div className="gw-preview-summary">
                        <div className="gw-preview-card gw-glass-panel">
                            <div className="gw-preview-card-label">
                                PR Review
                            </div>
                            <div className="gw-preview-card-value">
                                12
                            </div>
                        </div>
                        <div className="gw-preview-card gw-glass-panel">
                            <div className="gw-preview-card-label">
                                Drift Alerts
                            </div>
                            <div className="gw-preview-card-value">
                                07
                            </div>
                        </div>
                        <div className="gw-preview-card gw-glass-panel">
                            <div className="gw-preview-card-label">
                                Verdict Pace
                            </div>
                            <div className="gw-preview-card-value">
                                94%
                            </div>
                        </div>
                    </div>
                    <div className="gw-preview-graph gw-glass-panel">
                        Graph canvas reserved for live traversal playback
                    </div>
                </div>
            </div>
        </div>;
}
