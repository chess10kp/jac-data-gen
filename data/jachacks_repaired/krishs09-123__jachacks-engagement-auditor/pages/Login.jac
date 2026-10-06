import from "@jac/runtime" {
    Link as RuntimeLink,
    jacLogin as runtimeLogin,
    useNavigate as runtimeUseNavigate,
}
import from ..components.ui.Button { Button }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Input { Input, Label }
import from ..components.ui.Alert { Alert }

def:pub LoginPage() -> JsxElement {
    has username: str = "";
    has password: str = "";
    has error: str = "";
    has loading: bool = False;
    navigate = runtimeUseNavigate();

    async def handleLogin() -> None {
        loading = True;
        error = "";
        success: bool = False;
        success = await runtimeLogin(username, password);
        if success {
            navigate("/projects");
        } else {
            error = "Invalid credentials.";
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
                <CardTitle>Growth Lab</CardTitle>
                <CardDescription>Sign in to audit retention loops with private evidence.</CardDescription>
            </CardHeader>
            <CardContent>
                {error != "" and <Alert tone="danger">{error}</Alert>}
                <div className="stack">
                    <div>
                        <Label htmlFor="login-username">Email or username</Label>
                        <Input id="login-username" value={username} autoComplete="username" onChange={handleUsernameChange} />
                    </div>
                    <div>
                        <Label htmlFor="login-password">Password</Label>
                        <Input id="login-password" type="password" value={password} autoComplete="current-password" onChange={handlePasswordChange} />
                    </div>
                    <Button onClick={handleLogin} disabled={loading}>{"Signing in..." if loading else "Sign in"}</Button>
                </div>
                <p className="auth-switch">New here? <RuntimeLink to="/signup">Create an account</RuntimeLink></p>
            </CardContent>
        </Card>
    </div>;
}
