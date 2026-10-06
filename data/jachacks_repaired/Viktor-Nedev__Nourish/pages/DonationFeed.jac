import from "@jac/runtime" { Link, jacIsLoggedIn }
import from "lucide-react" { Package, MapPin, Clock, Filter, Search, ArrowRight }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_donations }

def:pub DonationFeed() -> JsxElement {
    has donations: list[any] = [];
    has search: str = "";
    has filter_cat: str = "all";

    async can with entry {
        donations = get_mock_donations();
    }

    def handle_search(e: ChangeEvent) -> None { search = e.target.value; }
    def set_filter(cat: str) -> None { filter_cat = cat; }

    categories: list[str] = ["all", "Vegetables", "Bread & Bakery", "Dairy", "Canned Goods", "Prepared Meals"];

    filtered: list[any] = [d for d in donations if
        (filter_cat == "all" or d["category"] == filter_cat) and
        (search == "" or search.lower() in d["title"].lower() or search.lower() in d["organization"].lower())
    ];

    def status_badge(s: str) -> str {
        if s == "expiring_soon" { return "badge badge-red"; }
        return "badge badge-green";
    }

    def status_label(s: str) -> str {
        if s == "expiring_soon" { return "Expiring Soon"; }
        return "Available";
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h1 className="page-title">{"Food Donations"}</h1>
                        <p className="page-subtitle">{str(len(filtered)) + " donations available near you"}</p>
                    </div>
                    {jacIsLoggedIn() and
                        <Link to="/donations/new" className="btn btn-primary flex items-center gap-2">
                            <Package size={16} />
                            {"Post Donation"}
                        </Link>
                    }
                </div>

                <div className="flex flex-col sm:flex-row gap-3 mb-5">
                    <div className="relative flex-1">
                        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
                        <input
                            className="input pl-9"
                            type="text"
                            placeholder="Search donations..."
                            value={search}
                            onChange={handle_search}
                        />
                    </div>
                </div>

                <div className="filter-bar">
                    {[<button
                        key={categories[i]}
                        className={"filter-chip " + ("filter-chip-active" if filter_cat == categories[i] else "")}
                        onClick={lambda(e: MouseEvent) -> None { set_filter(categories[i]); }}
                    >
                        {categories[i] if categories[i] != "all" else "All Categories"}
                    </button>
                    for i in range(len(categories))]}
                </div>

                {len(filtered) == 0 and
                    <div className="empty-state">
                        <div className="empty-state-icon">
                            <Package size={28} className="text-muted-foreground" />
                        </div>
                        <div className="empty-state-title">{"No donations found"}</div>
                        <div className="empty-state-desc">{"Try adjusting your filters or check back later."}</div>
                    </div>
                }

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                    {[<div key={filtered[i]["id"]} className="donation-card">
                        <div className="donation-card-img">
                            <Package size={40} className="text-amber-400" />
                        </div>
                        <div className="p-5">
                            <div className="flex items-start justify-between gap-2 mb-2">
                                <h3 className="text-base font-bold text-foreground">{filtered[i]["title"]}</h3>
                                <span className={status_badge(filtered[i]["status"])}>{status_label(filtered[i]["status"])}</span>
                            </div>
                            <p className="text-sm text-muted-foreground mb-3 line-clamp-2">{filtered[i]["description"]}</p>
                            <div className="flex flex-col gap-1.5 mb-4">
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Package size={12} />
                                    {filtered[i]["quantity"] + " · " + filtered[i]["category"]}
                                </div>
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <MapPin size={12} />
                                    {filtered[i]["pickup_address"]}
                                </div>
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Clock size={12} />
                                    {"Expires: " + filtered[i]["expiry_date"]}
                                </div>
                            </div>
                            <div className="text-xs font-semibold text-muted-foreground mb-3">{filtered[i]["organization"]}</div>
                            <div className="flex gap-2">
                                <Link to={"/donations/" + filtered[i]["id"]} className="btn btn-primary btn-sm flex-1 text-center">
                                    {"View Details"}
                                </Link>
                                <Link to="/map" className="btn btn-sm flex items-center gap-1">
                                    <MapPin size={12} />
                                    {"Map"}
                                </Link>
                            </div>
                        </div>
                    </div>
                    for i in range(len(filtered))]}
                </div>
            </div>
        </div>
    );
}
