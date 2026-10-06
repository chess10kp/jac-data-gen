import from "@jac/runtime" { Link, useParams }
import from "lucide-react" { Package, MapPin, Clock, ArrowLeft, Navigation, Building2 }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_donations }

def:pub DonationDetails() -> JsxElement {
    has donation: any = None;
    has donations: list[any] = [];

    params: any = useParams();

    async can with entry {
        donations = get_mock_donations();
        did: str = str(params["id"]) if params["id"] else "";
        for d in donations {
            if d["id"] == did {
                donation = d;
                break;
            }
        }
    }

    if donation is None {
        return (
            <div className="min-h-screen bg-background">
                <Navbar role={"user"} />
                <div className="max-w-2xl mx-auto px-6 py-16 text-center">
                    <h1 className="text-xl font-bold text-foreground mb-2">{"Donation not found"}</h1>
                    <Link to="/donations/feed" className="btn btn-primary mt-4">{"Browse Donations"}</Link>
                </div>
            </div>
        );
    }

    title: str = str(donation["title"]) if donation else "";
    desc: str = str(donation["description"]) if donation else "";
    org: str = str(donation["organization"]) if donation else "";
    qty: str = str(donation["quantity"]) if donation else "";
    cat: str = str(donation["category"]) if donation else "";
    addr: str = str(donation["pickup_address"]) if donation else "";
    expiry: str = str(donation["expiry_date"]) if donation else "";
    storage: str = str(donation["storage_type"]) if donation else "";
    from_t: str = str(donation["available_from"]) if donation else "";
    until_t: str = str(donation["available_until"]) if donation else "";
    status: str = str(donation["status"]) if donation else "";

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-3xl mx-auto px-6 py-8">
                <Link to="/donations/feed" className="btn btn-ghost btn-sm flex items-center gap-1 mb-6 w-fit">
                    <ArrowLeft size={14} />
                    {"Back to Donations"}
                </Link>

                <div className="card overflow-hidden">
                    <div className="h-48 bg-gradient-to-br from-amber-50 to-amber-100 flex items-center justify-center">
                        <Package size={64} className="text-amber-300" />
                    </div>
                    <div className="p-6">
                        <div className="flex items-start justify-between gap-3 mb-4">
                            <h1 className="text-2xl font-bold text-foreground">{title}</h1>
                            <span className={"badge " + ("badge-red" if status == "expiring_soon" else "badge-green")}>
                                {status}
                            </span>
                        </div>
                        <p className="text-muted-foreground mb-6">{desc}</p>

                        <div className="grid grid-cols-2 gap-4 mb-6">
                            <div className="p-4 bg-muted rounded-xl">
                                <div className="text-xs text-muted-foreground mb-1">{"Quantity"}</div>
                                <div className="text-sm font-bold text-foreground">{qty}</div>
                            </div>
                            <div className="p-4 bg-muted rounded-xl">
                                <div className="text-xs text-muted-foreground mb-1">{"Category"}</div>
                                <div className="text-sm font-bold text-foreground">{cat}</div>
                            </div>
                            <div className="p-4 bg-muted rounded-xl">
                                <div className="text-xs text-muted-foreground mb-1">{"Expiry Date"}</div>
                                <div className="text-sm font-bold text-red-600">{expiry}</div>
                            </div>
                            <div className="p-4 bg-muted rounded-xl">
                                <div className="text-xs text-muted-foreground mb-1">{"Storage"}</div>
                                <div className="text-sm font-bold text-foreground">{storage}</div>
                            </div>
                        </div>

                        <div className="flex flex-col gap-3 mb-6">
                            <div className="flex items-center gap-2 text-sm text-foreground">
                                <Building2 size={16} className="text-muted-foreground" />
                                <span className="font-semibold">{org}</span>
                            </div>
                            <div className="flex items-center gap-2 text-sm text-foreground">
                                <MapPin size={16} className="text-muted-foreground" />
                                {addr}
                            </div>
                            <div className="flex items-center gap-2 text-sm text-foreground">
                                <Clock size={16} className="text-muted-foreground" />
                                {"Available: " + from_t + " – " + until_t}
                            </div>
                        </div>

                        <div className="h-40 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl flex items-center justify-center mb-6">
                            <div className="text-center">
                                <MapPin size={32} className="text-blue-300 mx-auto mb-2" />
                                <p className="text-sm text-blue-400">{"Map preview"}</p>
                            </div>
                        </div>

                        <div className="flex gap-3">
                            <button className="btn btn-primary flex-1 flex items-center justify-center gap-2">
                                <Navigation size={16} />
                                {"Navigate to Pickup"}
                            </button>
                            <Link to="/map" className="btn flex items-center gap-2">
                                <MapPin size={16} />
                                {"View on Map"}
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
