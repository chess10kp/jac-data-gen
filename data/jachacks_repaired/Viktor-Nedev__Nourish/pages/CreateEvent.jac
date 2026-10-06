import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate, Link }
import from "lucide-react" { Calendar, ArrowLeft }
import from ..components.Navbar { Navbar }

def:pub CreateEvent() -> JsxElement {
    has title: str = "";
    has description: str = "";
    has event_date: str = "";
    has event_time: str = "10:00";
    has address: str = "";
    has food_type: str = "Mixed";
    has capacity: str = "100";
    has notes: str = "";
    has loading: bool = False;
    has success: bool = False;

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    navigate = useNavigate();

    def h_title(e: ChangeEvent) -> None { title = e.target.value; }
    def h_desc(e: ChangeEvent) -> None { description = e.target.value; }
    def h_date(e: ChangeEvent) -> None { event_date = e.target.value; }
    def h_time(e: ChangeEvent) -> None { event_time = e.target.value; }
    def h_addr(e: ChangeEvent) -> None { address = e.target.value; }
    def h_food(e: ChangeEvent) -> None { food_type = e.target.value; }
    def h_cap(e: ChangeEvent) -> None { capacity = e.target.value; }
    def h_notes(e: ChangeEvent) -> None { notes = e.target.value; }

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        success = True;
        setTimeout(lambda -> None { navigate("/events"); }, 1500);
        loading = False;
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"org"} />
            <div className="max-w-2xl mx-auto px-6 py-8">
                <div className="flex items-center gap-3 mb-6">
                    <Link to="/events" className="btn btn-ghost btn-sm flex items-center gap-1">
                        <ArrowLeft size={14} />
                        {"Back"}
                    </Link>
                    <div>
                        <h1 className="page-title">{"Create Event"}</h1>
                        <p className="page-subtitle">{"Organize a food distribution or community event."}</p>
                    </div>
                </div>
                {success and <div className="alert-banner alert-banner-green mb-6"><div className="font-semibold">{"Event created! Redirecting..."}</div></div>}
                <div className="card">
                    <form onSubmit={handle_submit} className="p-6 flex flex-col gap-4">
                        <div className="form-group">
                            <label className="label">{"Event Title *"}</label>
                            <input className="input" type="text" placeholder="e.g. Community Food Distribution Day" value={title} onChange={h_title} required={True} />
                        </div>
                        <div className="form-group">
                            <label className="label">{"Description *"}</label>
                            <textarea className="textarea" rows={3} placeholder="Describe the event..." value={description} onChange={h_desc} required={True} />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Date *"}</label>
                                <input className="input" type="date" value={event_date} onChange={h_date} required={True} />
                            </div>
                            <div className="form-group">
                                <label className="label">{"Time *"}</label>
                                <input className="input" type="time" value={event_time} onChange={h_time} required={True} />
                            </div>
                        </div>
                        <div className="form-group">
                            <label className="label">{"Address *"}</label>
                            <input className="input" type="text" placeholder="Full event address" value={address} onChange={h_addr} required={True} />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Food Type"}</label>
                                <select className="select" value={food_type} onChange={h_food}>
                                    <option value="Mixed">{"Mixed / General"}</option>
                                    <option value="Hot meals">{"Hot Meals"}</option>
                                    <option value="Groceries">{"Groceries"}</option>
                                    <option value="Halal">{"Halal"}</option>
                                    <option value="Vegetarian">{"Vegetarian"}</option>
                                </select>
                            </div>
                            <div className="form-group">
                                <label className="label">{"Capacity *"}</label>
                                <input className="input" type="number" min="1" placeholder="100" value={capacity} onChange={h_cap} required={True} />
                            </div>
                        </div>
                        <div className="form-group">
                            <label className="label">{"Notes"}</label>
                            <textarea className="textarea" rows={2} placeholder="any additional info..." value={notes} onChange={h_notes} />
                        </div>
                        <div className="flex gap-3 pt-2">
                            <Link to="/events" className="btn flex-1 text-center">{"Cancel"}</Link>
                            <button className="btn btn-primary flex-1" type="submit" disabled={loading}>
                                {loading and <span className="spinner" />}
                                {not loading and "Create Event"}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
