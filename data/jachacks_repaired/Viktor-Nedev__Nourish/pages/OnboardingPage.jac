import from "@jac/runtime" { useNavigate, jacIsLoggedIn, Navigate }
import from "lucide-react" { User, Building2, ArrowRight }
import from ..components.Navbar { Navbar }

def:pub OnboardingPage() -> JsxElement {
    has role: str = "user";
    has name: str = "";
    has phone: str = "";
    has location: str = "";
    has org_name: str = "";
    has org_type: str = "food_bank";
    has address: str = "";
    has loading: bool = False;

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    navigate = useNavigate();

    def h_name(e: ChangeEvent) -> None { name = e.target.value; }
    def h_phone(e: ChangeEvent) -> None { phone = e.target.value; }
    def h_loc(e: ChangeEvent) -> None { location = e.target.value; }
    def h_org(e: ChangeEvent) -> None { org_name = e.target.value; }
    def h_type(e: ChangeEvent) -> None { org_type = e.target.value; }
    def h_addr(e: ChangeEvent) -> None { address = e.target.value; }
    def set_user(e: MouseEvent) -> None { role = "user"; }
    def set_org(e: MouseEvent) -> None { role = "org"; }

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        if role == "org" {
            navigate("/dashboard/org");
        } else {
            navigate("/dashboard/user");
        }
        loading = False;
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={role} />
            <div className="max-w-xl mx-auto px-6 py-12">
                <div className="text-center mb-8">
                    <h1 className="text-2xl font-bold text-foreground mb-2">{"Complete your profile"}</h1>
                    <p className="text-muted-foreground">{"Help us personalize your Nourish experience."}</p>
                </div>

                <div className="grid grid-cols-2 gap-3 mb-6">
                    <button className={"card card-p flex flex-col items-center gap-2 cursor-pointer border-2 " + ("border-primary bg-primary-light" if role == "user" else "border-border")} onClick={set_user}>
                        <User size={24} className={"text-primary" if role == "user" else "text-muted-foreground"} />
                        <span className="text-sm font-semibold">{"Individual"}</span>
                    </button>
                    <button className={"card card-p flex flex-col items-center gap-2 cursor-pointer border-2 " + ("border-primary bg-primary-light" if role == "org" else "border-border")} onClick={set_org}>
                        <Building2 size={24} className={"text-primary" if role == "org" else "text-muted-foreground"} />
                        <span className="text-sm font-semibold">{"Organization"}</span>
                    </button>
                </div>

                <div className="card">
                    <form onSubmit={handle_submit} className="p-6 flex flex-col gap-4">
                        {role == "user" and
                            <div>
                                <div className="form-group">
                                    <label className="label">{"Your Name *"}</label>
                                    <input className="input" type="text" placeholder="Full name" value={name} onChange={h_name} required={True} />
                                </div>
                                <div className="form-group mt-4">
                                    <label className="label">{"Phone (optional)"}</label>
                                    <input className="input" type="tel" placeholder="+1 (555) 000-0000" value={phone} onChange={h_phone} />
                                </div>
                                <div className="form-group mt-4">
                                    <label className="label">{"Approximate Location *"}</label>
                                    <input className="input" type="text" placeholder="Neighborhood or city" value={location} onChange={h_loc} required={True} />
                                </div>
                            </div>
                        }
                        {role == "org" and
                            <div>
                                <div className="form-group">
                                    <label className="label">{"Organization Name *"}</label>
                                    <input className="input" type="text" placeholder="Organization name" value={org_name} onChange={h_org} required={True} />
                                </div>
                                <div className="form-group mt-4">
                                    <label className="label">{"Organization Type *"}</label>
                                    <select className="select" value={org_type} onChange={h_type}>
                                        <option value="food_bank">{"Food Bank"}</option>
                                        <option value="shelter">{"Shelter"}</option>
                                        <option value="restaurant">{"Restaurant"}</option>
                                        <option value="supermarket">{"Supermarket"}</option>
                                        <option value="ngo">{"NGO / Charity"}</option>
                                        <option value="community">{"Community Center"}</option>
                                    </select>
                                </div>
                                <div className="form-group mt-4">
                                    <label className="label">{"Address *"}</label>
                                    <input className="input" type="text" placeholder="Full address" value={address} onChange={h_addr} required={True} />
                                </div>
                            </div>
                        }
                        <button className="btn btn-primary w-full mt-2 flex items-center justify-center gap-2" type="submit" disabled={loading}>
                            {"Complete Setup"}
                            <ArrowRight size={16} />
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}
