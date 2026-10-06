import from "@jac/runtime" { Link }
import from ..mock_data { LANDING_FEATURES, FLOW_STEPS }
import from ..components.AmbientBackground { AmbientBackground }
import from ..components.GhostWatchWordmark { GhostWatchWordmark }
import from ..components.GhostShieldMark { GhostShieldMark }
import from ..components.FeatureCard { FeatureCard }
import from ..components.FlowCard { FlowCard }


def:pub page() -> JsxElement {
    return
        <div className="gw-page">
            <AmbientBackground screen="landing"/>
            <div className="gw-page-inner gw-page-inner--landing">
                <div className="gw-landing-fold">
                    <header
                        className="gw-shell-nav gw-shell-nav--balanced gw-glass-panel gw-fade-up gw-stagger-1"
                    >
                        <GhostWatchWordmark/>
                        <nav className="gw-header-links">
                            <a href="#capabilities" className="gw-nav-link">
                                Capabilities
                            </a>
                            <a href="#flow" className="gw-nav-link">Flow</a>
                        </nav>
                        <Link
                            to="/start"
                            className="gw-glass-button gw-button-primary gw-nav-cta gw-cta-rise-only"
                        >
                            Get started
                        </Link>
                    </header>
                    <section className="gw-hero gw-hero-landing" id="product">
                        <div className="gw-hero-landing-center">
                            <div
                                className="gw-hero-landing-backdrop"
                                aria-hidden="true"
                            >
                                <div className="gw-hero-landing-orb-anim gw-float-slow">
                                    <div
                                        className="gw-hero-landing-orb gw-fade-in gw-stagger-2"
                                    >
                                        <div className="gw-hero-landing-orb-shield">
                                            <GhostShieldMark/>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div className="gw-hero-landing-content">
                                <div className="gw-kicker gw-fade-in gw-stagger-2">
                                    Midnight observatory for code guardians
                                </div>
                                <h1 className="gw-hero-title gw-fade-in gw-stagger-3">
                                    Autonomous code defense, rendered in graph-native clarity.
                                </h1>
                                <p className="gw-hero-text gw-fade-in gw-stagger-4">
                                    GhostWatch reviews pull requests, monitors dependency movement, and surfaces risk through a premium control room that already feels alive before the live graph ever attaches.
                                </p>
                                <div className="gw-hero-pillars">
                                    <div
                                        className="gw-hero-pillar gw-glass-panel gw-fade-in gw-stagger-5"
                                    >
                                        PR Review
                                    </div>
                                    <div
                                        className="gw-hero-pillar gw-glass-panel gw-fade-in gw-stagger-6"
                                    >
                                        Supply Chain
                                    </div>
                                    <div
                                        className="gw-hero-pillar gw-glass-panel gw-fade-in gw-stagger-7"
                                    >
                                        Blast Radius
                                    </div>
                                    <div
                                        className="gw-hero-pillar gw-glass-panel gw-fade-in gw-stagger-8"
                                    >
                                        Maintainer Control
                                    </div>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
                <main className="gw-landing-main">
                    <section className="gw-section" id="capabilities">
                        <div className="gw-section-head">
                            <div className="gw-kicker gw-fade-up gw-stagger-1">
                                Why it feels different
                            </div>
                            <h2 className="gw-section-title gw-fade-up gw-stagger-2">
                                Premium calm instead of dashboard sameness.
                            </h2>
                            <p className="gw-section-copy gw-fade-up gw-stagger-3">
                                GhostWatch leans into liquid glass depth, high-trust typography, and structured motion so the interface looks intentional before you even inspect the data layer.
                            </p>
                        </div>
                        <div className="gw-feature-grid">
                            {[
                                <FeatureCard key={feature["kind"]} feature={feature}/>
                                for feature in LANDING_FEATURES
                            ]}
                        </div>
                    </section>
                    <section className="gw-section" id="flow">
                        <div className="gw-section-head">
                            <div className="gw-kicker gw-fade-up gw-stagger-1">
                                How GhostWatch operates
                            </div>
                            <h2 className="gw-section-title gw-fade-up gw-stagger-2">
                                Five deliberate beats, not one opaque black box.
                            </h2>
                            <p className="gw-section-copy gw-fade-up gw-stagger-3">
                                The frontend should make each stage legible so maintainers can feel the review pipeline breathing instead of guessing what happened behind the screen.
                            </p>
                        </div>
                        <div className="gw-flow-grid">
                            {[
                                <FlowCard key={step["step"]} step={step}/>
                                for step in FLOW_STEPS
                            ]}
                        </div>
                    </section>
                </main>
                <div
                    className="gw-landing-bottom-bar gw-glass-panel gw-fade-up gw-stagger-2"
                >
                    <span className="gw-landing-bottom-bar-text">Impressed?</span>
                    <Link
                        to="/start"
                        className="gw-glass-button gw-button-primary gw-cta-rise-only gw-landing-bottom-cta"
                    >
                        Get started
                    </Link>
                </div>
            </div>
        </div>;
}
