import from "@jac/runtime" { useNavigate, jacLogin, jacSignup }

def:pub page() -> JsxElement {
    has is_login: bool = True;
    has username: str = "";
    has password: str = "";
    has error: str = "";
    has loading: bool = False;

    navigate = useNavigate();

    async def handle_submit(e: any) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        try {
            if is_login {
                login_res = await jacLogin(username, password);
                if login_res {
                    navigate("/dashboard");
                } else {
                    error = "Invalid username or password";
                }
            } else {
                signup_res = await jacSignup(username, password);
                if signup_res {
                    login_after_signup = await jacLogin(username, password);
                    if login_after_signup {
                        navigate("/dashboard");
                    } else {
                        error = "Account created — please sign in";
                    }
                } else {
                    error = "Signup failed. Username may already be taken.";
                }
            }
        } except Exception as e {
            error = "Authentication error. Please try again.";
        }
        loading = False;
    }

    def handle_username(e: any) -> None {
        username = e.target.value;
    }

    def handle_password(e: any) -> None {
        password = e.target.value;
    }

    def toggle_mode() -> None {
        is_login = not is_login;
        error = "";
    }

    return (
        <div className="auth-page">
            <div className="auth-container">
                <div className="auth-header">
<h1>{"Welcome" if is_login else "Create account"}</h1>
                    <p>{"Sign in to continue" if is_login else "Get started for free"}</p>
                </div>
                <div className="auth-card">
                    {error and (
                        <div className="error-box mb-5">
                            {error}
                        </div>
                    )}
                    <form
                        onSubmit={handle_submit}
                        className="auth-form"
                    >
                        <div>
                            <label className="label">Username</label>
                            <input
                                className="input"
                                type="text"
                                value={username}
                                onChange={handle_username}
                                placeholder="Enter your username"
                                required={True}
                                autoComplete="username"
                            />
                        </div>
                        <div>
                            <label className="label">Password</label>
                            <input
                                className="input"
                                type="password"
                                value={password}
                                onChange={handle_password}
                                placeholder="••••••••"
                                required={True}
                                autoComplete="current-password"
                            />
                        </div>
                        <button
                            className="btn btn-primary w-full h-12 mt-1"
                            type="submit"
                            disabled={loading}
                        >
                            {(
                                ("Signing in..." if is_login else "Signing up...")
                                if loading
                                else ("Sign in" if is_login else "Sign up")
                            )}
                        </button>
                    </form>
                    <div className="auth-toggle">
                        {"Don't have an account? " if is_login else "Already have an account? "}
                        <button
                            type="button"
                            className="toggle-btn"
                            onClick={toggle_mode}
                        >
                            {"Sign up" if is_login else "Sign in"}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
