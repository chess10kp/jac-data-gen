cl import from "@jac/runtime" {
    jacLogin,
    jacSignup,
    jacLogout,
    jacIsLoggedIn,
    Router,
    Routes,
    Route,
    Link,
    useNavigate
}

cl {
    # === Login Page ===
    def:pub LoginPage() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";
        has loading: bool = False;

        navigate = useNavigate();

        # Check if already logged in
        can with entry {
            if jacIsLoggedIn() {
                navigate("/");
            }
        }

        async def handleLogin(e: FormEvent) -> None {
            e.preventDefault();
            error = "";

            if not username.trim() or not password {
                error = "Please fill in all fields";
                return;
            }

            loading = True;
            success = await jacLogin(username, password);
            loading = False;

            if success {
                navigate("/");
            } else {
                error = "Invalid username or password";
            }
        }

        return <div style={{"maxWidth": "400px", "margin": "2rem auto", "padding": "2rem"}}>
            <h2>Login</h2>
            <form onSubmit={handleLogin}>
                {error and <div style={{"color": "#dc2626", "marginBottom": "1rem"}}>{error}</div>}

                <div style={{"marginBottom": "1rem"}}>
                    <input
                        type="text"
                        value={username}
                        onChange={lambda e: ChangeEvent { username = e.target.value; }}
                        placeholder="Username"
                        style={{"width": "100%", "padding": "0.75rem", "border": "1px solid #ddd", "borderRadius": "4px"}}
                    />
                </div>

                <div style={{"marginBottom": "1rem"}}>
                    <input
                        type="password"
                        value={password}
                        onChange={lambda e: ChangeEvent { password = e.target.value; }}
                        placeholder="Password"
                        style={{"width": "100%", "padding": "0.75rem", "border": "1px solid #ddd", "borderRadius": "4px"}}
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading}
                    style={{
                        "width": "100%",
                        "padding": "0.75rem",
                        "background": "#3b82f6",
                        "color": "white",
                        "border": "none",
                        "borderRadius": "4px",
                        "cursor": "pointer"
                    }}
                >
                    {loading and "Logging in..." or "Login"}
                </button>

                <p style={{"textAlign": "center", "marginTop": "1rem"}}>
                    Need an account? <Link to="/signup">Sign up</Link>
                </p>
            </form>
        </div>;
    }

    # === Signup Page ===
    def:pub SignupPage() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has confirmPassword: str = "";
        has error: str = "";
        has loading: bool = False;

        navigate = useNavigate();

        async def handleSignup(e: FormEvent) -> None {
            e.preventDefault();
            error = "";

            if not username.trim() or not password {
                error = "Please fill in all fields";
                return;
            }

            if password != confirmPassword {
                error = "Passwords don't match";
                return;
            }

            if password.length < 6 {
                error = "Password must be at least 6 characters";
                return;
            }

            loading = True;
            result = await jacSignup(username, password);
            loading = False;

            if result["success"] {
                navigate("/");
            } else {
                error = result["error"] or "Signup failed";
            }
        }

        return <div style={{"maxWidth": "400px", "margin": "2rem auto", "padding": "2rem"}}>
            <h2>Create Account</h2>
            <form onSubmit={handleSignup}>
                {error and <div style={{"color": "#dc2626", "marginBottom": "1rem"}}>{error}</div>}

                <div style={{"marginBottom": "1rem"}}>
                    <input
                        type="text"
                        value={username}
                        onChange={lambda e: ChangeEvent { username = e.target.value; }}
                        placeholder="Username"
                        style={{"width": "100%", "padding": "0.75rem", "border": "1px solid #ddd", "borderRadius": "4px"}}
                    />
                </div>

                <div style={{"marginBottom": "1rem"}}>
                    <input
                        type="password"
                        value={password}
                        onChange={lambda e: ChangeEvent { password = e.target.value; }}
                        placeholder="Password"
                        style={{"width": "100%", "padding": "0.75rem", "border": "1px solid #ddd", "borderRadius": "4px"}}
                    />
                </div>

                <div style={{"marginBottom": "1rem"}}>
                    <input
                        type="password"
                        value={confirmPassword}
                        onChange={lambda e: ChangeEvent { confirmPassword = e.target.value; }}
                        placeholder="Confirm Password"
                        style={{"width": "100%", "padding": "0.75rem", "border": "1px solid #ddd", "borderRadius": "4px"}}
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading}
                    style={{
                        "width": "100%",
                        "padding": "0.75rem",
                        "background": "#10b981",
                        "color": "white",
                        "border": "none",
                        "borderRadius": "4px",
                        "cursor": "pointer"
                    }}
                >
                    {loading and "Creating account..." or "Sign Up"}
                </button>

                <p style={{"textAlign": "center", "marginTop": "1rem"}}>
                    Already have an account? <Link to="/login">Login</Link>
                </p>
            </form>
        </div>;
    }

    # === Protected Dashboard ===
    def:pub Dashboard() -> JsxElement {
        navigate = useNavigate();

        # Redirect if not logged in
        can with entry {
            if not jacIsLoggedIn() {
                navigate("/login");
            }
        }

        def handleLogout() -> None {
            jacLogout();
            navigate("/login");
        }

        if not jacIsLoggedIn() {
            return <p>Redirecting...</p>;
        }

        return <div style={{"padding": "2rem"}}>
            <h1>Dashboard</h1>
            <p>Welcome! You are logged in.</p>
            <button
                onClick={lambda -> None { handleLogout(); }}
                style={{
                    "padding": "0.5rem 1rem",
                    "background": "#ef4444",
                    "color": "white",
                    "border": "none",
                    "borderRadius": "4px",
                    "cursor": "pointer"
                }}
            >
                Logout
            </button>
        </div>;
    }

    # === Main App ===
    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/signup" element={<SignupPage />} />
            </Routes>
        </Router>;
    }
}
