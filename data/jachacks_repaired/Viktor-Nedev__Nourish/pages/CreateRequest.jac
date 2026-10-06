import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate, Link }
import from "lucide-react" { Users, MapPin, AlertTriangle, ArrowLeft }
import from ..components.Navbar { Navbar }

def:pub CreateRequest() -> JsxElement {
    has title: str = "";
    has description: str = "";
    has comment: str = "";
    has people_count: str = "1";
    has urgency: str = "medium";
    has food_type: str = "";
    has location_text: str = "";
    has share_location: bool = False;
    has loading: bool = False;
    has success: bool = False;
    has error: str = "";

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    navigate = useNavigate();

    def h_title(e: ChangeEvent) -> None { title = e.target.value; }
    def h_desc(e: ChangeEvent) -> None { description = e.target.value; }
    def h_comment(e: ChangeEvent) -> None { comment = e.target.value; }
    def h_people(e: ChangeEvent) -> None { people_count = e.target.value; }
    def h_urgency(e: ChangeEvent) -> None { urgency = e.target.value; }
    def h_food(e: ChangeEvent) -> None { food_type = e.target.value; }
    def h_location(e: ChangeEvent) -> None { location_text = e.target.value; }
    def h_share(e: ChangeEvent) -> None { share_location = not share_location; }

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        try {
            success = True;
            setTimeout(lambda -> None { navigate("/requests"); }, 1500);
        } except Exception as ex {
            error = "Failed to submit request. Please try again.";
        }
        loading = False;
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-2xl mx-auto px-6 py-8">
                <div className="flex items-center gap-3 mb-6">
                    <Link to="/requests" className="btn btn-ghost btn-sm flex items-center gap-1">
                        <ArrowLeft size={14} />
                        {"Back"}
                    </Link>
                    <div>
                        <h1 className="page-title">{"Make a Food Request"}</h1>
                        <p className="page-subtitle">{"Tell us what you need and we'll connect you with nearby donors."}</p>
                    </div>
                </div>

                {success and
                    <div className="alert-banner alert-banner-green mb-6">
                        <div className="font-semibold">{"Request submitted successfully!"}</div>
                        <div className="text-sm">{"Redirecting to requests feed..."}</div>
                    </div>
                }

                <div className="card">
                    <form onSubmit={handle_submit} className="p-6 flex flex-col gap-5">
                        <div className="form-group">
                            <label className="label">{"Request Title *"}</label>
                            <input className="input" type="text" placeholder="e.g. Family of 4 needs groceries" value={title} onChange={h_title} required={True} />
                        </div>

                        <div className="form-group">
                            <label className="label">{"Description *"}</label>
                            <textarea className="textarea" rows={3} placeholder="Describe your situation and what kind of food you need..." value={description} onChange={h_desc} required={True} />
                        </div>

                        <div className="form-group">
                            <label className="label">{"Additional Comments"}</label>
                            <textarea className="textarea" rows={2} placeholder="any dietary restrictions, preferences, or additional info..." value={comment} onChange={h_comment} />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Number of People *"}</label>
                                <input className="input" type="number" min="1" placeholder="1" value={people_count} onChange={h_people} required={True} />
                            </div>
                            <div className="form-group">
                                <label className="label">{"Urgency Level *"}</label>
                                <select className="select" value={urgency} onChange={h_urgency}>
                                    <option value="low">{"Low — within a week"}</option>
                                    <option value="medium">{"Medium — within 2-3 days"}</option>
                                    <option value="high">{"High — within 24 hours"}</option>
                                    <option value="critical">{"Critical — immediate need"}</option>
                                </select>
                            </div>
                        </div>

                        <div className="form-group">
                            <label className="label">{"Preferred Food Type"}</label>
                            <select className="select" value={food_type} onChange={h_food}>
                                <option value="">{"any food"}</option>
                                <option value="vegetables">{"Vegetables & Fruits"}</option>
                                <option value="bread">{"Bread & Bakery"}</option>
                                <option value="dairy">{"Dairy Products"}</option>
                                <option value="canned">{"Canned Goods"}</option>
                                <option value="meals">{"Prepared Meals"}</option>
                                <option value="mixed">{"Mixed / any"}</option>
                            </select>
                        </div>

                        <div className="form-group">
                            <label className="label">{"Location *"}</label>
                            <input className="input" type="text" placeholder="e.g. East Village, Block 4 or your address" value={location_text} onChange={h_location} required={True} />
                        </div>

                        <div className="flex items-center gap-3 p-4 bg-muted rounded-lg">
                            <input type="checkbox" id="share_loc" checked={share_location} onChange={h_share} className="accent-primary w-4 h-4" />
                            <label htmlFor="share_loc" className="text-sm text-foreground cursor-pointer">
                                <span className="font-semibold">{"Share my precise location"}</span>
                                <span className="text-muted-foreground ml-1">{"(helps volunteers find you faster)"}</span>
                            </label>
                        </div>

                        {error and <div className="error-box">{error}</div>}

                        <div className="flex gap-3 pt-2">
                            <Link to="/requests" className="btn flex-1 text-center">{"Cancel"}</Link>
                            <button className="btn btn-primary flex-1" type="submit" disabled={loading}>
                                {loading and <span className="spinner" />}
                                {not loading and "Submit Request"}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
