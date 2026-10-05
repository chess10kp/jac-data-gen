import from "@jac/runtime" { jacLogin, jacSignup, useNavigate }

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
                    error = "Invalid credentials. Try demo / demo123";
                }
            } else {
                signup_res = await jacSignup(username, password);
                if signup_res {
                    login_after = await jacLogin(username, password);
                    if login_after {
                        navigate("/dashboard");
                    } else {
                        error = "Account created — please sign in";
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

    def handle_username(e: ChangeEvent) -> None {
        username = e.target.value;
    }

    def handle_password(e: ChangeEvent) -> None {
        password = e.target.value;
    }

    def toggle_mode(e: MouseEvent) -> None {
        is_login = not is_login;
        error = "";
    }

    return (
        <div className="min-h-screen bg-background grid-bg flex items-center justify-center relative overflow-hidden">
            <div style={{"position": "absolute", "top": "10%", "left": "20%", "width": "400px", "height": "400px", "background": "radial-gradient(circle, rgba(59,130,246,0.08) 0%, transparent 70%)", "pointerEvents": "none"}}></div>
            <div style={{"position": "absolute", "bottom": "10%", "right": "20%", "width": "300px", "height": "300px", "background": "radial-gradient(circle, rgba(139,92,246,0.06) 0%, transparent 70%)", "pointerEvents": "none"}}></div>

            <div className="w-full max-w-md px-6 animate-fade-in-up">
                <div className="text-center mb-10">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-4 animate-pulse-glow" style={{"background": "linear-gradient(135deg, rgba(59,130,246,0.2), rgba(139,92,246,0.2))", "border": "1px solid rgba(59,130,246,0.3)"}}>
                        <span style={{"fontSize": "28px"}}>⚡</span>
                    </div>
                    <h1 className="text-3xl font-bold text-gradient-blue mb-2">FutureOS</h1>
                    <p className="text-muted-foreground text-sm">Your Adaptive AI Life Operating System</p>
                </div>

                <div className="glass-bright p-8">
                    <div className="mb-6">
                        <h2 className="text-xl font-semibold text-foreground mb-1">
                            {"Welcome back" if is_login else "Begin your journey"}
                        </h2>
                        <p className="text-muted-foreground text-sm">
                            {"Sign in to your AI workspace" if is_login else "Create your AI-powered life OS"}
                        </p>
                    </div>

                    {error and (
                        <div className="error-box mb-5">{error}</div>
                    )}

                    <form onSubmit={handle_submit}>
                        <div className="mb-4">
                            <label className="label">Username</label>
                            <input
                                className="input"
                                type="text"
                                value={username}
                                onChange={handle_username}
                                placeholder="Enter your username"
                                required={True}
                            />
                        </div>
                        <div className="mb-6">
                            <label className="label">Password</label>
                            <input
                                className="input"
                                type="password"
                                value={password}
                                onChange={handle_password}
                                placeholder="Enter your password"
                                required={True}
                            />
                        </div>

                        <button
                            type="submit"
                            className="btn btn-primary w-full py-3 text-base"
                            disabled={loading}
                        >
                            {loading and (
                                <span className="flex items-center gap-2 justify-center">
                                    <span className="typing-dot"></span>
                                    <span className="typing-dot"></span>
                                    <span className="typing-dot"></span>
                                    <span>{"Authenticating..."}</span>
                                </span>
                            )}
                            {not loading and (
                                <span>{"Sign In" if is_login else "Create Account"}</span>
                            )}
                        </button>
                    </form>

                    <div className="mt-6 text-center">
                        <span className="text-muted-foreground text-sm">
                            {"Don't have an account? " if is_login else "Already have an account? "}
                        </span>
                        <button
                            className="text-primary text-sm font-medium hover:text-blue-400 transition-colors"
                            onClick={toggle_mode}
                        >
                            {"Sign up" if is_login else "Sign in"}
                        </button>
                    </div>
                </div>

                <div className="mt-8 grid grid-cols-3 gap-3">
                    <div className="text-center p-3 rounded-xl" style={{"background": "rgba(59,130,246,0.05)", "border": "1px solid rgba(59,130,246,0.1)"}}>
                        <div className="text-lg mb-1">🤖</div>
                        <div className="text-xs text-muted-foreground">6 AI Agents</div>
                    </div>
                    <div className="text-center p-3 rounded-xl" style={{"background": "rgba(139,92,246,0.05)", "border": "1px solid rgba(139,92,246,0.1)"}}>
                        <div className="text-lg mb-1">🧠</div>
                        <div className="text-xs text-muted-foreground">Memory OS</div>
                    </div>
                    <div className="text-center p-3 rounded-xl" style={{"background": "rgba(6,182,212,0.05)", "border": "1px solid rgba(6,182,212,0.1)"}}>
                        <div className="text-lg mb-1">⚡</div>
                        <div className="text-xs text-muted-foreground">Daily Missions</div>
                    </div>
                </div>
            </div>
        </div>
    );
}
