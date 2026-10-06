import from "@jac/runtime" { Navigate, jacIsLoggedIn }
import from "lucide-react" { Bell, Globe, MapPin, Lock, Eye }
import from ..components.Navbar { Navbar }
import from ..components.Sidebar { Sidebar }

def:pub SettingsPage() -> JsxElement {
    has role: str = "user";
    has notifications: bool = True;
    has location_sharing: bool = False;
    has radius: str = "5";
    has language: str = "en";

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    def h_notif(e: ChangeEvent) -> None { notifications = not notifications; }
    def h_loc(e: ChangeEvent) -> None { location_sharing = not location_sharing; }
    def h_radius(e: ChangeEvent) -> None { radius = e.target.value; }
    def h_lang(e: ChangeEvent) -> None { language = e.target.value; }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={role} />
            <div className="dashboard-layout">
                <Sidebar role={role} />
                <div className="dashboard-content">
                    <div className="page-header">
                        <h1 className="page-title">{"Settings"}</h1>
                    </div>

                    <div className="max-w-2xl flex flex-col gap-5">
                        <div className="card card-p">
                            <h3 className="section-title">
                                <Bell size={16} />
                                {"Notifications"}
                            </h3>
                            <div className="flex items-center justify-between p-3 bg-muted rounded-lg">
                                <div>
                                    <div className="text-sm font-semibold text-foreground">{"Push Notifications"}</div>
                                    <div className="text-xs text-muted-foreground">{"Get alerts for new donations and requests"}</div>
                                </div>
                                <input type="checkbox" checked={notifications} onChange={h_notif} className="accent-primary w-5 h-5" />
                            </div>
                        </div>

                        <div className="card card-p">
                            <h3 className="section-title">
                                <MapPin size={16} />
                                {"Location & Radius"}
                            </h3>
                            <div className="flex flex-col gap-3">
                                <div className="flex items-center justify-between p-3 bg-muted rounded-lg">
                                    <div>
                                        <div className="text-sm font-semibold text-foreground">{"Share Location"}</div>
                                        <div className="text-xs text-muted-foreground">{"Allow Nourish to use your location"}</div>
                                    </div>
                                    <input type="checkbox" checked={location_sharing} onChange={h_loc} className="accent-primary w-5 h-5" />
                                </div>
                                <div className="form-group">
                                    <label className="label">{"Search Radius (km)"}</label>
                                    <select className="select" value={radius} onChange={h_radius}>
                                        <option value="1">{"1 km"}</option>
                                        <option value="2">{"2 km"}</option>
                                        <option value="5">{"5 km"}</option>
                                        <option value="10">{"10 km"}</option>
                                        <option value="20">{"20 km"}</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div className="card card-p">
                            <h3 className="section-title">
                                <Globe size={16} />
                                {"Language"}
                            </h3>
                            <div className="form-group">
                                <label className="label">{"Preferred Language"}</label>
                                <select className="select" value={language} onChange={h_lang}>
                                    <option value="en">{"English"}</option>
                                    <option value="es">{"Español"}</option>
                                    <option value="fr">{"Français"}</option>
                                    <option value="ar">{"العربية"}</option>
                                </select>
                            </div>
                        </div>

                        <div className="card card-p">
                            <h3 className="section-title">
                                <Lock size={16} />
                                {"Privacy"}
                            </h3>
                            <div className="flex flex-col gap-2">
                                <button className="btn btn-ghost text-left justify-start">{"Change Password"}</button>
                                <button className="btn btn-ghost text-left justify-start text-red-600">{"Delete Account"}</button>
                            </div>
                        </div>

                        <button className="btn btn-primary">{"Save Settings"}</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
