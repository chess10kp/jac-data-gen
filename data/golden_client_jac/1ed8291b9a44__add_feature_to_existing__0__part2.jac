"""App header with title, subtitle, signed-in user, and sign-out button."""

def:pub Header(user: str, onLogout: Callable[[], None]) -> JsxElement {
    return
        <div class="header">
            <div>
                <h1>AI Day Planner</h1>
                <p class="subtitle">Task management with AI-powered meal planning</p>
            </div>
            <div class="header-actions">
                <span class="header-user">Hi, {user}</span>
                <button class="btn-signout" onClick={onLogout}>Sign Out</button>
            </div>
        </div>;
}
