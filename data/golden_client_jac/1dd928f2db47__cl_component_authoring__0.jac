import from "@jac/runtime" { Navigate, jacIsLoggedIn, useNavigate }

def:pub LoginPage() -> JsxElement {
    nav = useNavigate();                 # imperative navigation - call nav("/dashboard") from a handler

    def go_home(e: MouseEvent) {
        nav("/dashboard");
    }

    return <div className="p-4">
        <button onClick={go_home}>home</button>
    </div>;
}

def:pub DashboardPage() -> JsxElement {
    # Protected route: inline guard. Components with no `has` / no hooks can
    # put the guard at the top; components WITH hooks or `has` must put the
    # guard AFTER those (see `jac-cl-components` rules-of-hooks pitfall).
    if not jacIsLoggedIn() {
        return <Navigate to="/login" replace={True} />;
    }
    return <div className="p-4">Dashboard</div>;
}
