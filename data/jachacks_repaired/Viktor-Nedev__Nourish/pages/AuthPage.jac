import from "@jac/runtime" { useNavigate, jacLogin, jacSignup, Link, jacIsLoggedIn }
import from "lucide-react" { Leaf, Building2, User, ArrowRight, Check }

def:pub AuthPage() -> JsxElement {
    has tab: str = "login";
    has role: str = "user";
    has username: str = "";
    has password: str = "";
    has confirm_pw: str = "";
    has error: str = "";
    has loading: bool = False;

    navigate = useNavigate();

    if jacIsLoggedIn() {
        navigate("/dashboard/user");
    }

    def set_tab_login(e: MouseEvent) -> None { tab = "login"; error = ""; }
    def set_tab_register(e: MouseEvent) -> None { tab = "register"; error = ""; }
    def set_role_user(e: MouseEvent) -> None { role = "user"; }
    def set_role_org(e: MouseEvent) -> None { role = "org"; }
    def handle_username(e: ChangeEvent) -> None { username = e.target.value; }
    def handle_password(e: ChangeEvent) -> None { password = e.target.value; }
    def handle_confirm(e: ChangeEvent) -> None { confirm_pw = e.target.value; }

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        ok: bool = False;
        signup_result: any = None;
        try {
            if tab == "login" {
                ok = await jacLogin(username, password);
                if ok {
                    if role == "org" {
                        navigate("/dashboard/org");
                    } else {
                        navigate("/dashboard/user");
                    }
                } else {
                    error = "Invalid username or password.";
                }
            } else {
                if password != confirm_pw {
                    error = "Passwords do not match.";
                    loading = False;
                    return;
                }
                signup_result = await jacSignup(username, password);
                if signup_result {
                    ok = await jacLogin(username, password);
                    if ok {
                        navigate("/onboarding");
                    } else {
                        error = "Account created. Please sign in.";
                        tab = "login";
                    }
                } else {
                    error = "Username may already be taken.";
                }
            }
        } except Exception as ex {
            error = "Authentication error. Please try again.";
        }
        loading = False;
    }

    return (
        <div className="auth-page">
            <div className="auth-left relative overflow-hidden">
                <div className="bg-animated-gradient absolute inset-0" />
                <div className="hero-particle" style={{"width": "250px", "height": "250px", "top": "-10%", "right": "-10%", "animationDuration": "10s"}} />
                <div className="hero-particle" style={{"width": "150px", "height": "150px", "bottom": "10%", "left": "-5%", "animationDelay": "3s", "background": "rgba(245,158,11,0.12)"}} />

                <div className="relative z-10 anim-fade-in-left">
                    <div className="flex items-center gap-3 mb-10">
                        <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{"background": "rgba(255,255,255,0.15)"}}>
                            <Leaf size={22} color="white" />
                        </div>
                        <span className="text-2xl font-bold text-white">{"Nourish"}</span>
                    </div>
                    <h2 className="text-4xl font-bold text-white mb-5 leading-tight">{"Rescue food."}<br />{"Feed communities."}</h2>
                    <p className="text-white/70 text-base leading-relaxed mb-10">
                        {"Join thousands of organizations and individuals working together to eliminate food waste and fight hunger."}
                    </p>
                </div>

                <div className="relative z-10 flex flex-col gap-4 anim-fade-in-up delay-300">
                    <div className="flex items-center gap-3 text-white/80 text-sm">
                        <div className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0" style={{"background": "rgba(255,255,255,0.15)"}}>
                            <Check size={13} />
                        </div>
                        {"Real-time food matching with AI"}
                    </div>
                    <div className="flex items-center gap-3 text-white/80 text-sm">
                        <div className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0" style={{"background": "rgba(255,255,255,0.15)"}}>
                            <Check size={13} />
                        </div>
                        {"Live map of donations and requests"}
                    </div>
                    <div className="flex items-center gap-3 text-white/80 text-sm">
                        <div className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0" style={{"background": "rgba(255,255,255,0.15)"}}>
                            <Check size={13} />
                        </div>
                        {"Impact tracking and analytics"}
                    </div>
                </div>
            </div>

            <div className="auth-right">
                <div className="auth-form-box anim-fade-in-right">
                    <div className="mb-8">
                        <h1 className="text-2xl font-bold text-foreground mb-1">
                            {"Welcome back" if tab == "login" else "Create your account"}
                        </h1>
                        <p className="text-muted-foreground text-sm">
                            {"Sign in to your Nourish account" if tab == "login" else "Join the food rescue network"}
                        </p>
                    </div>

                    <div className="tabs mb-6">
                        <button className={"tab " + ("tab-active" if tab == "login" else "")} onClick={set_tab_login}>
                            {"Sign in"}
                        </button>
                        <button className={"tab " + ("tab-active" if tab == "register" else "")} onClick={set_tab_register}>
                            {"Create account"}
                        </button>
                    </div>

                    {tab == "register" and
                        <div className="mb-5 anim-scale-in">
                            <div className="label">{"I am a..."}</div>
                            <div className="grid grid-cols-2 gap-3">
                                <button
                                    className={"card card-p flex flex-col items-center gap-2 cursor-pointer border-2 card-cinematic " + ("border-primary bg-primary-light" if role == "user" else "border-border")}
                                    onClick={set_role_user}
                                >
                                    <User size={24} className={"text-primary" if role == "user" else "text-muted-foreground"} />
                                    <span className={"text-sm font-semibold " + ("text-primary" if role == "user" else "text-foreground")}>{"Individual"}</span>
                                    <span className="text-xs text-muted-foreground text-center">{"Find food, make requests"}</span>
                                </button>
                                <button
                                    className={"card card-p flex flex-col items-center gap-2 cursor-pointer border-2 card-cinematic " + ("border-primary bg-primary-light" if role == "org" else "border-border")}
                                    onClick={set_role_org}
                                >
                                    <Building2 size={24} className={"text-primary" if role == "org" else "text-muted-foreground"} />
                                    <span className={"text-sm font-semibold " + ("text-primary" if role == "org" else "text-foreground")}>{"Organization"}</span>
                                    <span className="text-xs text-muted-foreground text-center">{"Donate food, manage events"}</span>
                                </button>
                            </div>
                        </div>
                    }

                    <form onSubmit={handle_submit} className="flex flex-col gap-4">
                        <div className="form-group anim-fade-in-up delay-100">
                            <label className="label">{"Username"}</label>
                            <input className="input" type="text" placeholder="Enter username" value={username} onChange={handle_username} required={True} />
                        </div>
                        <div className="form-group anim-fade-in-up delay-200">
                            <label className="label">{"Password"}</label>
                            <input className="input" type="password" placeholder="Enter password" value={password} onChange={handle_password} required={True} />
                        </div>
                        {tab == "register" and
                            <div className="form-group anim-fade-in-up delay-300">
                                <label className="label">{"Confirm Password"}</label>
                                <input className="input" type="password" placeholder="Confirm password" value={confirm_pw} onChange={handle_confirm} required={True} />
                            </div>
                        }
                        {error and <div className="error-box anim-scale-in">{error}</div>}
                        <button className="btn btn-primary w-full btn-cinematic ripple-container anim-fade-in-up delay-400" type="submit" disabled={loading}>
                            {loading and <span className="spinner" />}
                            {not loading and (("Sign in" if tab == "login" else "Create account"))}
                        </button>
                    </form>

                    <p className="text-center text-xs text-muted-foreground mt-6">
                        {"By continuing, you agree to Nourish's Terms of Service and Privacy Policy."}
                    </p>
                </div>
            </div>
        </div>
    );
}
