def:pub layout() -> JsxElement {
    if not jacIsLoggedIn() { return <Outlet redirect="/login" />; }
    return <Outlet />;
}
