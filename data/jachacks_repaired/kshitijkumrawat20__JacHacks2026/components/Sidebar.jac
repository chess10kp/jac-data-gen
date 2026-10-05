import from "@jac/runtime" { useNavigate, useLocation, jacLogout }

def:pub Sidebar() -> JsxElement {
    navigate = useNavigate();
    location = useLocation();
    current = location["pathname"];

    def handle_logout(e: MouseEvent) -> None {
        jacLogout();
        navigate("/login");
    }

    def go_dashboard(e: MouseEvent) -> None {
        navigate("/dashboard");
    }

    def go_goals(e: MouseEvent) -> None {
        navigate("/goals");
    }

    def go_agents(e: MouseEvent) -> None {
        navigate("/agents");
    }

    def go_analytics(e: MouseEvent) -> None {
        navigate("/analytics");
    }

    def go_memory(e: MouseEvent) -> None {
        navigate("/memory");
    }

    def go_opportunities(e: MouseEvent) -> None {
        navigate("/opportunities");
    }

    def go_settings(e: MouseEvent) -> None {
        navigate("/settings");
    }

    return (
        <div className="sidebar">
            <div className="p-5 mb-2">
                <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center animate-pulse-glow" style={{"background": "linear-gradient(135deg, rgba(59,130,246,0.3), rgba(139,92,246,0.3))", "border": "1px solid rgba(59,130,246,0.4)"}}>
                        <span style={{"fontSize": "16px"}}>⚡</span>
                    </div>
                    <div>
                        <div className="text-sm font-bold text-gradient-blue">FutureOS</div>
                        <div className="text-xs text-muted-foreground">AI Life OS</div>
                    </div>
                </div>
            </div>

            <div className="px-3 mb-2">
                <div className="text-xs text-muted-foreground uppercase tracking-widest px-2 mb-2">Navigation</div>
                <nav className="flex flex-col gap-1">
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/dashboard" else "")} onClick={go_dashboard}>
                        <span style={{"fontSize": "16px"}}>⚡</span>
                        <span>Dashboard</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/goals" else "")} onClick={go_goals}>
                        <span style={{"fontSize": "16px"}}>🎯</span>
                        <span>Goal Workspace</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/agents" else "")} onClick={go_agents}>
                        <span style={{"fontSize": "16px"}}>🤖</span>
                        <span>Agent Activity</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/analytics" else "")} onClick={go_analytics}>
                        <span style={{"fontSize": "16px"}}>📊</span>
                        <span>Analytics</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/memory" else "")} onClick={go_memory}>
                        <span style={{"fontSize": "16px"}}>🧠</span>
                        <span>Memory</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/opportunities" else "")} onClick={go_opportunities}>
                        <span style={{"fontSize": "16px"}}>🚀</span>
                        <span>Opportunities</span>
                    </button>
                    <button className={"sidebar-item w-full text-left " + ("active" if current == "/settings" else "")} onClick={go_settings}>
                        <span style={{"fontSize": "16px"}}>⚙️</span>
                        <span>Settings</span>
                    </button>
                </nav>
            </div>

            <div className="mt-auto p-4 border-t border-border">
                <div className="flex items-center gap-3 mb-3 px-2">
                    <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold" style={{"background": "linear-gradient(135deg, #3b82f6, #8b5cf6)"}}>U</div>
                    <div>
                        <div className="text-sm font-medium text-foreground">User</div>
                        <div className="text-xs text-muted-foreground">Pro Plan</div>
                    </div>
                </div>
                <button className="btn btn-ghost w-full text-xs justify-start gap-2" onClick={handle_logout}>
                    <span>↩</span>
                    <span>Sign out</span>
                </button>
            </div>
        </div>
    );
}
