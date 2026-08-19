def:pub Header(username: str, onLogout: Callable[[], None]) -> JsxElement {
    return <div class="header"> ... <p>Welcome back, {username}!</p> ... </div>;
}
