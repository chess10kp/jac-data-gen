import from "@jac/runtime" { Link, useLocation }
import from "lucide-react" {
    LayoutDashboard, Package, Users, Calendar, Map,
    Brain, Bell, User, Settings, Plus, TrendingUp, Leaf
}

def:pub Sidebar(role: str) -> JsxElement {
    loc: any = useLocation();
    path: str = "/";

    def is_active(p: str) -> str {
        if path == p { return "sidebar-link sidebar-link-active"; }
        return "sidebar-link";
    }

    return (
        <div className="sidebar">
            <div className="p-4 border-b border-border">
                <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                        <Leaf size={14} color="white" />
                    </div>
                    <div>
                        <div className="text-sm font-bold text-foreground">{"Nourish"}</div>
                        <div className="text-xs text-muted-foreground">{role if role == "org" else "User"}</div>
                    </div>
                </div>
            </div>

            <div className="sidebar-nav flex-1">
                <div className="sidebar-section">{"Overview"}</div>
                {role == "org" and
                    <Link to="/dashboard/org" className={is_active("/dashboard/org")}>
                        <LayoutDashboard size={16} />
                        {"Dashboard"}
                    </Link>
                }
                {role != "org" and
                    <Link to="/dashboard/user" className={is_active("/dashboard/user")}>
                        <LayoutDashboard size={16} />
                        {"Dashboard"}
                    </Link>
                }
                <Link to="/map" className={is_active("/map")}>
                    <Map size={16} />
                    {"Map"}
                </Link>

                <div className="sidebar-section mt-2">{"Food"}</div>
                <Link to="/donations/feed" className={is_active("/donations/feed")}>
                    <Package size={16} />
                    {"Donations"}
                </Link>
                {role == "org" and
                    <Link to="/donations/new" className={is_active("/donations/new")}>
                        <Plus size={16} />
                        {"Add Donation"}
                    </Link>
                }
                <Link to="/requests" className={is_active("/requests")}>
                    <Users size={16} />
                    {"Requests"}
                </Link>
                {role != "org" and
                    <Link to="/requests/new" className={is_active("/requests/new")}>
                        <Plus size={16} />
                        {"Make Request"}
                    </Link>
                }

                <div className="sidebar-section mt-2">{"Community"}</div>
                <Link to="/events" className={is_active("/events")}>
                    <Calendar size={16} />
                    {"Events"}
                </Link>
                {role == "org" and
                    <Link to="/events/new" className={is_active("/events/new")}>
                        <Plus size={16} />
                        {"Create Event"}
                    </Link>
                }

                {role == "org" and
                    <div>
                        <div className="sidebar-section mt-2">{"AI Tools"}</div>
                        <Link to="/ai/insights" className={is_active("/ai/insights")}>
                            <Brain size={16} />
                            {"AI Insights"}
                        </Link>
                        <Link to="/ai/alerts" className={is_active("/ai/alerts")}>
                            <Bell size={16} />
                            {"Priority Alerts"}
                        </Link>
                        <Link to="/ai/forecast" className={is_active("/ai/forecast")}>
                            <TrendingUp size={16} />
                            {"Forecasting"}
                        </Link>
                    </div>
                }
            </div>

            <div className="border-t border-border p-4 flex flex-col gap-1">
                <Link to="/profile" className={is_active("/profile")}>
                    <User size={16} />
                    {"Profile"}
                </Link>
                <Link to="/settings" className={is_active("/settings")}>
                    <Settings size={16} />
                    {"Settings"}
                </Link>
            </div>
        </div>
    );
}
