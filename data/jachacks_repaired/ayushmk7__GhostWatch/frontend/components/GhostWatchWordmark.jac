def:pub GhostWatchWordmark(showSubtitle: bool = True) -> JsxElement {
    return
        <div className="gw-wordmark">
            <div className="gw-mark" aria-hidden="true">
                <span className="gw-mark-core"></span>
                <span className="gw-mark-orbit gw-mark-orbit-one"></span>
                <span className="gw-mark-orbit gw-mark-orbit-two"></span>
            </div>
            <div className="gw-wordmark-copy">
                <span className="gw-wordmark-title">
                    GhostWatch
                </span>
                {showSubtitle and
                    <span className="gw-wordmark-subtitle">
                        Autonomous code defense
                    </span>}
            </div>
        </div>;
}
