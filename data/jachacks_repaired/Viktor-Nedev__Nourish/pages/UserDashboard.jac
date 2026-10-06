import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn }
import from "lucide-react" { Map, Package, Users, Calendar, Plus }
import from ..components.Navbar { Navbar }
import from ..components.Sidebar { Sidebar }
import from ..data.mockData { get_mock_donations, get_mock_requests, get_mock_events }

def:pub UserDashboard() -> JsxElement {
    has donations: list[any] = [];
    has requests: list[any] = [];
    has events: list[any] = [];

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    async can with entry {
        donations = get_mock_donations();
        requests = get_mock_requests();
        events = get_mock_events();
    }

    don_count: str = str(len(donations));
    ev_count: str = str(len(events));

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="dashboard-layout">
                <Sidebar role={"user"} />
                <div className="dashboard-content">
                    <div className="page-header">
                        <h1 className="page-title">{"Welcome back!"}</h1>
                        <p className="page-subtitle">{"Find food near you or make a request."}</p>
                    </div>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                        <Link to="/map" className="card card-p flex flex-col items-center gap-3 text-center hover:border-primary hover:bg-primary-light cursor-pointer">
                            <div className="w-12 h-12 bg-primary-light rounded-xl flex items-center justify-center">
                                <Map size={22} className="text-primary" />
                            </div>
                            <div>
                                <div className="text-sm font-bold text-foreground">{"View Full Map"}</div>
                                <div className="text-xs text-muted-foreground">{"Find food near you"}</div>
                            </div>
                        </Link>
                        <Link to="/donations/feed" className="card card-p flex flex-col items-center gap-3 text-center hover:border-amber-400 hover:bg-amber-50 cursor-pointer">
                            <div className="w-12 h-12 bg-amber-50 rounded-xl flex items-center justify-center">
                                <Package size={22} className="text-amber-500" />
                            </div>
                            <div>
                                <div className="text-sm font-bold text-foreground">{"Browse Food"}</div>
                                <div className="text-xs text-muted-foreground">{don_count + " available"}</div>
                            </div>
                        </Link>
                        <Link to="/requests/new" className="card card-p flex flex-col items-center gap-3 text-center hover:border-red-400 hover:bg-red-50 cursor-pointer">
                            <div className="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center">
                                <Plus size={22} className="text-red-500" />
                            </div>
                            <div>
                                <div className="text-sm font-bold text-foreground">{"Make Request"}</div>
                                <div className="text-xs text-muted-foreground">{"Get food support"}</div>
                            </div>
                        </Link>
                        <Link to="/events" className="card card-p flex flex-col items-center gap-3 text-center hover:border-blue-400 hover:bg-blue-50 cursor-pointer">
                            <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                                <Calendar size={22} className="text-blue-500" />
                            </div>
                            <div>
                                <div className="text-sm font-bold text-foreground">{"View Events"}</div>
                                <div className="text-xs text-muted-foreground">{ev_count + " upcoming"}</div>
                            </div>
                        </Link>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div className="card">
                            <div className="p-5 border-b border-border flex items-center justify-between">
                                <h3 className="section-title mb-0">
                                    <Package size={16} className="text-amber-500" />
                                    {"Food Available Nearby"}
                                </h3>
                                <Link to="/donations/feed" className="text-xs text-primary font-semibold">{"See all →"}</Link>
                            </div>
                            <div className="divide-y divide-border">
                                {[<div key={str(i)} className="p-4 flex items-center justify-between hover:bg-muted/50">
                                    <div>
                                        <div className="text-sm font-semibold text-foreground">{str(donations[i]["title"])}</div>
                                        <div className="text-xs text-muted-foreground">{str(donations[i]["organization"]) + " · " + str(donations[i]["quantity"])}</div>
                                        <div className="text-xs text-muted-foreground">{"Expires: " + str(donations[i]["expiry_date"])}</div>
                                    </div>
                                    <Link to={"/donations/" + str(donations[i]["id"])} className="btn btn-sm btn-outline">{"View"}</Link>
                                </div>
                                for i in range(min(4, len(donations)))]}
                            </div>
                        </div>

                        <div className="card">
                            <div className="p-5 border-b border-border flex items-center justify-between">
                                <h3 className="section-title mb-0">
                                    <Calendar size={16} className="text-blue-500" />
                                    {"Upcoming Events"}
                                </h3>
                                <Link to="/events" className="text-xs text-primary font-semibold">{"See all →"}</Link>
                            </div>
                            <div className="divide-y divide-border">
                                {[<div key={str(i)} className="p-4 hover:bg-muted/50">
                                    <div className="text-sm font-semibold text-foreground">{str(events[i]["title"])}</div>
                                    <div className="text-xs text-muted-foreground mt-0.5">{str(events[i]["event_date"]) + " · " + str(events[i]["event_time"])}</div>
                                    <div className="text-xs text-muted-foreground">{str(events[i]["address"])}</div>
                                    <div className="flex items-center justify-between mt-2">
                                        <span className="badge badge-blue">{str(events[i]["registered"]) + "/" + str(events[i]["capacity"]) + " registered"}</span>
                                        <Link to={"/events/" + str(events[i]["id"])} className="text-xs text-primary font-semibold">{"Details →"}</Link>
                                    </div>
                                </div>
                                for i in range(min(3, len(events)))]}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
