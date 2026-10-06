import from "@jac/runtime" {
    Link as RuntimeLink,
    jacLogin as runtimeLogin,
    jacSignup as runtimeSignup,
    useNavigate as runtimeUseNavigate,
}
import from ..components.ui.Button { Button }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Input { Input, Label }
import from ..components.ui.Alert { Alert }

def:pub SignupPage() -> JsxElement {
    has username: str = "";
    has password: str = "";
    has error: str = "";
    has loading: bool = False;
    navigate = runtimeUseNavigate();

    async def handleSignup() -> None {
        loading = True;
        error = "";
        signup_result: dict | None = None;
        login_ok: bool = False;
        signup_result = await runtimeSignup(username, password);
        if signup_result {
            login_ok = await runtimeLogin(username, password);
        }
        if login_ok {
            navigate("/projects");
        } else {
            error = "Signup failed.";
        }
        loading = False;
    }

    def handleUsernameChange(e: ChangeEvent) -> None {
        username = e.target.value;
    }

    def handlePasswordChange(e: ChangeEvent) -> None {
        password = e.target.value;
    }

    return <div className="auth-page">
        <Card className="auth-card">
            <CardHeader>
                <CardTitle>Create account</CardTitle>
                <CardDescription>Each account gets an isolated graph root for audit data.</CardDescription>
            </CardHeader>
            <CardContent>
                {error != "" and <Alert tone="danger">{error}</Alert>}
                <div className="stack">
                    <div>
                        <Label htmlFor="signup-username">Email or username</Label>
                        <Input id="signup-username" value={username} autoComplete="username" onChange={handleUsernameChange} />
                    </div>
                    <div>
                        <Label htmlFor="signup-password">Password</Label>
                        <Input id="signup-password" type="password" value={password} autoComplete="new-password" onChange={handlePasswordChange} />
                    </div>
                    <Button onClick={handleSignup} disabled={loading}>{"Creating..." if loading else "Create account"}</Button>
                </div>
                <p className="auth-switch">Already have an account? <RuntimeLink to="/login">Sign in</RuntimeLink></p>
            </CardContent>
        </Card>
    </div>;
}
