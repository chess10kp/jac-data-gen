cl import from "@jac/runtime" { AuthGuard, Outlet, useLocation }

cl {
    def:pub layout() -> JsxElement {
        loc: any = useLocation();
        return <AuthGuard redirect={f"/login?next={loc.pathname}"}>
            <Outlet />
        </AuthGuard>;
    }
}
