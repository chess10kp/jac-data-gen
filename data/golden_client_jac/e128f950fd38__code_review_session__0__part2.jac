cl {
    def:pub LoginForm() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";

        def handle_submit(e: FormEvent) -> None {
            e.preventDefault();
            if not username or not password {
                error = "Username and password are required";
                return;
            }
            error = "";
            print(f"Login: {username}");
        }

        return <form onSubmit={lambda e: FormEvent { handle_submit(e); }}>
            <label>Username
                <input
                    name="username"
                    autoComplete="username"
                    value={username}
                    onChange={lambda e: ChangeEvent { username = e.target.value; }}
                />
            </label>
            <label>Password
                <input
                    type="password"
                    name="password"
                    autoComplete="current-password"
                    value={password}
                    onChange={lambda e: ChangeEvent { password = e.target.value; }}
                />
            </label>
            {error and <p className="error">{error}</p>}
            <button type="submit">Login</button>
        </form>;
    }
}
