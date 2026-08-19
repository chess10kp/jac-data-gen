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
            <input
                value={username}
                onChange={lambda e: ChangeEvent { username = e.target.value; }}
            />
            <input
                type="password"
                value={password}
                onChange={lambda e: ChangeEvent { password = e.target.value; }}
            />
            {error and <p className="error">{error}</p>}
            <button type="submit">Login</button>
        </form>;
    }
}
