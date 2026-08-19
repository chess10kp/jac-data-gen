cl import from "@jac/runtime" { jacLogin, useNavigate }

cl {
    def:pub LoginForm() -> JsxElement {
        has username: str = "";
        has password: str = "";
        has error: str = "";

        navigate = useNavigate();

        async def handleLogin(e: FormEvent) -> None {
            e.preventDefault();
            try {
                success = await jacLogin(username, password);
                if success {
                    navigate("/dashboard");
                } else {
                    error = "Invalid credentials";
                }
            } except Exception {
                error = "Login failed. Please try again.";
            }
        }

        return <form onSubmit={handleLogin}>...</form>;
    }
}
