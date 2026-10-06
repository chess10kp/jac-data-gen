import from "@jac/runtime" { Link }
import from ..components.AmbientBackground { AmbientBackground }


def:pub page() -> JsxElement {
    return
        <div className="gw-page">
            <AmbientBackground screen="landing"/>
            <div className="gw-page-inner gw-page-inner--landing">
                <Link to="/" className="gw-role-back gw-fade-up gw-stagger-1">
                    <svg
                        className="gw-role-back-icon"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="none"
                        aria-hidden="true"
                    >
                        <path
                            d="M19 12H5M11 5l-7 7 7 7"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                        ></path>
                    </svg>
                    Back to the Landing Page
                </Link>
                <div className="gw-role-panel">
                    <div className="gw-role-head">
                        <div className="gw-kicker gw-fade-up gw-stagger-1">
                            GhostWatch
                        </div>
                        <h1 className="gw-role-title gw-fade-up gw-stagger-2">
                            How will you use GhostWatch?
                        </h1>
                        <p className="gw-role-sub gw-fade-up gw-stagger-3">
                            Pick the workspace that matches your responsibilities. This demo keeps both paths local until real accounts and repo scopes are wired in.
                        </p>
                    </div>
                    <div className="gw-role-grid">
                        <Link
                            to="/app/contributor"
                            className="gw-role-card gw-glass-panel gw-fade-up gw-stagger-4"
                        >
                            <div className="gw-role-card-kicker">
                                Contribute to Open Sourced Projects today!
                            </div>
                            <h2 className="gw-role-card-title">Contributor</h2>
                            <p className="gw-role-card-body">
                                See ranked gap suggestions after merges (tests, docs, and small implementation prompts) without the maintainer incident desk.
                            </p>
                        </Link>
                        <Link
                            to="/app/maintainer"
                            className="gw-role-card gw-glass-panel gw-fade-up gw-stagger-5"
                        >
                            <div className="gw-role-card-kicker">
                                Review, merge & guard the repo
                            </div>
                            <h2 className="gw-role-card-title">Lead maintainer</h2>
                            <p className="gw-role-card-body">
                                Open the control room for dependency incidents, walker status, escalation feeds, and the surfaces aligned with autonomous defense.
                            </p>
                        </Link>
                    </div>
                </div>
            </div>
        </div>;
}
