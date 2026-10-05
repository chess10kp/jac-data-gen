import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from ..components.Sidebar { Sidebar }

def:pub page() -> JsxElement {
    has notifications_enabled: bool = True;
    has daily_missions: bool = True;
    has streak_alerts: bool = True;
    has ai_suggestions: bool = True;
    has active_section: str = "profile";

    navigate = useNavigate();

    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }

    def toggle_notifications(e: MouseEvent) -> None {
        notifications_enabled = not notifications_enabled;
    }

    def toggle_missions(e: MouseEvent) -> None {
        daily_missions = not daily_missions;
    }

    def toggle_streaks(e: MouseEvent) -> None {
        streak_alerts = not streak_alerts;
    }

    def toggle_ai(e: MouseEvent) -> None {
        ai_suggestions = not ai_suggestions;
    }

    def set_profile(e: MouseEvent) -> None {
        active_section = "profile";
    }

    def set_ai_section(e: MouseEvent) -> None {
        active_section = "ai";
    }

    def set_notif(e: MouseEvent) -> None {
        active_section = "notifications";
    }

    return (
        <div className="page">
            <Sidebar />
            <div className="page-content">
                <div className="page-header">
                    <div>
                        <h1 className="text-2xl font-bold text-foreground">Settings</h1>
                        <p className="text-muted-foreground text-sm mt-1">Personalize your AI operating system</p>
                    </div>
                </div>

                <div className="grid grid-cols-4 gap-6">
                    <div className="card p-4">
                        <nav className="flex flex-col gap-1">
                            <button className={"sidebar-item w-full text-left " + ("active" if active_section == "profile" else "")} onClick={set_profile}>
                                👤 Profile
                            </button>
                            <button className={"sidebar-item w-full text-left " + ("active" if active_section == "ai" else "")} onClick={set_ai_section}>
                                🤖 AI Behavior
                            </button>
                            <button className={"sidebar-item w-full text-left " + ("active" if active_section == "notifications" else "")} onClick={set_notif}>
                                🔔 Notifications
                            </button>
                        </nav>
                    </div>

                    <div className="col-span-3">
                        {active_section == "profile" and (
                            <div className="card p-6">
                                <h2 className="text-base font-semibold text-foreground mb-6">Profile Settings</h2>
                                <div className="flex items-center gap-4 mb-6 p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.05)", "border": "1px solid rgba(59,130,246,0.1)"}}>
                                    <div className="w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold" style={{"background": "linear-gradient(135deg, #3b82f6, #8b5cf6)"}}>U</div>
                                    <div>
                                        <div className="text-base font-semibold text-foreground">User</div>
                                        <div className="text-sm text-muted-foreground">Pro Plan · Member since Nov 2024</div>
                                    </div>
                                    <button className="btn btn-ghost ml-auto text-xs">Change Photo</button>
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="label">Display Name</label>
                                        <input className="input" type="text" value="User" placeholder="Your name" />
                                    </div>
                                    <div>
                                        <label className="label">Email</label>
                                        <input className="input" type="email" value="user@futureos.ai" placeholder="Email" />
                                    </div>
                                    <div>
                                        <label className="label">Goal Focus</label>
                                        <input className="input" type="text" value="AI Engineering" placeholder="Primary goal" />
                                    </div>
                                    <div>
                                        <label className="label">Daily Hours Available</label>
                                        <input className="input" type="number" value="4" placeholder="Hours" />
                                    </div>
                                </div>
                                <button className="btn btn-primary mt-6">Save Changes</button>
                            </div>
                        )}

                        {active_section == "ai" and (
                            <div className="card p-6">
                                <h2 className="text-base font-semibold text-foreground mb-6">AI Behavior Controls</h2>
                                <div className="flex flex-col gap-4">
                                    <div className="flex items-center justify-between p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div>
                                            <div className="text-sm font-medium text-foreground">AI Suggestions</div>
                                            <div className="text-xs text-muted-foreground">Proactive recommendations from agents</div>
                                        </div>
                                        <button
                                            className={"w-12 h-6 rounded-full transition-all " + ("bg-primary" if ai_suggestions else "bg-muted")}
                                            onClick={toggle_ai}
                                        >
                                            <div className={"w-5 h-5 rounded-full bg-white transition-all mx-0.5 " + ("translate-x-6" if ai_suggestions else "translate-x-0")}></div>
                                        </button>
                                    </div>
                                    <div className="p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div className="text-sm font-medium text-foreground mb-3">Agent Autonomy Level</div>
                                        <div className="flex gap-2">
                                            <button className="btn btn-primary text-xs flex-1">Autonomous</button>
                                            <button className="btn text-xs flex-1">Assisted</button>
                                            <button className="btn text-xs flex-1">Manual</button>
                                        </div>
                                    </div>
                                    <div className="p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div className="text-sm font-medium text-foreground mb-1">Mission Difficulty</div>
                                        <div className="text-xs text-muted-foreground mb-3">How challenging should daily missions be?</div>
                                        <div className="flex gap-2">
                                            <button className="btn text-xs flex-1">Easy</button>
                                            <button className="btn btn-primary text-xs flex-1">Adaptive</button>
                                            <button className="btn text-xs flex-1">Hard</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}

                        {active_section == "notifications" and (
                            <div className="card p-6">
                                <h2 className="text-base font-semibold text-foreground mb-6">Notification Settings</h2>
                                <div className="flex flex-col gap-4">
                                    <div className="flex items-center justify-between p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div>
                                            <div className="text-sm font-medium text-foreground">All Notifications</div>
                                            <div className="text-xs text-muted-foreground">Master toggle for all alerts</div>
                                        </div>
                                        <button
                                            className={"w-12 h-6 rounded-full transition-all " + ("bg-primary" if notifications_enabled else "bg-muted")}
                                            onClick={toggle_notifications}
                                        ></button>
                                    </div>
                                    <div className="flex items-center justify-between p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div>
                                            <div className="text-sm font-medium text-foreground">Daily Mission Reminders</div>
                                            <div className="text-xs text-muted-foreground">Get reminded about pending missions</div>
                                        </div>
                                        <button
                                            className={"w-12 h-6 rounded-full transition-all " + ("bg-primary" if daily_missions else "bg-muted")}
                                            onClick={toggle_missions}
                                        ></button>
                                    </div>
                                    <div className="flex items-center justify-between p-4 rounded-xl" style={{"background": "rgba(59,130,246,0.04)", "border": "1px solid rgba(59,130,246,0.08)"}}>
                                        <div>
                                            <div className="text-sm font-medium text-foreground">Streak Alerts</div>
                                            <div className="text-xs text-muted-foreground">Don't break your streak</div>
                                        </div>
                                        <button
                                            className={"w-12 h-6 rounded-full transition-all " + ("bg-primary" if streak_alerts else "bg-muted")}
                                            onClick={toggle_streaks}
                                        ></button>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
