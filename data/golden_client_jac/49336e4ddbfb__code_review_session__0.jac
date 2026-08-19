cl import from "@jac/runtime" { jacLogin, jacSignup, jacLogout, jacIsLoggedIn, useNavigate }

cl {
    def:pub LoginPage() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";
        has loading: bool = False;

        navigate = useNavigate();

        async def handleLogin(e: FormEvent) -> None {
            e.preventDefault();
            error = "";

            if not username or not password {
                error = "Please fill in all fields";
                return;
            }

            loading = True;
            try {
                success = await jacLogin(username, password);
                if success {
                    navigate("/");
                } else {
                    error = "Invalid credentials";
                }
            } except Exception as ex {
                error = "Login failed, please try again";
            } finally {
                loading = False;
            }
        }

        return <div style={{"maxWidth": "400px", "margin": "0 auto", "padding": "2rem"}}>
            <h2>Login</h2>
            <form onSubmit={handleLogin}>
                {error and <div style={{"color": "red", "marginBottom": "1rem"}}>{error}</div>}

                <input
                    type="text"
                    value={username}
                    onChange={lambda e: ChangeEvent { username = e.target.value; }}
                    placeholder="Username"
                    style={{"width": "100%", "padding": "0.5rem", "marginBottom": "1rem"}}
                />

                <input
                    type="password"
                    value={password}
                    onChange={lambda e: ChangeEvent { password = e.target.value; }}
                    placeholder="Password"
                    style={{"width": "100%", "padding": "0.5rem", "marginBottom": "1rem"}}
                />

                <button
                    type="submit"
                    disabled={loading}
                    style={{"width": "100%", "padding": "0.5rem"}}
                >
                    {loading and "Logging in..." or "Login"}
                </button>
            </form>
        </div>;
    }
}
