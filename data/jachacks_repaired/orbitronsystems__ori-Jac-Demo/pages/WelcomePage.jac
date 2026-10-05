import from "@jac/runtime" { useNavigate }

def:pub page() -> JsxElement {
    nav = useNavigate();

    def go_dashboard(e: MouseEvent) -> None {
        nav("/dashboard");
    }

    def go_onboarding(e: MouseEvent) -> None {
        nav("/onboarding");
    }

    return (
        <div className="welcome-page">
            <nav className="welcome-nav">
                <div className="orbitron-logo">ORBITRON</div>
                <div className="flex items-center gap-3">
                    <span className="orbitron-tagline">Enterprise Resource Platform</span>
                </div>
                <div className="flex items-center gap-3">
                    <button className="btn btn-ghost" onClick={go_onboarding}>Get Started</button>
                    <button className="btn btn-primary" onClick={go_dashboard}>Launch ERP</button>
                </div>
            </nav>

            <div className="welcome-hero">
                <div className="welcome-hero-badge">
                    <span>🛰️</span>
                    <span>Next-Generation Fleet Intelligence</span>
                </div>
                <h1 className="welcome-hero-title">
                    Command Your<br />Fleet Universe
                </h1>
                <p className="welcome-hero-subtitle">
                    ORBITRON unifies fleet management, driver intelligence, real-time telemetry,
                    and AI-powered routing into one seamless enterprise platform.
                </p>
                <div className="flex items-center gap-4">
                    <button className="btn btn-primary px-8 py-3 text-base" onClick={go_dashboard}>
                        🚀 Launch Dashboard
                    </button>
                    <button className="btn btn-secondary px-8 py-3 text-base" onClick={go_onboarding}>
                        ✨ Start Onboarding
                    </button>
                </div>

                <div className="flex items-center gap-8 mt-12 text-sm text-muted-foreground">
                    <div className="flex items-center gap-2">
                        <span className="text-emerald-400 font-bold">●</span>
                        <span>2,847 Active Vehicles</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <span className="text-cyan-400 font-bold">●</span>
                        <span>98.4% Fleet Uptime</span>
                    </div>
                    <div className="flex items-center gap-2">
                        <span className="text-indigo-400 font-bold">●</span>
                        <span>AI-Optimized Routes</span>
                    </div>
                </div>
            </div>

            <div className="welcome-features">
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">🚛</div>
                    <div className="welcome-feature-title">Fleet Management</div>
                    <div className="welcome-feature-desc">
                        Real-time tracking, maintenance scheduling, and vehicle lifecycle management across your entire fleet.
                    </div>
                </div>
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">🧠</div>
                    <div className="welcome-feature-title">AI Intelligence Hub</div>
                    <div className="welcome-feature-desc">
                        Predictive analytics, anomaly detection, and smart recommendations powered by machine learning.
                    </div>
                </div>
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">📡</div>
                    <div className="welcome-feature-title">Real-time Telemetry</div>
                    <div className="welcome-feature-desc">
                        Live sensor data, GPS tracking, fuel monitoring, and driver behavior analytics at your fingertips.
                    </div>
                </div>
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">🗺️</div>
                    <div className="welcome-feature-title">Smart Routing</div>
                    <div className="welcome-feature-desc">
                        Dynamic route optimization with traffic, weather, and load balancing for maximum efficiency.
                    </div>
                </div>
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">💰</div>
                    <div className="welcome-feature-title">Monetization Engine</div>
                    <div className="welcome-feature-desc">
                        Revenue tracking, cost analysis, and profitability insights to maximize your fleet ROI.
                    </div>
                </div>
                <div className="welcome-feature-card">
                    <div className="welcome-feature-icon">🏆</div>
                    <div className="welcome-feature-title">Driver Rewards</div>
                    <div className="welcome-feature-desc">
                        Gamified performance surveys, reward programs, and driver engagement tools to boost retention.
                    </div>
                </div>
            </div>
        </div>
    );
}
