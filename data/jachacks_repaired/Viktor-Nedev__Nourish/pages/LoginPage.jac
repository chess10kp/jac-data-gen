import from "@jac/runtime" { useNavigate, jacLogin, jacSignup }
import from "lucide-react" { Leaf }

def:pub page() -> JsxElement {
    has is_login: bool = True;
    has username: str = "";
    has password: str = "";
    has error: str = "";
    has loading: bool = False;

    navigate = useNavigate();

    async def handle_submit(e: FormEvent) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        try {
            if is_login {
                login_res = await jacLogin(username, password);
                if login_res {
                    navigate("/dashboard");
                } else {
                    error = "Invalid username or password.";
                }
            } else {
                signup_res = await jacSignup(username, password);
                if signup_res {
                    login_after = await jacLogin(username, password);
                    if login_after {
                        navigate("/dashboard");
                    } else {
                        error = "Account created — please sign in.";
                    }
                } else {
                    error = "Signup failed. Username may already be taken.";
                }
            }
        } except Exception as ex {
            error = "Authentication error. Please try again.";
        }
        loading = False;
    }

    def handle_username(e: ChangeEvent) -> None { username = e.target.value; }
    def handle_password(e: ChangeEvent) -> None { password = e.target.value; }

    def toggle_mode(e: MouseEvent) -> None {
        is_login = not is_login;
        error = "";
    }

    return (
        <div className="auth-page">
            <div className="auth-container">
                <div className="auth-header">
                    <div className="flex items-center justify-center gap-2 mb-3">
                        <div className="w-8 h-8 bg-primary rounded-md flex items-center justify-center">
                            <Leaf size={16} color="white" strokeWidth={2} />
                        </div>
                        <span className="text-xl font-bold text-foreground tracking-tight">{"Nourish"}</span>
                    </div>
                    <h1>{"Sign in" if is_login else "Create account"}</h1>
                    <p>{"Food Rescue Dispatcher Platform" if is_login else "Join the food rescue network"}</p>
                </div>

                <div className="auth-card">
                    <form className="auth-form" onSubmit={handle_submit}>
                        <div>
                            <label className="label">{"Username"}</label>
                            <input
                                className="input"
                                type="text"
                                placeholder="Enter username"
                                value={username}
                                onChange={handle_username}
                                required={True}
                            />
                        </div>
                        <div>
                            <label className="label">{"Password"}</label>
                            <input
                                className="input"
                                type="password"
                                placeholder="Enter password"
                                value={password}
                                onChange={handle_password}
                                required={True}
                            />
                        </div>

                        {error and <div className="error-box">{error}</div>}

                        <button
                            className="btn btn-primary w-full"
                            type="submit"
                            disabled={loading}
                        >
                            {("Signing in..." if loading else "Sign in") if is_login else ("Creating account..." if loading else "Create account")}
                        </button>
                    </form>

                    <div className="auth-toggle">
                        {("No account? " if is_login else "Already have an account? ")}
                        <button className="toggle-btn" onClick={toggle_mode}>
                            {"Sign up" if is_login else "Sign in"}
                        </button>
                    </div>
                </div>

                <p className="text-center text-xs text-muted-foreground mt-5">
                    {"Connecting surplus food with those who need it most."}
                </p>
            </div>
        </div>
    );
}
