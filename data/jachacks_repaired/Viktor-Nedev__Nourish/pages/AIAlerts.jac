import from "@jac/runtime" { Navigate, jacIsLoggedIn, Link }
import from "lucide-react" { Bell, AlertTriangle, Clock, Package, MapPin, ArrowRight }
import from ..components.Navbar { Navbar }
import from ..components.Sidebar { Sidebar }
import from ..data.mockData { get_mock_donations, get_mock_requests }

def:pub AIAlerts() -> JsxElement {
    has donations: list[any] = [];
    has requests: list[any] = [];

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    async can with entry {
        donations = get_mock_donations();
        requests = get_mock_requests();
    }

    expiring: list[any] = [d for d in donations if d["status"] == "expiring_soon"];
    urgent: list[any] = [r for r in requests if r["urgency"] == "critical" or r["urgency"] == "high"];

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"org"} />
            <div className="dashboard-layout">
                <Sidebar role={"org"} />
                <div className="dashboard-content">
                    <div className="page-header">
                        <h1 className="page-title flex items-center gap-2">
                            <Bell size={22} className="text-red-500" />
                            {"Priority Alerts"}
                        </h1>
                        <p className="page-subtitle">{"Action-oriented alerts requiring immediate attention."}</p>
                    </div>

                    {len(urgent) > 0 and
                        <div className="alert-banner alert-banner-red mb-6">
                            <AlertTriangle size={18} />
                            <div className="font-semibold">{str(len(urgent)) + " urgent requests need immediate response"}</div>
                        </div>
                    }

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div className="card">
                            <div className="p-5 border-b border-border">
                                <h3 className="section-title mb-0">
                                    <AlertTriangle size={16} className="text-red-500" />
                                    {"Urgent Requests"}
                                </h3>
                            </div>
                            <div className="divide-y divide-border">
                                {len(urgent) == 0 and <div className="p-8 text-center text-sm text-muted-foreground">{"No urgent requests"}</div>}
                                {[<div key={urgent[i]["id"]} className="p-4">
                                    <div className="flex items-start justify-between gap-2 mb-2">
                                        <div className="text-sm font-bold text-foreground">{urgent[i]["title"]}</div>
                                        <span className={"urgency-" + urgent[i]["urgency"]}>{urgent[i]["urgency"]}</span>
                                    </div>
                                    <div className="text-xs text-muted-foreground mb-1">{urgent[i]["location_text"]}</div>
                                    <div className="text-xs text-muted-foreground mb-3">{str(urgent[i]["people_count"]) + " people · " + urgent[i]["food_type"]}</div>
                                    <div className="flex gap-2">
                                        <Link to={"/requests/" + urgent[i]["id"]} className="btn btn-primary btn-sm">{"Respond Now"}</Link>
                                        <Link to="/map" className="btn btn-sm flex items-center gap-1">
                                            <MapPin size={12} />
                                            {"Map"}
                                        </Link>
                                    </div>
                                </div>
                                for i in range(len(urgent))]}
                            </div>
                        </div>

                        <div className="card">
                            <div className="p-5 border-b border-border">
                                <h3 className="section-title mb-0">
                                    <Clock size={16} className="text-amber-500" />
                                    {"Expiring Donations"}
                                </h3>
                            </div>
                            <div className="divide-y divide-border">
                                {len(expiring) == 0 and <div className="p-8 text-center text-sm text-muted-foreground">{"No expiring donations"}</div>}
                                {[<div key={expiring[i]["id"]} className="p-4">
                                    <div className="flex items-start justify-between gap-2 mb-2">
                                        <div className="text-sm font-bold text-foreground">{expiring[i]["title"]}</div>
                                        <span className="badge badge-red">{"Expiring"}</span>
                                    </div>
                                    <div className="text-xs text-muted-foreground mb-1">{expiring[i]["quantity"] + " · " + expiring[i]["category"]}</div>
                                    <div className="text-xs text-red-600 font-semibold mb-3">{"Expires: " + expiring[i]["expiry_date"]}</div>
                                    <Link to={"/donations/" + expiring[i]["id"]} className="btn btn-sm btn-outline">{"View Donation"}</Link>
                                </div>
                                for i in range(len(expiring))]}
                            </div>
                        </div>
                    </div>

                    <div className="card mt-6">
                        <div className="p-5 border-b border-border">
                            <h3 className="section-title mb-0">{"Underserved Zones"}</h3>
                        </div>
                        <div className="p-5 grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div className="p-4 bg-red-50 border border-red-200 rounded-xl">
                                <div className="text-sm font-bold text-red-800 mb-1">{"East Village"}</div>
                                <div className="text-xs text-red-600">{"8 requests, 2 donations"}</div>
                                <div className="text-xs text-red-600">{"Coverage gap: 75%"}</div>
                                <Link to="/donations/new" className="btn btn-sm btn-primary mt-3 w-full">{"Add Donation Here"}</Link>
                            </div>
                            <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl">
                                <div className="text-sm font-bold text-amber-800 mb-1">{"Northside"}</div>
                                <div className="text-xs text-amber-600">{"6 requests, 1 donation"}</div>
                                <div className="text-xs text-amber-600">{"Coverage gap: 60%"}</div>
                                <Link to="/events/new" className="btn btn-sm btn-secondary mt-3 w-full">{"Create Event"}</Link>
                            </div>
                            <div className="p-4 bg-green-50 border border-green-200 rounded-xl">
                                <div className="text-sm font-bold text-green-800 mb-1">{"Westside"}</div>
                                <div className="text-xs text-green-600">{"4 requests, 5 donations"}</div>
                                <div className="text-xs text-green-600">{"Well covered"}</div>
                                <div className="btn btn-sm bg-green-100 text-green-700 border-green-200 mt-3 w-full">{"No action needed"}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
