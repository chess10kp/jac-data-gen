import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate, Link }
import from "lucide-react" { Package, ArrowLeft }
import from ..components.Navbar { Navbar }

def:pub CreateDonation() -> JsxElement {
    has title: str = "";
    has description: str = "";
    has category: str = "Vegetables";
    has quantity: str = "";
    has expiry_date: str = "";
    has pickup_address: str = "";
    has available_from: str = "08:00";
    has available_until: str = "18:00";
    has storage_type: str = "Room temperature";
    has notes: str = "";
    has loading: bool = False;
    has success: bool = False;
    has error: str = "";

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    navigate = useNavigate();

    def h(field: str, e: ChangeEvent) -> None { }
    def h_title(e: ChangeEvent) -> None { title = e.target.value; }
    def h_desc(e: ChangeEvent) -> None { description = e.target.value; }
    def h_cat(e: ChangeEvent) -> None { category = e.target.value; }
    def h_qty(e: ChangeEvent) -> None { quantity = e.target.value; }
    def h_expiry(e: ChangeEvent) -> None { expiry_date = e.target.value; }
    def h_addr(e: ChangeEvent) -> None { pickup_address = e.target.value; }
    def h_from(e: ChangeEvent) -> None { available_from = e.target.value; }
    def h_until(e: ChangeEvent) -> None { available_until = e.target.value; }
    def h_storage(e: ChangeEvent) -> None { storage_type = e.target.value; }
    def h_notes(e: ChangeEvent) -> None { notes = e.target.value; }

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        try {
            success = True;
            setTimeout(lambda -> None { navigate("/donations/feed"); }, 1500);
        } except Exception as ex {
            error = "Failed to post donation. Please try again.";
        }
        loading = False;
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"org"} />
            <div className="max-w-2xl mx-auto px-6 py-8">
                <div className="flex items-center gap-3 mb-6">
                    <Link to="/donations/feed" className="btn btn-ghost btn-sm flex items-center gap-1">
                        <ArrowLeft size={14} />
                        {"Back"}
                    </Link>
                    <div>
                        <h1 className="page-title">{"Post Food Donation"}</h1>
                        <p className="page-subtitle">{"Share surplus food with your community."}</p>
                    </div>
                </div>

                {success and
                    <div className="alert-banner alert-banner-green mb-6">
                        <div className="font-semibold">{"Donation posted successfully!"}</div>
                        <div className="text-sm">{"Redirecting to donations feed..."}</div>
                    </div>
                }

                <div className="card">
                    <form onSubmit={handle_submit} className="p-6 flex flex-col gap-5">
                        <div className="form-group">
                            <label className="label">{"Donation Title *"}</label>
                            <input className="input" type="text" placeholder="e.g. Fresh Vegetables Mix" value={title} onChange={h_title} required={True} />
                        </div>

                        <div className="form-group">
                            <label className="label">{"Description *"}</label>
                            <textarea className="textarea" rows={3} placeholder="Describe the food items, condition, and any relevant details..." value={description} onChange={h_desc} required={True} />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Category *"}</label>
                                <select className="select" value={category} onChange={h_cat}>
                                    <option value="Vegetables">{"Vegetables & Fruits"}</option>
                                    <option value="Bread & Bakery">{"Bread & Bakery"}</option>
                                    <option value="Dairy">{"Dairy Products"}</option>
                                    <option value="Canned Goods">{"Canned Goods"}</option>
                                    <option value="Prepared Meals">{"Prepared Meals"}</option>
                                    <option value="Other">{"Other"}</option>
                                </select>
                            </div>
                            <div className="form-group">
                                <label className="label">{"Quantity *"}</label>
                                <input className="input" type="text" placeholder="e.g. 45 kg or 30 loaves" value={quantity} onChange={h_qty} required={True} />
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Expiry Date *"}</label>
                                <input className="input" type="date" value={expiry_date} onChange={h_expiry} required={True} />
                            </div>
                            <div className="form-group">
                                <label className="label">{"Storage Type"}</label>
                                <select className="select" value={storage_type} onChange={h_storage}>
                                    <option value="Room temperature">{"Room temperature"}</option>
                                    <option value="Refrigerated">{"Refrigerated"}</option>
                                    <option value="Frozen">{"Frozen"}</option>
                                    <option value="Hot holding">{"Hot holding"}</option>
                                    <option value="Dry storage">{"Dry storage"}</option>
                                </select>
                            </div>
                        </div>

                        <div className="form-group">
                            <label className="label">{"Pickup Address *"}</label>
                            <input className="input" type="text" placeholder="Full pickup address" value={pickup_address} onChange={h_addr} required={True} />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="form-group">
                                <label className="label">{"Available From"}</label>
                                <input className="input" type="time" value={available_from} onChange={h_from} />
                            </div>
                            <div className="form-group">
                                <label className="label">{"Available Until"}</label>
                                <input className="input" type="time" value={available_until} onChange={h_until} />
                            </div>
                        </div>

                        <div className="form-group">
                            <label className="label">{"Additional Notes"}</label>
                            <textarea className="textarea" rows={2} placeholder="any special instructions for pickup..." value={notes} onChange={h_notes} />
                        </div>

                        {error and <div className="error-box">{error}</div>}

                        <div className="flex gap-3 pt-2">
                            <Link to="/donations/feed" className="btn flex-1 text-center">{"Cancel"}</Link>
                            <button className="btn btn-primary flex-1" type="submit" disabled={loading}>
                                {loading and <span className="spinner" />}
                                {not loading and "Post Donation"}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
}
