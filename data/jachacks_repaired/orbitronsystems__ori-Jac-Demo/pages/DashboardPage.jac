import from "@jac/runtime" { useNavigate }
import from .dashboard.FleetModule { FleetModule }
import from .dashboard.DriverModule { DriverModule }
import from .dashboard.OperationsModule { OperationsModule }
import from .dashboard.AIHubModule { AIHubModule }
import from .dashboard.TelemetryModule { TelemetryModule }
import from .dashboard.RoutingModule { RoutingModule }
import from .dashboard.AnalyticsModule { AnalyticsModule }
import from .dashboard.MonetizationModule { MonetizationModule }
import from .dashboard.SurveyModule { SurveyModule }

def SidebarItem(icon: str, label: str, module_id: str, active_module: str, onSelect: Any) -> JsxElement {
    is_active: bool = active_module == module_id;
    cls: str = "sidebar-item " + ("active" if is_active else "");

    def handle_click(e: MouseEvent) -> None {
        if onSelect { onSelect(module_id); }
    }

    return (
        <button className={cls} onClick={handle_click}>
            <span className="sidebar-item-icon">{icon}</span>
            <span>{label}</span>
        </button>
    );
}

def:pub page() -> JsxElement {
    has active_module: str = "overview";
    has sidebar_collapsed: bool = False;

    nav = useNavigate();

    def select_module(mod: str) -> None {
        active_module = mod;
    }

    def select_overview(e: MouseEvent) -> None { active_module = "overview"; }
    def select_fleet(e: MouseEvent) -> None { active_module = "fleet"; }
    def select_driver(e: MouseEvent) -> None { active_module = "driver"; }
    def select_ops(e: MouseEvent) -> None { active_module = "operations"; }
    def select_ai(e: MouseEvent) -> None { active_module = "ai"; }
    def select_telemetry(e: MouseEvent) -> None { active_module = "telemetry"; }
    def select_routing(e: MouseEvent) -> None { active_module = "routing"; }
    def select_analytics(e: MouseEvent) -> None { active_module = "analytics"; }
    def select_monetization(e: MouseEvent) -> None { active_module = "monetization"; }
    def select_survey(e: MouseEvent) -> None { active_module = "survey"; }

    def go_welcome(e: MouseEvent) -> None {
        nav("/");
    }

    module_labels = {
        "overview": "Main Dashboard",
        "fleet": "Fleet Management",
        "driver": "Driver Management",
        "operations": "Operations",
        "ai": "AI Intelligence Hub",
        "telemetry": "Real-time Telemetry",
        "routing": "Smart Routing",
        "analytics": "Analytics & Reporting",
        "monetization": "Monetization",
        "survey": "Driver Survey & Rewards",
    };

    current_label: str = str(module_labels[active_module]) if active_module in module_labels else "Dashboard";

    return (
        <div className="erp-layout">
            <aside className="sidebar">
                <div className="sidebar-header">
                    <div className="orbitron-logo">ORBITRON</div>
                    <div className="orbitron-tagline mt-1">Enterprise Resource Platform</div>
                </div>

                <nav className="sidebar-nav">
                    <div className="sidebar-section">
                        <div className="sidebar-section-label">Overview</div>
                        <SidebarItem icon="🏠" label="Main Dashboard" module_id="overview" active_module={active_module} onSelect={select_module} />
                    </div>

                    <div className="sidebar-section">
                        <div className="sidebar-section-label">Fleet & Drivers</div>
                        <SidebarItem icon="🚛" label="Fleet Management" module_id="fleet" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="👤" label="Driver Management" module_id="driver" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="⚙️" label="Operations" module_id="operations" active_module={active_module} onSelect={select_module} />
                    </div>

                    <div className="sidebar-section">
                        <div className="sidebar-section-label">Intelligence</div>
                        <SidebarItem icon="🧠" label="AI Hub" module_id="ai" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="📡" label="Telemetry" module_id="telemetry" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="🗺️" label="Smart Routing" module_id="routing" active_module={active_module} onSelect={select_module} />
                    </div>

                    <div className="sidebar-section">
                        <div className="sidebar-section-label">Business</div>
                        <SidebarItem icon="📊" label="Analytics" module_id="analytics" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="💰" label="Monetization" module_id="monetization" active_module={active_module} onSelect={select_module} />
                        <SidebarItem icon="🏆" label="Driver Rewards" module_id="survey" active_module={active_module} onSelect={select_module} />
                    </div>
                </nav>

                <div className="sidebar-footer">
                    <button className="sidebar-item w-full" onClick={go_welcome}>
                        <span className="sidebar-item-icon">←</span>
                        <span>Back to Home</span>
                    </button>
                </div>
            </aside>

            <div className="erp-main">
                <header className="erp-topbar">
                    <div className="flex items-center gap-3">
                        <div className="text-sm font-bold text-foreground">{current_label}</div>
                        <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold text-emerald-400" style={{"background": "rgba(16,185,129,0.1)", "border": "1px solid rgba(16,185,129,0.2)"}}>
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block"></span>
                            Live
                        </div>
                    </div>
                    <div className="flex items-center gap-4">
                        <div className="text-xs text-muted-foreground">Fleet Status: <span className="text-emerald-400 font-bold">98.4% Uptime</span></div>
                        <div className="text-xs text-muted-foreground">|</div>
                        <div className="text-xs text-muted-foreground">Active Vehicles: <span className="text-foreground font-bold">2,847</span></div>
                        <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm cursor-pointer">A</div>
                    </div>
                </header>

                <main className="erp-content">
                    {active_module == "overview" and <OverviewDashboard onNavigate={select_module} />}
                    {active_module == "fleet" and <FleetModule />}
                    {active_module == "driver" and <DriverModule />}
                    {active_module == "operations" and <OperationsModule />}
                    {active_module == "ai" and <AIHubModule />}
                    {active_module == "telemetry" and <TelemetryModule />}
                    {active_module == "routing" and <RoutingModule />}
                    {active_module == "analytics" and <AnalyticsModule />}
                    {active_module == "monetization" and <MonetizationModule />}
                    {active_module == "survey" and <SurveyModule />}
                </main>
            </div>
        </div>
    );
}

def OverviewDashboard(onNavigate: Any) -> JsxElement {
    def nav_fleet(e: MouseEvent) -> None { if onNavigate { onNavigate("fleet"); } }
    def nav_driver(e: MouseEvent) -> None { if onNavigate { onNavigate("driver"); } }
    def nav_ops(e: MouseEvent) -> None { if onNavigate { onNavigate("operations"); } }
    def nav_ai(e: MouseEvent) -> None { if onNavigate { onNavigate("ai"); } }
    def nav_telemetry(e: MouseEvent) -> None { if onNavigate { onNavigate("telemetry"); } }
    def nav_routing(e: MouseEvent) -> None { if onNavigate { onNavigate("routing"); } }
    def nav_analytics(e: MouseEvent) -> None { if onNavigate { onNavigate("analytics"); } }
    def nav_monetization(e: MouseEvent) -> None { if onNavigate { onNavigate("monetization"); } }
    def nav_survey(e: MouseEvent) -> None { if onNavigate { onNavigate("survey"); } }

    return (
        <div>
            <div className="module-header">
                <h1 className="module-title">🏠 Command Center</h1>
                <p className="module-subtitle">Real-time overview of your entire fleet operation</p>
            </div>

            <div className="grid grid-cols-4 gap-4 mb-6">
                <div className="stat-card">
                    <div className="stat-label">Active Vehicles</div>
                    <div className="stat-value text-emerald-400">2,847</div>
                    <div className="stat-change up">↑ 98.4% uptime</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Drivers On Duty</div>
                    <div className="stat-value">1,284</div>
                    <div className="stat-change up">↑ 5 new today</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Revenue Today</div>
                    <div className="stat-value text-emerald-400">$94.2K</div>
                    <div className="stat-change up">↑ 12% vs yesterday</div>
                </div>
                <div className="stat-card">
                    <div className="stat-label">Active Dispatches</div>
                    <div className="stat-value text-primary">187</div>
                    <div className="stat-change">In transit now</div>
                </div>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="col-span-2 card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">📈 Fleet Activity (Last 24h)</div>
                    <div className="flex items-end gap-1.5 h-32 mb-2">
                        {[
                            <div
                                key={str(i)}
                                className="flex-1 rounded-t-sm"
                                style={{"height": str(30 + (i * 13 + 7) % 65) + "%", "background": "linear-gradient(180deg, #6366f1 0%, rgba(99,102,241,0.3) 100%)"}}
                            ></div>
                            for i in range(24)
                        ]}
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground">
                        <span>00:00</span><span>06:00</span><span>12:00</span><span>18:00</span><span>23:59</span>
                    </div>
                </div>

                <div className="card p-5">
                    <div className="text-sm font-bold text-foreground mb-4">🚨 Active Alerts</div>
                    <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-2 p-2 rounded-lg bg-red-500/10 border border-red-500/20">
                            <span className="text-red-400 text-xs">●</span>
                            <div className="text-xs">
                                <div className="text-foreground font-medium">Low Fuel — ORB-3341</div>
                                <div className="text-muted-foreground">12% remaining</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-2 p-2 rounded-lg bg-amber-500/10 border border-amber-500/20">
                            <span className="text-amber-400 text-xs">●</span>
                            <div className="text-xs">
                                <div className="text-foreground font-medium">HOS Warning — DRV-005</div>
                                <div className="text-muted-foreground">45 min remaining</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-2 p-2 rounded-lg bg-blue-500/10 border border-blue-500/20">
                            <span className="text-blue-400 text-xs">●</span>
                            <div className="text-xs">
                                <div className="text-foreground font-medium">Traffic Delay — DSP-4820</div>
                                <div className="text-muted-foreground">+22 min ETA</div>
                            </div>
                        </div>
                        <div className="flex items-center gap-2 p-2 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
                            <span className="text-emerald-400 text-xs">●</span>
                            <div className="text-xs">
                                <div className="text-foreground font-medium">Delivery Complete — DSP-4818</div>
                                <div className="text-muted-foreground">8 min early</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="text-sm font-bold text-foreground mb-3">Quick Access</div>
            <div className="grid grid-cols-3 gap-3">
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_fleet}>
                    <div className="text-2xl mb-2">🚛</div>
                    <div className="text-sm font-bold text-foreground">Fleet Management</div>
                    <div className="text-xs text-muted-foreground">6 vehicles · 1 in maintenance</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_driver}>
                    <div className="text-2xl mb-2">👤</div>
                    <div className="text-sm font-bold text-foreground">Driver Management</div>
                    <div className="text-xs text-muted-foreground">8 drivers · 5 on duty</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_ops}>
                    <div className="text-2xl mb-2">⚙️</div>
                    <div className="text-sm font-bold text-foreground">Operations</div>
                    <div className="text-xs text-muted-foreground">24 active dispatches</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_ai}>
                    <div className="text-2xl mb-2">🧠</div>
                    <div className="text-sm font-bold text-foreground">AI Intelligence Hub</div>
                    <div className="text-xs text-muted-foreground">12 models active · 96.3% accuracy</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_telemetry}>
                    <div className="text-2xl mb-2">📡</div>
                    <div className="text-sm font-bold text-foreground">Real-time Telemetry</div>
                    <div className="text-xs text-muted-foreground">Live sensor data · GPS active</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_routing}>
                    <div className="text-2xl mb-2">🗺️</div>
                    <div className="text-sm font-bold text-foreground">Smart Routing</div>
                    <div className="text-xs text-muted-foreground">4 routes · 340L saved today</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_analytics}>
                    <div className="text-2xl mb-2">📊</div>
                    <div className="text-sm font-bold text-foreground">Analytics & Reporting</div>
                    <div className="text-xs text-muted-foreground">$2.84M revenue · 57.4% margin</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_monetization}>
                    <div className="text-2xl mb-2">💰</div>
                    <div className="text-sm font-bold text-foreground">Monetization</div>
                    <div className="text-xs text-muted-foreground">$69.7K outstanding invoices</div>
                </button>
                <button className="card p-4 text-left hover:border-primary/40 transition-all cursor-pointer" onClick={nav_survey}>
                    <div className="text-2xl mb-2">🏆</div>
                    <div className="text-sm font-bold text-foreground">Driver Rewards</div>
                    <div className="text-xs text-muted-foreground">87% survey response rate</div>
                </button>
            </div>
        </div>
    );
}
