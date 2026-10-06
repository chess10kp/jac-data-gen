import from "@jac/runtime" { Navigate, jacIsLoggedIn, Link }
import from "lucide-react" { User, Building2, MapPin, Phone, Mail, Edit2, Shield }
import from ..components.Navbar { Navbar }
import from ..components.Sidebar { Sidebar }

def:pub ProfilePage() -> JsxElement {
    has role: str = "user";

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={role} />
            <div className="dashboard-layout">
                <Sidebar role={role} />
                <div className="dashboard-content">
                    <div className="page-header">
                        <h1 className="page-title">{"Profile"}</h1>
                    </div>

                    <div className="max-w-2xl">
                        <div className="card card-p mb-5">
                            <div className="flex items-center gap-4 mb-5">
                                <div className="w-20 h-20 bg-primary rounded-full flex items-center justify-center text-white text-3xl font-bold">
                                    {"U"}
                                </div>
                                <div>
                                    <h2 className="text-xl font-bold text-foreground">{"Demo User"}</h2>
                                    <div className="flex items-center gap-2 mt-1">
                                        <span className="badge badge-blue">{"Individual"}</span>
                                        <span className="badge badge-green flex items-center gap-1">
                                            <Shield size={10} />
                                            {"Verified"}
                                        </span>
                                    </div>
                                </div>
                                <button className="btn btn-ghost btn-sm ml-auto flex items-center gap-1">
                                    <Edit2 size={14} />
                                    {"Edit"}
                                </button>
                            </div>

                            <div className="grid grid-cols-1 gap-3">
                                <div className="flex items-center gap-3 p-3 bg-muted rounded-lg">
                                    <Mail size={16} className="text-muted-foreground" />
                                    <div>
                                        <div className="text-xs text-muted-foreground">{"Email"}</div>
                                        <div className="text-sm font-medium text-foreground">{"demo@nourish.app"}</div>
                                    </div>
                                </div>
                                <div className="flex items-center gap-3 p-3 bg-muted rounded-lg">
                                    <Phone size={16} className="text-muted-foreground" />
                                    <div>
                                        <div className="text-xs text-muted-foreground">{"Phone"}</div>
                                        <div className="text-sm font-medium text-foreground">{"Not set"}</div>
                                    </div>
                                </div>
                                <div className="flex items-center gap-3 p-3 bg-muted rounded-lg">
                                    <MapPin size={16} className="text-muted-foreground" />
                                    <div>
                                        <div className="text-xs text-muted-foreground">{"Location"}</div>
                                        <div className="text-sm font-medium text-foreground">{"Downtown"}</div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="card card-p">
                            <h3 className="section-title">{"Request History"}</h3>
                            <div className="empty-state py-8">
                                <div className="empty-state-icon"><User size={24} className="text-muted-foreground" /></div>
                                <div className="empty-state-title">{"No requests yet"}</div>
                                <div className="empty-state-desc">{"Your food requests will appear here."}</div>
                                <Link to="/requests/new" className="btn btn-primary mt-4">{"Make a Request"}</Link>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
