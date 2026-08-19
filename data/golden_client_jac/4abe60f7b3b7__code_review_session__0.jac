cl import from "@jac/runtime" { useNavigate }

cl {
    def:pub LoginForm() -> JsxElement {
        has email: str = "";
        has password: str = "";

        navigate = useNavigate();

        async def handle_login() -> None {
            success = await do_login(email, password);
            if success {
                navigate("/dashboard");
            }
        }

        return <form onSubmit={lambda e: FormEvent { e.preventDefault(); handle_login(); }}>
            <input
                value={email}
                onChange={lambda e: ChangeEvent { email = e.target.value; }}
            />
            <input
                type="password"
                value={password}
                onChange={lambda e: ChangeEvent { password = e.target.value; }}
            />
            <button type="submit">Login</button>
        </form>;
    }
}
