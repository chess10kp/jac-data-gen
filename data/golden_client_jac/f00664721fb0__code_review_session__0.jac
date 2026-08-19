cl import from "@jac/runtime" { useNavigate }

cl {
    def:pub LoginForm() -> JsxElement {
        has loading: bool = False;
        navigate = useNavigate();

        async def handle_login() -> None {
            if loading { return; }
            loading = True;
            success = await do_login();
            loading = False;
            if success {
                navigate("/dashboard");
            }
        }

        return <button disabled={loading} onClick={lambda -> None { handle_login(); }}>
            {loading and "Logging in..." or "Login"}
        </button>;
    }
}
