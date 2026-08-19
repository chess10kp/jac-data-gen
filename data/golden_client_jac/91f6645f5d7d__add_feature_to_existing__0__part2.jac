"""App header with title, subtitle, greeting, and sign-out button."""

def:pub Header(username: str, onLogout: Callable[[], None]) -> JsxElement {
    return
        <div class="header">
            <div>
                <h1>AI Day Planner</h1>
                <p class="subtitle">Task management with AI-powered meal planning</p>
                {(<p class="greeting">Welcome back, {username}!</p>)
                    if username.strip()
                    else None}
            </div>
            <button class="btn-signout" onClick={onLogout}>Sign Out</button>
        </div>;
}
