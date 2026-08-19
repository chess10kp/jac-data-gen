cl import from "@jac/runtime" { AuthGuard, Outlet }

# pages/(auth)/layout.jac - Protects all routes in (auth) group
cl {
    glob LOGIN_ROUTE = "/login";

    def:pub layout() -> JsxElement {
        return <AuthGuard redirect={LOGIN_ROUTE}>
            <Outlet />
        </AuthGuard>;
    }
}
