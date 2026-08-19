def:pub layout() -> JsxElement {
    if not jacIsLoggedIn() { return <p>Redirecting...</p>; }
    return <Outlet />;
}
