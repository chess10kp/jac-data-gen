import from "@jac/runtime" { Link, useNavigate, jacIsLoggedIn, jacLogout }
import from "lucide-react" { Leaf, Map, Package, Users, Calendar, Bell, User, LogOut, Menu, X, ChevronDown }

def:pub Navbar(role: str) -> JsxElement {
    has menu_open: bool = False;
    has user_menu: bool = False;

    navigate = useNavigate();
    logged_in: bool = jacIsLoggedIn();

    def toggle_menu(e: MouseEvent) -> None {
        menu_open = not menu_open;
    }

    def toggle_user(e: MouseEvent) -> None {
        user_menu = not user_menu;
    }

    def handle_logout(e: MouseEvent) -> None {
        jacLogout();
        navigate("/");
    }

    dashboard_path: str = "/dashboard/org" if role == "org" else "/dashboard/user";

    return (
        <div className="navbar">
            <div className="navbar-inner">
                <div className="flex items-center gap-8">
                    <Link to="/" className="navbar-logo">
                        <div className="navbar-logo-icon">
                            <Leaf size={16} color="white" strokeWidth={2.5} />
                        </div>
                        <span className="text-primary">{"Nourish"}</span>
                    </Link>

                    <div className="hidden md:flex items-center gap-1">
                        <Link to="/map" className="nav-link flex items-center gap-1.5">
                            <Map size={14} />
                            {"Map"}
                        </Link>
                        <Link to="/donations/feed" className="nav-link flex items-center gap-1.5">
                            <Package size={14} />
                            {"Donations"}
                        </Link>
                        <Link to="/requests" className="nav-link flex items-center gap-1.5">
                            <Users size={14} />
                            {"Requests"}
                        </Link>
                        <Link to="/events" className="nav-link flex items-center gap-1.5">
                            <Calendar size={14} />
                            {"Events"}
                        </Link>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    {not logged_in and
                        <div className="flex items-center gap-2">
                            <Link to="/auth" className="btn btn-ghost btn-sm">{"Sign in"}</Link>
                            <Link to="/auth" className="btn btn-primary btn-sm">{"Get started"}</Link>
                        </div>
                    }
                    {logged_in and
                        <div className="flex items-center gap-2">
                            <Link to={dashboard_path} className="btn btn-ghost btn-sm">{"Dashboard"}</Link>
                            <div className="relative">
                                <button className="btn btn-ghost btn-sm flex items-center gap-1.5" onClick={toggle_user}>
                                    <div className="w-7 h-7 bg-primary rounded-full flex items-center justify-center text-white text-xs font-bold">
                                        {"U"}
                                    </div>
                                    <ChevronDown size={12} />
                                </button>
                                {user_menu and
                                    <div className="absolute right-0 top-10 w-48 bg-white border border-border rounded-xl shadow-lg py-1 z-50">
                                        <Link to="/profile" className="flex items-center gap-2 px-4 py-2.5 text-sm text-foreground hover:bg-muted">
                                            <User size={14} />
                                            {"Profile"}
                                        </Link>
                                        <Link to="/settings" className="flex items-center gap-2 px-4 py-2.5 text-sm text-foreground hover:bg-muted">
                                            {"Settings"}
                                        </Link>
                                        <div className="border-t border-border my-1" />
                                        <button className="flex items-center gap-2 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 w-full text-left" onClick={handle_logout}>
                                            <LogOut size={14} />
                                            {"Sign out"}
                                        </button>
                                    </div>
                                }
                            </div>
                        </div>
                    }
                    <button className="md:hidden btn btn-ghost btn-sm" onClick={toggle_menu}>
                        {menu_open and <X size={18} />}
                        {not menu_open and <Menu size={18} />}
                    </button>
                </div>
            </div>

            {menu_open and
                <div className="md:hidden border-t border-border bg-white px-4 py-3 flex flex-col gap-1">
                    <Link to="/map" className="nav-link">{"Map"}</Link>
                    <Link to="/donations/feed" className="nav-link">{"Donations"}</Link>
                    <Link to="/requests" className="nav-link">{"Requests"}</Link>
                    <Link to="/events" className="nav-link">{"Events"}</Link>
                    {logged_in and <Link to={dashboard_path} className="nav-link">{"Dashboard"}</Link>}
                    {not logged_in and <Link to="/auth" className="btn btn-primary mt-2">{"Sign in"}</Link>}
                </div>
            }
        </div>
    );
}
