import from "@jac/runtime" { jacLogout, useNavigate, __doFuncFetch }

def:pub GreetCard() -> JsxElement {
    has greet_name: str = "";
    has greeting: str = "";
    has loading: bool = False;
    has error: str = "";

    navigate = useNavigate();

    def on_input(e: any) -> None {
        greet_name = e.target.value;
    }

    async def on_submit(e: any) -> None {
        e.preventDefault();
        loading = True;
        error = "";
        try {
            input_name = greet_name if greet_name else "World";
            result = await __doFuncFetch("greet", {"name": input_name});
            if result and result["message"] {
                greeting = str(result["message"]);
            }
        } except Exception as ex {
            msg = str(ex);
            if "UNAUTHORIZED" in msg {
                jacLogout();
                navigate("/login");
            } else {
                error = "Request failed: " + msg;
            }
        }
        loading = False;
    }

    return (
        <div className="card greet-card">
            <h2 className="greet-card-title">Try your backend</h2>
            <p className="greet-card-desc">
                Call the
                <code className="code-inline">greet</code>
                function in
                <code className="code-inline">services/appService.jac</code>
            </p>
            <form onSubmit={on_submit} className="greet-form">
                <input
                    className="input"
                    type="text"
                    value={greet_name}
                    onChange={on_input}
                    placeholder="Enter your name"
                    disabled={loading}
                />
                <button
                    className="btn btn-primary shrink-0"
                    type="submit"
                    disabled={loading}
                >
                    {("Calling..." if loading else "Greet")}
                </button>
            </form>
            {error and (
                <div className="error-box mt-3">{error}</div>
            )}
            {greeting and (
                <div className="result-box">{greeting}</div>
            )}
        </div>
    );
}
