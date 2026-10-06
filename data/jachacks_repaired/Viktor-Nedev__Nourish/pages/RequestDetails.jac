import from "@jac/runtime" { Link, useParams }
import from "lucide-react" { Users, MapPin, Clock, ArrowLeft, Navigation, MessageSquare }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_requests }

def:pub RequestDetails() -> JsxElement {
    has request: any = None;
    has requests: list[any] = [];
    has comment: str = "";

    params: any = useParams();

    async can with entry {
        requests = get_mock_requests();
        rid: str = str(params["id"]) if params["id"] else "";
        for r in requests {
            if r["id"] == rid {
                request = r;
                break;
            }
        }
    }

    def h_comment(e: ChangeEvent) -> None { comment = e.target.value; }

    if request is None {
        return (
            <div className="min-h-screen bg-background">
                <Navbar role={"user"} />
                <div className="max-w-2xl mx-auto px-6 py-16 text-center">
                    <h1 className="text-xl font-bold text-foreground mb-2">{"Request not found"}</h1>
                    <Link to="/requests" className="btn btn-primary mt-4">{"Browse Requests"}</Link>
                </div>
            </div>
        );
    }

    title: str = str(request["title"]) if request else "";
    desc: str = str(request["description"]) if request else "";
    cmt: str = str(request["comment"]) if request else "";
    loc: str = str(request["location_text"]) if request else "";
    urgency: str = str(request["urgency"]) if request else "";
    people: str = str(request["people_count"]) if request else "";
    food: str = str(request["food_type"]) if request else "";
    posted: str = str(request["posted_by"]) if request else "";
    created: str = str(request["created_at"]) if request else "";

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-3xl mx-auto px-6 py-8">
                <Link to="/requests" className="btn btn-ghost btn-sm flex items-center gap-1 mb-6 w-fit">
                    <ArrowLeft size={14} />
                    {"Back to Requests"}
                </Link>

                <div className="card p-6 mb-5">
                    <div className="flex items-start justify-between gap-3 mb-4">
                        <h1 className="text-2xl font-bold text-foreground">{title}</h1>
                        <span className={"urgency-" + urgency}>{urgency}</span>
                    </div>
                    <p className="text-muted-foreground mb-4">{desc}</p>
                    {cmt and <p className="text-sm text-muted-foreground italic mb-4">{cmt}</p>}

                    <div className="grid grid-cols-2 gap-4 mb-5">
                        <div className="p-3 bg-muted rounded-lg">
                            <div className="text-xs text-muted-foreground">{"People"}</div>
                            <div className="text-lg font-bold text-foreground">{people}</div>
                        </div>
                        <div className="p-3 bg-muted rounded-lg">
                            <div className="text-xs text-muted-foreground">{"Food Type"}</div>
                            <div className="text-sm font-bold text-foreground">{food}</div>
                        </div>
                    </div>

                    <div className="flex flex-col gap-2 mb-5">
                        <div className="flex items-center gap-2 text-sm text-foreground">
                            <MapPin size={14} className="text-muted-foreground" />
                            {loc}
                        </div>
                        <div className="flex items-center gap-2 text-sm text-foreground">
                            <Clock size={14} className="text-muted-foreground" />
                            {created}
                        </div>
                        <div className="flex items-center gap-2 text-sm text-foreground">
                            <Users size={14} className="text-muted-foreground" />
                            {"Posted by: " + posted}
                        </div>
                    </div>

                    <div className="h-36 bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl flex items-center justify-center mb-5">
                        <div className="text-center">
                            <MapPin size={28} className="text-blue-300 mx-auto mb-1" />
                            <p className="text-xs text-blue-400">{"Location preview"}</p>
                        </div>
                    </div>

                    <div className="flex gap-3">
                        <button className="btn btn-primary flex-1 flex items-center justify-center gap-2">
                            <Navigation size={16} />
                            {"Navigate"}
                        </button>
                        <Link to="/map" className="btn flex items-center gap-2">
                            <MapPin size={16} />
                            {"View on Map"}
                        </Link>
                        <button className="btn btn-success flex items-center gap-2">
                            {"Offer Food"}
                        </button>
                    </div>
                </div>

                <div className="card p-6">
                    <h3 className="section-title">
                        <MessageSquare size={16} />
                        {"Comments"}
                    </h3>
                    <div className="flex gap-3">
                        <input className="input flex-1" type="text" placeholder="Add a comment..." value={comment} onChange={h_comment} />
                        <button className="btn btn-primary">{"Post"}</button>
                    </div>
                    <div className="mt-4 text-sm text-muted-foreground text-center">{"No comments yet. Be the first to respond."}</div>
                </div>
            </div>
        </div>
    );
}
