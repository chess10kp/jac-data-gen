def:pub AmbientBackground(screen: str) -> JsxElement {
    isLanding = screen == "landing";
    orbOne = (
        <div className="gw-orb gw-orb-one"></div>
            if not isLanding
        else None
    );
    return
        <div className={"gw-ambient gw-ambient-" + screen} aria-hidden="true">
            <div className="gw-light-pool gw-light-pool-one"></div>
            <div className="gw-light-pool gw-light-pool-two"></div>
            <div className="gw-light-pool gw-light-pool-three"></div>
            {orbOne}
            <div className="gw-orb gw-orb-two"></div>
            <svg
                className="gw-ambient-lines"
                viewBox="0 0 1600 1000"
                fill="none"
                preserveAspectRatio="none"
            >
                <path
                    d="M-40 320C220 210 520 210 740 326C982 454 1220 452 1640 280"
                    stroke="rgba(220,239,255,0.22)"
                    strokeWidth="1.5"
                ></path>
                <path
                    d="M-20 408C240 316 430 340 648 448C860 550 1160 582 1640 430"
                    stroke="rgba(125,211,255,0.18)"
                    strokeWidth="1.1"
                    strokeDasharray="8 12"
                ></path>
                <path
                    d="M60 760C320 680 470 624 702 700C980 790 1200 840 1540 738"
                    stroke="rgba(82,229,213,0.14)"
                    strokeWidth="1.1"
                ></path>
                <circle
                    cx="1180"
                    cy="180"
                    r="112"
                    stroke="rgba(220,239,255,0.08)"
                    strokeWidth="1"
                ></circle>
                <circle
                    cx="1180"
                    cy="180"
                    r="72"
                    stroke="rgba(220,239,255,0.08)"
                    strokeWidth="1"
                ></circle>
            </svg>
            <div className="gw-noise-layer"></div>
        </div>;
}
