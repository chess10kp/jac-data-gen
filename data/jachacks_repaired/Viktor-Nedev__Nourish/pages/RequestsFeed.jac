import from "@jac/runtime" { Link, jacIsLoggedIn }
import from "lucide-react" { Users, MapPin, Clock, Search, Plus, AlertTriangle }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_requests }

def:pub RequestsFeed() -> JsxElement {
    has requests: list[any] = [];
    has search: str = "";
    has filter_urgency: str = "all";

    async can with entry {
        requests = get_mock_requests();
    }

    def handle_search(e: ChangeEvent) -> None { search = e.target.value; }
    def set_filter(u: str) -> None { filter_urgency = u; }

    urgencies: list[str] = ["all", "critical", "high", "medium", "low"];

    filtered: list[any] = [r for r in requests if
        (filter_urgency == "all" or r["urgency"] == filter_urgency) and
        (search == "" or search.lower() in r["title"].lower())
    ];

    def urgency_badge(u: str) -> str {
        if u == "critical" { return "urgency-critical"; }
        if u == "high" { return "urgency-high"; }
        if u == "medium" { return "urgency-medium"; }
        return "urgency-low";
    }

    def urgency_border(u: str) -> str {
        if u == "critical" { return "border-l-4 border-l-red-600"; }
        if u == "high" { return "border-l-4 border-l-orange-500"; }
        if u == "medium" { return "border-l-4 border-l-amber-400"; }
        return "border-l-4 border-l-green-500";
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h1 className="page-title">{"Food Requests"}</h1>
                        <p className="page-subtitle">{str(len(filtered)) + " active requests in your area"}</p>
                    </div>
                    <Link to="/requests/new" className="btn btn-primary flex items-center gap-2">
                        <Plus size={16} />
                        {"Make a Request"}
                    </Link>
                </div>

                <div className="flex flex-col sm:flex-row gap-3 mb-5">
                    <div className="relative flex-1">
                        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
                        <input className="input pl-9" type="text" placeholder="Search requests..." value={search} onChange={handle_search} />
                    </div>
                </div>

                <div className="filter-bar">
                    {[<button
                        key={urgencies[i]}
                        className={"filter-chip " + ("filter-chip-active" if filter_urgency == urgencies[i] else "")}
                        onClick={lambda(e: MouseEvent) -> None { set_filter(urgencies[i]); }}
                    >
                        {urgencies[i].capitalize() if urgencies[i] != "all" else "All Urgency"}
                    </button>
                    for i in range(len(urgencies))]}
                </div>

                {len(filtered) == 0 and
                    <div className="empty-state">
                        <div className="empty-state-icon"><Users size={28} className="text-muted-foreground" /></div>
                        <div className="empty-state-title">{"No requests found"}</div>
                        <div className="empty-state-desc">{"Try adjusting your filters."}</div>
                    </div>
                }

                <div className="flex flex-col gap-4">
                    {[<div key={filtered[i]["id"]} className={"request-card " + urgency_border(filtered[i]["urgency"])}>
                        <div className="p-5">
                            <div className="flex items-start justify-between gap-3 mb-2">
                                <h3 className="text-base font-bold text-foreground">{filtered[i]["title"]}</h3>
                                <span className={urgency_badge(filtered[i]["urgency"])}>{filtered[i]["urgency"]}</span>
                            </div>
                            <p className="text-sm text-muted-foreground mb-3">{filtered[i]["description"]}</p>
                            <div className="flex flex-wrap gap-4 mb-4">
                                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                    <Users size={12} />
                                    {str(filtered[i]["people_count"]) + " people"}
                                </div>
                                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                    <MapPin size={12} />
                                    {filtered[i]["location_text"]}
                                </div>
                                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                    <Clock size={12} />
                                    {filtered[i]["created_at"]}
                                </div>
                            </div>
                            <div className="flex items-center justify-between">
                                <div className="text-xs text-muted-foreground">
                                    {"Posted by: " + filtered[i]["posted_by"]}
                                </div>
                                <div className="flex gap-2">
                                    <Link to={"/requests/" + filtered[i]["id"]} className="btn btn-sm btn-outline">{"View Details"}</Link>
                                    <Link to="/map" className="btn btn-sm flex items-center gap-1">
                                        <MapPin size={12} />
                                        {"Map"}
                                    </Link>
                                </div>
                            </div>
                        </div>
                    </div>
                    for i in range(len(filtered))]}
                </div>
            </div>
        </div>
    );
}
